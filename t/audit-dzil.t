# Test origin: AI
use strict;
use warnings;

use Test2::V0;
use Cwd qw/abs_path/;
use File::Path qw/make_path/;
use File::Spec ();
use File::Temp qw/tempdir/;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Agents::Test qw/run_cmd write_file/;

my $ROOT     = abs_path(File::Spec->catdir($Bin, '..'));
my $AUDIT    = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-dzil');
my $TEMPLATE = File::Spec->catfile($ROOT, 'templates',     'dist.ini');

sub template_text {
    open(my $fh, '<', $TEMPLATE) or die "open '$TEMPLATE': $!";
    local $/;
    return <$fh>;
}

sub project_with_ini {
    my ($content) = @_;
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'dist.ini'), $content);
    return $dir;
}

subtest 'canonical packaging template' => sub {
    my $dir = project_with_ini(template_text());
    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'template passes without Agents project files');
    like($output, qr/^OK:/, 'clean result is reported');
};

subtest 'repository-wide Git gather' => sub {
    my $ini = template_text();
    $ini =~ s/^\[GatherDir\]/[Git::GatherDir \/ Root]/m;
    my $dir = project_with_ini($ini);
    my ($exit) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'repository-wide Git::GatherDir can replace GatherDir');
};

subtest 'plugin ordering and MakeMaker presence' => sub {
    my $ini = template_text();
    $ini =~ s/\[RewriteVersion\](.*?)\n\[License\]/[License]$1\n[RewriteVersion]/s;
    $ini =~ s/^\[MakeMaker\]\n//m;
    my $dir = project_with_ini($ini);
    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'invalid plugin structure fails');
    like($output, qr/\[warning DZI101\]/, 'out-of-order plugin has a stable code');
    like($output, qr/\[warning DZI402\]/, 'missing MakeMaker has a stable code');
};

subtest 'dynamic old trees and XS prereqs' => sub {
    my $ini = template_text();
    $ini =~ s/^exclude_match\s+= \^old.*\n//m;
    my $dir = project_with_ini($ini);
    make_path(File::Spec->catdir($dir, 'old17'));
    write_file(File::Spec->catfile($dir, 'Example.xs'), "/* fixture */\n");
    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'packaging gaps fail');
    like($output, qr/DZI200.*old17/,    'arbitrary old-number tree is checked');
    like($output, qr/DZI503.*XSLoader/, 'XSLoader is required for XS sources');
};

subtest 'dependency policy remains project-local' => sub {
    my $ini = template_text();
    $ini =~ s/^\[Prereqs\]$/[Prereqs]\nDateTime::Format::SQLite = 0/m;
    my $dir = project_with_ini($ini);
    my ($exit) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'individual dependency classification is not enforced');
};

subtest 'Markdown exclusion diagnostic is self-contained' => sub {
    my $ini = template_text();
    $ini =~ s/^exclude_match\s+= \\.md\$.*\n//m;
    my $dir = project_with_ini($ini);
    write_file(File::Spec->catfile($dir, 'INTERNAL.md'), "fixture\n");

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'missing Markdown exclusion fails');
    like($output, qr/DZI201/, 'finding has a stable code');
    unlike($output, qr/\.md\b/, 'diagnostic does not refer users to a Markdown filename');
};

done_testing;
