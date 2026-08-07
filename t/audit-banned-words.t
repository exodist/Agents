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
my $AUDIT = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-banned-words');

subtest 'default scope' => sub {
    my $dir = tempdir(CLEANUP => 1);
    make_path(File::Spec->catdir($dir, 'lib'));
    write_file(File::Spec->catfile($dir, 'NOTES.md'), "An iff discussion is allowed here.\n");    # banned-words-ok
    write_file(File::Spec->catfile($dir, 'lib', 'Clean.pm'), "package Clean;\n1;\n");

    my ($exit, $output) = run_cmd({cwd => $dir}, $^X, $AUDIT);
    is($exit, 0, 'internal root Markdown is not scanned');
    like($output, qr/^OK:/, 'clean result is reported');

    write_file(File::Spec->catfile($dir, 'lib', 'Bad.pm'), "package Bad;\n# iff this runs\n1;\n");    # banned-words-ok
    ($exit, $output) = run_cmd({cwd => $dir}, $^X, $AUDIT);
    is($exit, 1, 'maintained code is scanned');
    like($output, qr{lib/Bad\.pm:2:}, 'code hit names its source line');
};

subtest 'explicit user documentation' => sub {
    my $dir    = tempdir(CLEANUP => 1);
    my $readme = File::Spec->catfile($dir, 'USER_GUIDE.md');
    write_file($readme, "Pass kwargs to the constructor.\n");                                         # banned-words-ok

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $readme);
    is($exit, 1, 'an explicitly identified user document is scanned');
    like($output, qr/USER_GUIDE\.md:1:/, 'user-document hit is reported');
};

subtest 'immutable trees' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for my $name (qw/reference old2 worktrees/) {
        my $tree = File::Spec->catdir($dir, $name);
        make_path($tree);
        write_file(File::Spec->catfile($tree, 'Bad.pm'), "package Bad;\n# iff this runs\n1;\n");    # banned-words-ok
    }

    my ($exit, $output) = run_cmd({}, $^X, $AUDIT, $dir);
    is($exit, 0, 'immutable and worktree paths are excluded');
    like($output, qr/^OK:/, 'excluded content produces no hits');
};

done_testing;
