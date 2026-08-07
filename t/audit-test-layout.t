# Test origin: AI
use strict;
use warnings;

use Test2::V0;
use Cwd qw/abs_path/;
use File::Path qw/make_path remove_tree/;
use File::Spec ();
use File::Temp qw/tempdir/;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Agents::Test qw/run_cmd write_file/;

my $ROOT  = abs_path(File::Spec->catdir($Bin, '..'));
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-test-layout');

sub fixture_file {
    my ($root, $path, $content) = @_;
    my @parts = File::Spec->splitdir($path);
    pop @parts;
    make_path(File::Spec->catdir($root, @parts)) if @parts;
    write_file(File::Spec->catfile($root, split(m{/}, $path)), $content);
    return;
}

sub run_audit {
    my ($root, $mode, @extra) = @_;
    return run_cmd(
        {},
        $^X,
        $AUDIT,
        '--root',
        $root,
        '--mode',
        $mode,
        '--namespace',
        'Foo::Bar',
        @extra,
    );
}

sub clean_tree {
    my $root = tempdir(CLEANUP => 1);
    fixture_file($root, 'lib/Foo/Bar.pm',                       "package Foo::Bar;\n1;\n");
    fixture_file($root, 'lib/Foo/Bar/Thing.pm',                 "package Foo::Bar::Thing;\n1;\n");
    fixture_file($root, 'lib/Foo/Bar/Manual.pm',                "package Foo::Bar::Manual;\n1;\n");
    fixture_file($root, 'lib/Foo/Bar/Manual/Workflow.pm',       "package Foo::Bar::Manual::Workflow;\n1;\n");
    fixture_file($root, 't/00-report.t',                        "# Test origin: human\n1;\n");
    fixture_file($root, 't/01-test-support.t',                  "# Test origin: AI\n1;\n");
    fixture_file($root, 't/unit/Bar.t',                         "# Test origin: human\n1;\n");
    fixture_file($root, 't/unit/Thing_behavior.t',              "# Test origin: AI\n1;\n");
    fixture_file($root, 't/unit/Thing_behavior.fixtures/x.sql', "select 1;\n");
    fixture_file($root, 't/acceptance/Manual.t',                "# Test origin: AI\n1;\n");
    fixture_file($root, 't/acceptance/Manual/Workflow.t',       "# Test origin: AI\n1;\n");
    fixture_file($root, 't/fixtures/shared/sqlite.sql',         "select 1;\n");
    return $root;
}

subtest 'clean progressive modes use configured namespace' => sub {
    my $root = clean_tree();
    for my $mode (qw/structure unit manual combined strict/) {
        my ($status, $output) = run_audit($root, $mode);
        is($status, 0, "$mode mode succeeds") or diag $output;
        like($output, qr/OK: \Q$mode\E test layout audit passed/, "$mode reports success");
    }
};

subtest 'report inventories migration debt without failing' => sub {
    my $root = tempdir(CLEANUP => 1);
    fixture_file($root, 'lib/Foo/Bar.pm', "package Foo::Bar;\n1;\n");
    fixture_file($root, 't/legacy.t',     "use Test2::V0;\n");
    fixture_file($root, 't/legacy/x.sql', "select 1;\n");

    my ($status, $output) = run_audit($root, 'report');
    is($status, 0, 'report mode succeeds despite debt');
    like($output, qr/TLY105.*outside an allowed test category/, 'location debt is reported');
    like($output, qr/TLY106.*origin header/,                    'origin debt is reported');
    like($output, qr/TLY101.*without the \.fixtures suffix/,    'fixture debt is reported');
};

subtest 'structural options remain project controlled' => sub {
    my $root = clean_tree();
    fixture_file($root, 't/unit/NoInc.t',         "# Test origin: AI\nuse Foo::Bar::Test;\n");
    fixture_file($root, 't/unit/upstream/Case.t', "# Test origin: human\n1;\n");

    my ($status, $output) = run_audit($root, 'structure', '--test-helper', 'Foo::Bar::Test');
    is($status, 1, 'configured helper import is enforced');
    like($output, qr/TLY108.*without adding t\/lib/, 'helper error is explicit');

    fixture_file(
        $root,
        't/unit/NoInc.t',
        "# Test origin: AI\nuse lib 't/lib';\nuse Foo::Bar::Test;\n",
    );
    ($status, $output) = run_audit(
        $root,
        'unit',
        '--test-helper',
        'Foo::Bar::Test',
        '--unit-special-prefix',
        't/unit/upstream/',
    );
    is($status, 0, 'configured helper and special prefix pass') or diag $output;
    unlike($output, qr/TLY003.*upstream/, 'special unit suite is not warned about');
};

subtest 'tracked mirror deferral is explicit and strict ignores it' => sub {
    my $root = clean_tree();
    remove_tree(File::Spec->catdir($root, 't', 'unit', 'Thing_behavior.fixtures'));
    unlink(File::Spec->catfile($root, 't', 'unit', 'Thing_behavior.t'))
        or die "Cannot remove unit test: $!";
    fixture_file($root, 'TEST_REORG_DEFERRALS.md', "lib/Foo/Bar/Thing.pm\n");

    my $ledger = File::Spec->catfile($root, 'TEST_REORG_DEFERRALS.md');
    my ($status, $output) = run_audit($root, 'unit', '--deferrals', $ledger);
    is($status, 0, 'tracked deferral permits an incomplete progressive gate');
    like($output, qr/^DEFERRED: \[TLY200\].*Thing\.pm/m, 'accepted deferral is displayed');

    ($status, $output) = run_audit($root, 'strict', '--deferrals', $ledger);
    is($status, 1, 'strict mode accepts no unresolved deferral');
    like($output, qr/^ERROR: \[TLY200\].*Thing\.pm/m, 'strict error names the missing mirror');
};

subtest 'mixed markers and TODO dispositions are checked' => sub {
    my $root = clean_tree();
    fixture_file($root, 't/integration/Mixed.t', "# Test origin: mixed\n1;\n");
    fixture_file(
        $root,
        't/unit/Thing_behavior.t',
        "# Test origin: AI\nuse Test2::V0;\nmy \$reason = 'known';\ntodo \$reason => sub { fail('known') };\ndone_testing;\n",
    );

    my ($status, $output) = run_audit($root, 'strict');
    is($status, 1, 'missing markers fail strict mode');
    like($output, qr/TLY107.*mixed but has no AI section marker/, 'mixed marker is checked');
    like($output, qr/TLY400.*without enough dated/,               'TODO disposition is checked');
};

subtest 'invalid or missing namespace is rejected' => sub {
    my $root = clean_tree();
    my ($status, $output) = run_cmd({}, $^X, $AUDIT, '--root', $root, '--mode', 'structure');
    isnt($status, 0, 'namespace is required');
    like($output, qr/--namespace Package::Name is required/, 'requirement is explained');

    ($status, $output) = run_audit($root, 'structure', '--manual-namespace', 'Other::Manual');
    isnt($status, 0, 'manual namespace must be under primary namespace');
    like($output, qr/must be below --namespace/, 'namespace relationship is explained');
};

done_testing;
