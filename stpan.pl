#!/usr/bin/env perl
use strict;
use warnings;
use autodie;

use File::Slurp;
use File::Find::Rule;
use Mojo::DOM;
use YAML qw(Dump Load DumpFile LoadFile);

my $file = shift || '/Users/wangq/Downloads/wangq_alignDB_master.html';
die "Provide a valid html file!\n" unless $file;

my $minicpan = '/Users/wangq/minicpan';

# find ~/minicpan -type f | perl -nl -e '/CHECKSUMS/ and next; s/^.*\.//; print' | sort | uniq
my @all_files
    = File::Find::Rule->file->name( "*.bz2", "*.gz", "*.tgz", "*.zip" )
    ->in($minicpan);

my $html = read_file($file);
my $dom  = Mojo::DOM->new($html);

my $string = $dom->find('span.dist-name')->map('text')->join("\n");

#print $string;

my @els = grep {defined} split /\n/, $string;

my @not_found;
my @found;
my @bio;

for my $el (@els) {
    print $el, "\n";

    my $module = $el;
    $module =~ s/\-.[v\d\._]+$//;
    $module =~ s/-/::/g;

    my @gzs = grep { index( $_, "/$el" ) != -1 } @all_files;

    if ( $el =~ /Bio|AlignDB/ ) {
        push @bio, $el;
    }
    elsif ( @gzs == 0 ) {
        push @not_found, $module;
    }
    elsif ( $el =~ /libwww/ ) {
        push @found, 'LWP::Simple';
    }
    else {
        push @found, $module;
    }
}

open my $fh, '>', 'stpan.txt';

for my $el (@found) {
    print {$fh} "cpanm --verbose --mirror-only --mirror ~/minicpan $el\n";
}

for my $el (@not_found) {
    print {$fh}
        "cpanm --verbose --mirror-only --mirror https://stratopan.com/wangq/alignDB/master $el\n";
}

for my $el (@bio) {
    print {$fh}
        "# cpanm --verbose --mirror-only --mirror https://stratopan.com/wangq/alignDB/master $el\n";

}

close $fh;

