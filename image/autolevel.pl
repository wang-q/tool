#!/usr/bin/perl
use strict;
use warnings;

use Image::Magick;
use File::Find::Rule;
use YAML qw(Dump Load DumpFile LoadFile);

my $dir = shift @ARGV;
die unless -d $dir;
my @files = File::Find::Rule->file->name('*.jpg', '*.JPG')->in($dir);

for my $file (@files) {
    print "Processing [$file]\n";
    my $newfile = $file;
    $newfile =~ s/\.jpg$/\.new\.jpg/i;
    
    my $model = Image::Magick->new;
    $model->ReadImage($file);

    print "Auto-gamma...\n";
    my $example = $model->Clone;
    $example->AutoGamma;
    $example->AutoLevel;
    $example->Write($newfile);
}
