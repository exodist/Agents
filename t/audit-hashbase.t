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

my $ROOT    = abs_path(File::Spec->catdir($Bin, '..'));
my $METHODS = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-methods-not-functions');
my $ATTRS   = File::Spec->catfile($ROOT, 'agent_scripts', 'audit-readonly-attrs');

subtest 'private HashBase identifies an object module' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'Inline.pm');
    write_file(
        $file,
        <<'PERL',
package Inline;
use Local::Util::HashBase qw{<name};
sub helper { 1 }
sub call_helper { helper() }
1;
PERL
    );

    my ($exit, $output) = run_cmd({}, $^X, $METHODS, $file);
    is($exit, 1, 'bare call in an inlined HashBase class fails');
    like($output, qr/Inline\.pm:4: helper/, 'bare call is identified');
};

subtest 'Object::HashBase without attributes still identifies a class' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'Empty.pm');
    write_file(
        $file,
        <<'PERL',
package Empty;
use Object::HashBase;
sub helper { 1 }
sub call_helper { helper() }
1;
PERL
    );

    my ($exit) = run_cmd({}, $^X, $METHODS, $file);
    is($exit, 1, 'an attribute-free HashBase class is audited');
};

subtest 'read-only attribute positions' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'Attrs.pm');
    write_file(
        $file,
        <<'PERL',
package Attrs;
use Local::HashBase qw{ -single <ok };
use Local::HashBase qw{
    <other
    -closing};
1;
PERL
    );

    my ($exit, $output) = run_cmd({}, $^X, $ATTRS, $file);
    is($exit, 1, 'single-line and closing-line attributes fail');
    like($output, qr/Attrs\.pm:2:.*-single/,  'single-line attribute is reported');
    like($output, qr/Attrs\.pm:5:.*-closing/, 'closing-line attribute is reported');
};

subtest 'explicit throwing-setter marker' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'Allowed.pm');
    write_file(
        $file,
        <<'PERL',
package Allowed;
use Local::HashBase qw{
    -throwing # -attr-ok clearer compatibility error
};
1;
__END__
=head1 EXAMPLE

use Local::HashBase qw{-example};
PERL
    );

    my ($exit, $output) = run_cmd({}, $^X, $ATTRS, $file);
    is($exit, 0, 'marked attribute is allowed');
    like($output, qr/^OK:/, 'clean result is reported');
};

done_testing;
