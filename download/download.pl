#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use Pod::Usage;
use YAML qw(Dump Load DumpFile LoadFile);

use LWP::Simple;
use LWP::UserAgent;
use Path::Class;
use File::Path qw(make_path);
use LockFile::Simple qw(lock trylock unlock);

use AlignDB::Run;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
# running options
my $file_yaml;
my $path_regex = '.';
my $ipv6;
my $aria2;    # generate a aria2 input file

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'    => \$help,
    'man'       => \$man,
    'i|input=s' => \$file_yaml,
    'r|regex=s' => \$path_regex,
    '6|ipv6'    => \$ipv6,
    'a|aria2'   => \$aria2,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# init
#----------------------------------------------------------#
# When downloading from an IPV6 site, we require this package
# It's not compatible with IPV4 sites
if ($ipv6) {
    require Net::INET6Glue::INET_is_INET6;
}

my $parallel = 4;

my $dispatch  = LoadFile($file_yaml);
my $dir_to_mk = $dispatch->{dir_to_mk};
my $url_path  = $dispatch->{url_path};

#----------------------------#
# create dirs
#----------------------------#
# Files will locate in the same dir as the yaml file.
$file_yaml = file($file_yaml)->absolute;
my $base_dir = $file_yaml->dir->stringify;
for my $dir ( sort keys %{$dir_to_mk} ) {
    $dir = dir( $base_dir, $dir )->stringify;
    make_path($dir) unless -e $dir;
}

my $aria2_file;
if ($aria2) {
    $aria2_file = $file_yaml . ".txt";
    unlink $aria2_file if -e $aria2_file;
}

#----------------------------#
# parallel download
#----------------------------#
my @jobs;
for my $url ( sort keys %{$url_path} ) {
    my $path = $url_path->{$url};
    next unless $path =~ /$path_regex/;

    $path = file( $base_dir, $url_path->{$url} )->stringify;
    push @jobs, [ $url, $path ];
}

if ($aria2) {    # aria2
    for my $job (@jobs) {
        my ( $url, $path ) = @{$job};
        printf "* URL: %s\n" . "* LOCAL: %s\n", $url, $path;

        my $str;
        $str .= "$url\n";

        my $file = file($path);
        $str .= "  dir=" . $file->dir->stringify . "\n";
        $str .= "  out=" . $file->basename . "\n";

        open my $fh, '>>', $aria2_file;
        print {$fh} $str;
        close $fh;
    }

    print "\nRun something like the following command to start downloading.\n";
    print "aria2c -x 12 -s 4 -i $aria2_file\n";
}
else {    # LWP
    my $worker = sub {
        my $job = shift;
        my $opt = shift;

        my ( $url, $path ) = @{$job};
        printf "* URL: %s\n" . "* LOCAL: %s\n", $url, $path;

        my $rc = get_file( $url, $path );
        printf "* RC: %s\n\n", $rc;

        return;
    };

    my $run = AlignDB::Run->new(
        parallel => $parallel,
        jobs     => \@jobs,
        code     => $worker,
    );
    $run->run;
}

#----------------------------#
# subs
#----------------------------#
sub get_file {
    my $url      = shift;
    my $filename = shift;

    my $rc = mirror( $url, $filename );
    return $rc;
}

__END__

=head1 SYNOPSIS

perl download.pl -i _goldenPath_sacCer3_multiz7way_.yml -r gz

perl download.pl -i _goldenPath_sacCer3_multiz7way_.ipv6.yml -r gz -6

>perl download.pl -i 19genomes_fasta.yml -a
>c:\tools\aria2\aria2c -x 12 -s 4 -i D:\wq\Scripts\tool\download\19genomes_fasta.yml.txt
