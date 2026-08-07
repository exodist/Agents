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

done_testing;
