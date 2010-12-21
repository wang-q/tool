#!/usr/bin/perl
use strict;
use warnings;

use List::MoreUtils qw(uniq);
use AlignDB::Util qw(:all);

my $filename = shift or die "Need a filename\n";

my ( $seq_of, $seq_names ) = read_fasta($filename);

my @seq_names = uniq( @{$seq_names} );

open my $fh, '>', $filename . ".new";
for my $seq_name (@seq_names) {
    print {$fh} ">$seq_name\n";
    print {$fh} $seq_of->{$seq_name}, "\n";
}
close $fh;
