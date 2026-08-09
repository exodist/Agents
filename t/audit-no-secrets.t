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
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-no-secrets');

subtest 'project-relative path' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'notes.txt');
    write_file($file, "Test2-Harness2/agent_scripts/find-large-modules:18\n");    # not-a-secret

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $file);
    is($exit, 0, 'relative path is not treated as a secret');
    like($output, qr/^OK:/, 'clean result is reported');
};

subtest 'high-entropy value' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'token.txt');
    write_file($file, "AbCdEfGhIjKlMnOpQrStUvWxYz123456\n");                      # not-a-secret

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $file);
    is($exit, 1, 'token-shaped value still fails');
    like($output, qr/high-entropy blob/, 'finding identifies the heuristic');
    unlike($output, qr/\.md\b/, 'diagnostic is self-contained');
};

done_testing;
