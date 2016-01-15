#!/usr/bin/env perl
###
# This snippet will recursively scan directories for use/require statements
# in perl scripts or modules, making it easy to build a list of dependencies
# from code you've inherited or neglected to document.
###
use Perl::PrereqScanner;
use File::Spec::Functions qw( catfile );
use File::Find qw(finddepth);
use YAML qw(Dump Load DumpFile LoadFile);
use 5.014;
my @files;

my $source_files = shift || '.';

finddepth(
    sub {
        return if ( $_ eq '.' || $_ eq '..' );
        push @files, $File::Find::name if $_ =~ m/\.(?:pl|pm)$/;
    },
    $source_files
);

my $scanner = Perl::PrereqScanner->new;

my %deps;

for my $filename (@files) {

    # returns a CPAN::Meta::Requirements hashref of requirements
    my $prereqs = $scanner->scan_file($filename);

    foreach my $mod ( keys $prereqs->{'requirements'} ) {
        push( @{ $deps{$mod} }, $filename );
    }
}

print Dump(\%deps);
