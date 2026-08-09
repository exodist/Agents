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

my $ROOT  = abs_path(File::Spec->catdir($Bin, '..'));
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-project-wiring');

sub valid_override {
    return <<'EOT';
# AGENTS_OVERRIDE.md
## Declarations
### Minimum Perl version
> **Minimum: 5.012000**
### Subroutine signatures
> **Policy: disabled**
> **Enabling pragma: not applicable**
### POD placement
> **Layout: All at bottom**
### Test layout and provenance
> **Scheme: Categories plus origin headers**
> **Layout audit: perl agent_scripts/audit-test-layout --mode strict --namespace Example**
### perltidy
> **Config: Shared**
## Overrides
None.
EOT
}

sub adopted_project {
    my $dir = tempdir(CLEANUP => 1);
    for my $file (qw/Changes .perltidyrc AI_AND_LLM_POLICY.txt TEMPLATE.pod/) {
        write_file(File::Spec->catfile($dir, $file), "fixture\n");
    }
    write_file(File::Spec->catfile($dir, 'AGENTS_OVERRIDE.md'), valid_override());
    write_file(File::Spec->catfile($dir, 'AGENTS.md'),          "Read ~/projects/Agents/AGENTS.md first.\n");
    write_file(File::Spec->catfile($dir, 'CODEX.md'),           "Read AGENTS.md first.\n");
    return $dir;
}

subtest 'unadopted project' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'missing optional wiring is reported when this audit is requested');
    like($output, qr/\[warning WIR002\]/, 'finding has a stable code');
    unlike($output, qr/\.md\b/, 'diagnostics do not refer users to Markdown files');
};

subtest 'adopted project' => sub {
    my $dir = adopted_project();

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'complete optional wiring passes');
    like($output, qr/^OK:/, 'clean result is reported');
};

subtest 'declaration placeholders and signature pragma' => sub {
    my $dir      = adopted_project();
    my $override = valid_override();
    $override =~ s/\*\*Policy: disabled\*\*/**Policy: required where expressible**/;
    $override =~ s/\*\*Enabling pragma: not applicable\*\*/**Enabling pragma: _____**/;
    $override =~ s/\*\*Config: Shared\*\*/**Config: _____**/;
    write_file(File::Spec->catfile($dir, 'AGENTS_OVERRIDE.md'), $override);

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'unanswered declarations fail');
    like($output, qr/WIR103.*perltidy/,        'ordinary placeholder is reported');
    like($output, qr/WIR104.*enabling pragma/, 'required signature pragma is reported separately');
};

subtest 'Perl floor matches packaging and module pragmas' => sub {
    my $dir = adopted_project();
    make_path(File::Spec->catdir($dir, 'lib'));
    write_file(File::Spec->catfile($dir, 'dist.ini'), "[Prereqs]\nperl = 5.010000\n");
    write_file(File::Spec->catfile($dir, 'lib', 'Example.pm'), "package Example;\nuse v5.38;\n1;\n");

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'inconsistent Perl floors fail');
    like($output, qr/WIR106.*does not match/,          'dist.ini mismatch is reported');
    like($output, qr/WIR107.*Example\.pm uses v5\.38/, 'higher shipped pragma is reported');

    write_file(File::Spec->catfile($dir, 'dist.ini'), "[Prereqs]\nperl = _____\n");
    ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'unfilled dist.ini minimum fails');
    like($output, qr/WIR106.*no parsable perl prerequisite/, 'dist.ini placeholder is reported');

    write_file(File::Spec->catfile($dir, 'dist.ini'), "[Prereqs]\nperl = 5.012000\n");
    write_file(File::Spec->catfile($dir, 'lib', 'Example.pm'), "package Example;\nuse 5.012;\n1;\n");
    ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'equivalent version spellings pass') or diag $output;
};

done_testing;
