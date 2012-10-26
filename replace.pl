#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use Pod::Usage;
use File::Find::Rule;

# axt
my $dir = '.';
my $find;
my $replace;
my $pattern;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'    => \$help,
    'man'       => \$man,
    'dir=s'     => \$dir,
    'find=s'    => \$find,
    'replace=s' => \$replace,
    'pattern=s' => \$pattern,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my @files;
if ($pattern) {
    @files = sort File::Find::Rule->file->name($pattern)->in($dir);
}
else {    # find out all ascii file
    @files = File::Find::Rule->file->ascii->in($dir);
}

$find    = quotemeta $find;
$replace = $replace;

for my $file (@files) {

    # read in
    open my $in_fh, "<", $file;
    my $content = do { local $/; <$in_fh> };
    close $in_fh;

    # replace
    my $times = $content =~ s/$find/$replace/g;
    next unless $times;
    print "Replace $times times in $file\n";

    # write out
    open my $out_fh, ">", $file;
    print {$out_fh} $content;
    close $out_fh;
    print "\n";
}

exit;

__END__

=head1 NAME

    replace.pl - replace strings in a directory

=head1 SYNOPSIS

    perl replace.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        --dir               directory
        --find              find what
        --replace           replace with
        --pattern           filename pattern

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
