# Test origin: AI
use strict;
use warnings;

use Test2::V0;
use Cwd qw/abs_path/;
use File::Spec ();
use File::Temp qw/tempdir/;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Agents::Test qw/run_cmd write_file/;

my $ROOT  = abs_path(File::Spec->catdir($Bin, '..'));
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-project-wiring');

subtest 'unadopted project' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 1, 'missing optional wiring is reported when this audit is requested');
    like($output, qr/\[warning WIR002\]/, 'finding has a stable code');
};

subtest 'adopted project' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for my $file (qw/Changes AGENTS_OVERRIDE.md .perltidyrc AI_AND_LLM_POLICY.txt TEMPLATE.pod/) {
        write_file(File::Spec->catfile($dir, $file), "fixture\n");
    }
    write_file(File::Spec->catfile($dir, 'AGENTS.md'), "Read ~/projects/Agents/AGENTS.md first.\n");
    write_file(File::Spec->catfile($dir, 'CODEX.md'),  "Read AGENTS.md first.\n");

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'complete optional wiring passes');
    like($output, qr/^OK:/, 'clean result is reported');
};

done_testing;
