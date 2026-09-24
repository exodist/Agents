# Test origin: AI
use strict;
use warnings;

use Test2::V0;
use Cwd qw/abs_path/;
use File::Spec ();
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Agents::Test qw/run_cmd/;

my $ROOT = abs_path(File::Spec->catdir($Bin, '..'));
my $LOCK = File::Spec->catfile($ROOT, 'bin', 'agent-test-lock');

sub author_value {
    my ($inherited, @options) = @_;
    return run_cmd(
        {env => {AUTHOR_TESTING => $inherited}},
        $^X,
        $LOCK,
        '--jobs',
        1,
        @options,
        '--',
        $^X,
        '-e',
        'print $ENV{AUTHOR_TESTING}',
    );
}

my ($exit, $output) = author_value(0);
is($exit, 0, 'ordinary command succeeds');
like($output, qr/1\z/, 'ordinary invocation forces author tests on');

($exit, $output) = author_value(1, '--no-author');
is($exit, 0, 'no-author command succeeds');
like($output, qr/0\z/, 'no-author forces author tests off');

($exit, $output) = run_cmd({}, $^X, $LOCK, '--help');
is($exit, 0, 'help succeeds');
like($output, qr/default 900 for serial,\s+300 for concurrent/, 'help documents derived defaults');
like($output, qr/1M \(default 75%/,                             'help documents the memory cap default');

for my $size (qw/lots 64m 150% 0 0% 0.5% 12.345% 300K/) {
    ($exit, $output) = run_cmd({}, $^X, $LOCK, '--jobs', 1, '--memory-max', $size, '--', $^X, '-e', '1');
    isnt($exit, 0, "memory cap '$size' is rejected");
    like($output, qr/--memory-max takes 1-100% or a size of at least 1M/, "rejection of '$size' names the expected format");
}

($exit, $output) = run_cmd({}, $^X, $LOCK, '--jobs', 1, '--no-memory-cap', '--', $^X, '-e', 'exit 3');
is($exit, 3, 'uncapped run returns the command exit status');
unlike($output, qr/memory capped/, 'no-memory-cap skips the scope');

subtest 'memory cap under user systemd' => sub {
    skip_all 'no user systemd scope available'
        unless system('systemd-run --user --scope --quiet -- true >/dev/null 2>&1') == 0;

    # Start each run from a fresh scope so an enclosing agent-test-lock run
    # does not turn these into nested runs.
    my @fresh = qw/systemd-run --user --scope --quiet --/;

    my ($exit, $output) = run_cmd({}, @fresh, $^X, $LOCK, '--jobs', 1, '--', 'cat', '/proc/self/cgroup');
    is($exit, 0, 'capped run succeeds');
    like($output, qr/memory capped at 75%/,           'cap is announced');
    like($output, qr/agent-test-lock-\d+-\d+\.scope/, 'command runs inside the transient scope');

    ($exit, $output) = run_cmd({}, @fresh, $^X, $LOCK, '--jobs', 1, '--', $^X, '-MTime::HiRes=sleep', '-e', 'sleep 0.6');
    like($output, qr/memory peak \S+ \(cap 75%\)/, 'the run reports its memory peak');

    ($exit, $output) = run_cmd(
        {},  @fresh, $^X, $LOCK, '--jobs', 1, '--memory-max', '64M', '--',
        $^X, '-e',   'use Time::HiRes qw/sleep/; my @hog; for (1 .. 512) { push @hog => ("x" x (1 << 20)) . $_; sleep 0.005 }',
    );
    isnt($exit, 0, 'a run over the cap is killed');
    like($output, qr/hit the memory cap \(64M\)/, 'the kill is reported as a memory cap kill');
    unlike($output, qr/memory peak/, 'a killed run prints no peak');

    ($exit, $output) = run_cmd(
        {}, @fresh, $^X, $LOCK, '--jobs', 1, '--', $^X, $LOCK, '--jobs', 1, '--', 'cat', '/proc/self/cgroup',
    );
    is($exit, 0, 'nested run succeeds');
    like($output, qr/already inside agent-test-lock-\d+-\d+\.scope/, 'a nested run keeps the enclosing cap');
};

done_testing;
