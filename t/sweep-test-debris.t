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
my $SWEEP = File::Spec->catfile($ROOT, 'bin', 'sweep-test-debris');

sub debris_dir {
    my ($root, $name) = @_;
    my $dir = File::Spec->catdir($root, $name);
    make_path($dir);
    write_file(File::Spec->catfile($dir, 'my.cfg'), "test fixture\n");
    return $dir;
}

subtest 'default safety age' => sub {
    my $tmp    = tempdir(CLEANUP => 1);
    my $debris = debris_dir($tmp, 'fresh');

    my ($exit, $output) = run_cmd({}, $^X, $SWEEP, '--tmpdir', $tmp);
    is($exit, 0, 'report succeeds');
    like($output, qr/^No database test debris/, 'fresh marker is ignored by default');
    ok(-d $debris, 'fresh directory remains');

    ($exit, $output) = run_cmd({}, $^X, $SWEEP, '--tmpdir', $tmp, '--min-age', 0);
    is($exit, 0, 'explicit all-age report succeeds');
    like($output, qr/1 abandoned dir/, 'all-age report finds the fixture');
};

subtest 'delete mode' => sub {
    my $tmp    = tempdir(CLEANUP => 1);
    my $debris = debris_dir($tmp, 'old');
    my $old    = time - 7200;
    utime($old, $old, $debris) or die "utime '$debris': $!";

    my ($exit, $output) = run_cmd({}, $^X, $SWEEP, '--delete', '--tmpdir', $tmp);
    is($exit, 0, 'old debris is removed');
    like($output, qr/Removed 1 of 1 dir/, 'removal is reported');
    ok(!-e $debris, 'directory was deleted');
};

subtest 'watcher enumeration failure' => sub {
    my $tmp      = tempdir(CLEANUP => 1);
    my $debris   = debris_dir($tmp, 'candidate');
    my $fake_bin = File::Spec->catdir($tmp, 'bin');
    make_path($fake_bin);
    my $ps = File::Spec->catfile($fake_bin, 'ps');
    write_file($ps, "#!/bin/sh\nexit 1\n");
    chmod(0755, $ps) or die "chmod '$ps': $!";

    my ($exit, $output) = run_cmd(
        {env => {PATH => $fake_bin}},
        $^X,
        $SWEEP,
        '--delete',
        '--tmpdir',
        $tmp,
        '--min-age',
        0,
    );
    isnt($exit, 0, 'enumeration failure refuses the operation');
    like($output, qr/could not enumerate QuickDB watchers/, 'failure is explicit');
    ok(-d $debris, 'candidate directory remains');
};

done_testing;
