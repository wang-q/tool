#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use YAML qw(Dump Load DumpFile LoadFile);

use LWP::Simple;
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

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'    => \$help,
    'man'       => \$man,
    'i|input=s' => \$file_yaml,
    'r|regex=s' => \$path_regex,
    '6|ipv6'    => \$ipv6,
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

    my $rc = mirror( $url, $path );
    printf "* RC: %s\n\n", $rc;
};

my $run = AlignDB::Run->new(
    parallel => $parallel,
    jobs     => \@jobs,
    code     => $worker,
);
$run->run;

__END__

perl download.pl -i _goldenPath_sacCer3_multiz7way_.yml -r gz

perl download.pl -i _goldenPath_sacCer3_multiz7way_.ipv6.yml -r gz -6
