# Test origin: AI
use strict;
use warnings;

use Test2::V0;
use Cwd qw/abs_path/;
use File::Path qw/make_path/;
use File::Spec ();
use File::Temp qw/tempdir/;
use FindBin qw/$Bin/;

my $ROOT = abs_path(File::Spec->catdir($Bin, '..'));

sub run_install {
    my ($fake_home, @args) = @_;

    my $stdout = File::Spec->catfile($fake_home, 'install.stdout');
    my $stderr = File::Spec->catfile($fake_home, 'install.stderr');
    my $pid    = fork // die "fork failed: $!";

    unless ($pid) {
        $ENV{HOME} = $fake_home;
        open(STDOUT, '>', $stdout) or die "open '$stdout': $!";
        open(STDERR, '>', $stderr) or die "open '$stderr': $!";
        exec {$ROOT . '/install'} $ROOT . '/install', @args;
        die "exec install failed: $!";
    }

    waitpid($pid, 0);
    return $? >> 8;
}

subtest 'fresh home' => sub {
    my $fake_home = tempdir(CLEANUP => 1);

    is(run_install($fake_home), 0, 'install succeeds');

    my $claude = File::Spec->catfile($fake_home, '.claude', 'skills');
    ok(-l $claude, 'whole Claude skill directory is linked');
    is(readlink($claude), "$ROOT/skills", 'Claude link points at this checkout');

    my $codex = File::Spec->catfile($fake_home, '.agents', 'skills');
    ok(-l $codex, 'whole Codex skill directory is linked');
    is(readlink($codex), "$ROOT/skills", 'Codex link points at this checkout');

    my $tool = File::Spec->catfile($fake_home, '.local', 'bin', 'agent-test-lock');
    ok(-l $tool, 'bin tool is linked');
};

subtest 'user-owned Claude symlink' => sub {
    my $fake_home   = tempdir(CLEANUP => 1);
    my $user_skills = File::Spec->catdir($fake_home, 'user-skills');
    my $claude_root = File::Spec->catdir($fake_home, '.claude');
    make_path($user_skills, $claude_root);

    my $claude = File::Spec->catfile($claude_root, 'skills');
    symlink($user_skills, $claude) or die "symlink '$claude': $!";

    is(run_install($fake_home), 0,            'install succeeds');
    is(readlink($claude),       $user_skills, 'user symlink is preserved');
    ok(
        -l File::Spec->catfile($user_skills, 'perl-test-run'),
        'Agents skills are linked individually through the user directory',
    );
};

subtest 'user-owned individual skill symlink' => sub {
    my $fake_home = tempdir(CLEANUP => 1);
    my $codex     = File::Spec->catdir($fake_home, '.agents', 'skills');
    my $foreign   = File::Spec->catdir($fake_home, 'foreign-skill');
    make_path($codex, $foreign);

    my $skill = File::Spec->catfile($codex, 'perl-test-run');
    symlink($foreign, $skill) or die "symlink '$skill': $!";

    is(run_install($fake_home), 0,        'install succeeds');
    is(readlink($skill),        $foreign, 'individual user symlink is preserved');
};

done_testing;
