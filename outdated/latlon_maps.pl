#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use Geo::GoogleEarth::Document;
use Text::CSV_XS;
use File::Basename;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $csv_file;
my $kml_file;
my $title;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'       => \$help,
    'man'          => \$man,
    'c|csv_file=s' => \$csv_file,
    'k|kml_file=s' => \$kml_file,
    't|title=s'    => \$title,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

pod2usage( -exitstatus => 0, -verbose => 2 ) unless $csv_file;
$kml_file = "$csv_file.kml"     unless $kml_file;
$title    = basename($csv_file) unless $title;

#----------------------------------------------------------#
# init
#----------------------------------------------------------#
my $document = Geo::GoogleEarth::Document->new( name => $title );

my $csv = Text::CSV_XS->new( { binary => 1, eol => "\n" } );
open my $csv_fh, "<", $csv_file or die "$csv_file: $!";

$csv->getline($csv_fh);    # head line
while ( my $row = $csv->getline($csv_fh) ) {
    my ( $name, $lat, $lon, $description ) = @$row;

    $lat = decimal_degrees($lat);
    $lon = decimal_degrees($lon);

    $description =~ s/\n/\<br\>/g;

    my $point = $document->Placemark(
        name        => $name,
        lat         => $lat,
        lon         => $lon,
        description => "latitude $lat<br>"
            . "longtitude $lon<br>"
            . $description,
    );
}

close $csv_fh;

open my $kml_fh, ">", $kml_file or die "$kml_file: $!";
print {$kml_fh} $document->render;
close $kml_fh;

exit;

sub decimal_degrees {
    my $str = shift;

    my ( $d, $m, $s ) = grep {/\d/} split /[^\d.]+/, $str;
    warn "latitude wrong\n" unless defined $d;
    $m = $m || 0;
    $s = $s || 0;
    my $dd = $d + $m / 60 + $s / 3600;
    $str =~ /^\s*[-]/;
    $dd = -$dd if $1;

    #print Dump {
    #    dd  => $dd,
    #    d   => $d,
    #    m   => $m,
    #    s   => $s,
    #    str => $str,
    #};

    return $dd;
}

__END__

=head1 NAME

    latlon_maps.pl - Generate Google Earth KML files

=head1 SYNOPSIS

    latlon_maps.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        -c, --csv_file      REQUIRED. input csv filename
                            dms form 12бу33'34.6"
                            dd form 12.345678
        -k, --kml_file      output KML filename
        -t, --title         title of KML

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do someting
useful with the contents thereof.

=cut
