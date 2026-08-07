package Agents::Test;

use strict;
use warnings;

use Exporter qw/import/;
use File::Spec ();

our @EXPORT_OK = qw/run_cmd write_file/;

sub run_cmd {
    my ($options, @cmd) = @_;
    $options = {} unless ref($options) eq 'HASH';

    pipe(my $reader, my $writer) or die "pipe failed: $!";
    my $pid = fork // die "fork failed: $!";

    unless ($pid) {
        close($reader);
        chdir($options->{cwd}) or die "chdir '$options->{cwd}': $!"
            if defined $options->{cwd};
        if ($options->{env}) {
            $ENV{$_} = $options->{env}{$_} for keys %{$options->{env}};
        }
        open(STDOUT, '>&', $writer) or die "redirect stdout: $!";
        open(STDERR, '>&', $writer) or die "redirect stderr: $!";
        exec {$cmd[0]} @cmd;
        die "exec '$cmd[0]' failed: $!";
    }

    close($writer);
    local $/;
    my $output = <$reader> // '';
    close($reader);
    waitpid($pid, 0);

    return ($? >> 8, $output);
}

sub write_file {
    my ($path, $content) = @_;
    open(my $fh, '>', $path) or die "open '$path': $!";
    print {$fh} $content;
    close($fh) or die "close '$path': $!";
    return;
}

1;
