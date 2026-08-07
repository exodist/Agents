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
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'find-large-modules');

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'Size.pm');
write_file(
    $file,
    <<'PERL',
package Size;
my $one = 1;
=pod
POD does not count.
=cut
my $two = 2;
__DATA__
Data does not count.
PERL
);

my ($exit, $output) = run_cmd({}, $^X, $AUDIT, '--threshold', 3, $file);
is($exit,   0,  'POD and data trailer are excluded');
is($output, '', 'clean scan is quiet');

($exit, $output) = run_cmd({}, $^X, $AUDIT, '--threshold', 2, $file);
is($exit, 1, 'code lines enforce the configured threshold');
like($output, qr/3 lines of code/, 'reported count excludes non-code regions');

done_testing;
