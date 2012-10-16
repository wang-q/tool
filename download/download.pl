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

use AlignDB::Run;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
# running options
my $file_yaml;
my $path_regex = '.';
my $ipv6;
my $wget;     # use wget instead of LWP
my $aria2;    # generate a aria2 input file

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'    => \$help,
    'man'       => \$man,
    'i|input=s' => \$file_yaml,
    'r|regex=s' => \$path_regex,
    '6|ipv6'    => \$ipv6,
    'w|wget'    => \$wget,
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

my ( $aria_file, $aria_fh );
if ($aria2) {
    $aria_file = $file_yaml . ".txt";
    open $aria_fh, ">>", $aria_file;
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

my $worker = sub {
    my $job = shift;

    my ( $url, $path ) = @{$job};
    printf "* URL: %s\n" . "* LOCAL: %s\n", $url, $path;

    if ( $wget or $aria2 ) {
        my ( $is_success, $rsize, $rmtime ) = get_headers($url);
        if ($is_success) {
            if ( -e $path and $rsize and $rmtime ) {
                my ( $lsize, $lmtime ) = ( stat($path) )[ 7, 9 ];
                if ( $rsize == $lsize or $rmtime <= $lmtime ) {
                    printf "* SKIP: %s\n\n", "Already download successly";
                    return;
                }
            }
        }
        else {
            printf "* WARN: %s\n\n", "Can't get headers from URL";
            return;
        }

        unlink $path if -e $path;

        if ($wget) {

            # wget exit status
            my $error_of = {
                0 => "No problems occurred",
                1 => "Generic error code",
                2 => "Parse error¡ªfor instance",
                3 => "File I/O error",
                4 => "Network failure",
                5 => "SSL verification failure",
                6 => "Username/password authentication failure",
                7 => "Protocol errors",
                8 => "Server issued an error response",
            };

            my $rc = wget_file( $url, $path );
            if ( defined $rc ) {
                if ( $rc == 0 ) {
                    utime $rmtime, $rmtime, $path if $rmtime;
                }
                printf "* WGET: %s\n\n",
                    $error_of->{$rc} ? $error_of->{$rc} : $rc;
            }
            printf "* WGET: %s\n\n", "Something goes wrong";
        }
        elsif ($aria2) {
            my $str;
            $str .= "$url\n";

            my $file = file($path);
            $str .= "  dir=" . $file->dir->stringify . "\n";
            $str .= "  out=" . $file->basename . "\n";

            print {$aria_fh} $str;
        }
    }
    else {
        my $rc = get_file( $url, $path );
        printf "* RC: %s\n\n", $rc;
    }

    return;
};

my $run = AlignDB::Run->new(
    parallel => $parallel,
    jobs     => \@jobs,
    code     => $worker,
);
$run->run;

if ($aria2) {
    close $aria_fh;
    print "Run something like the following command to start downloading.\n";
    print "aria2c -x 12 -s 4 -i $aria_file\n";
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

sub get_headers {
    my $url = shift;

    my $ua = LWP::UserAgent->new( timeout => 10 );

    my $res = $ua->head($url);
    if ( $res->is_success ) {
        my $h = $res->headers;
        return ( 1, $h->content_length, $h->last_modified );
    }

    return ( 0, undef, undef );
}

# self compiled wget, with ipv6 supported
sub wget_file {
    my $url      = shift;
    my $filename = shift;

    my $cmd = "wget $url -O \"$filename\" -q";
    my $rc  = system($cmd );

    return $rc;
}

__END__

perl download.pl -i _goldenPath_sacCer3_multiz7way_.yml -r gz

perl download.pl -i _goldenPath_sacCer3_multiz7way_.ipv6.yml -r gz -6

>perl download.pl -i 19genomes_fasta.yml -a
>c:\tools\aria2\aria2c -x 12 -s 4 -i D:\wq\Scripts\tool\download\19genomes_fasta.yml.txt