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
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'find-long-subs');

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'Comments.pm');
my $body = join('', ("    my \$value;\n" x 43), ("    # comment with { braces }\n" x 40), ("\n" x 10));
write_file($file, "package Comments;\nsub example {\n${body}}\n1;\n");

my ($exit, $output) = run_cmd({}, $^X, $AUDIT, '--threshold', 50, $file);
is($exit,   0,  'comments and blank lines do not push the sub over the limit');
is($output, '', 'clean scan is quiet');

($exit, $output) = run_cmd({}, $^X, $AUDIT, '--threshold', 44, $file);
is($exit, 1, 'executable lines still enforce the limit');
like($output, qr/example\s+\(45 lines\)/, 'reported length counts signature, code, and closing brace');

done_testing;
