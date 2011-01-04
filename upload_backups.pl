#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use Path::Class;
use Net::FTP;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

my $backup_dir = 'F:\Software\AppData';
my $remote_dir = 'AppData';

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'         => \$help,
    'man'            => \$man,
    'b|backup_dir=s' => \$backup_dir,
    'r|remote_dir=s' => \$remote_dir,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# Start
#----------------------------------------------------------#
my $dir = dir($backup_dir);

while ( my $file = $dir->next ) {
    next unless -f $file;
    upload( $remote_dir, $file );
}

exit;

sub upload {
    my $remotedir = shift;
    my $file      = shift;

    my $absname  = $file->absolute->stringify;
    my $basename = $file->basename;

    my $ftpserver = "rukh.nju.edu.cn";
    my $user      = "wangq";
    my $pass      = "111111";

    my $ftp = Net::FTP->new( $ftpserver, Debug => 1, Passive => 1, )
        or die "Cannot connect to $ftpserver: $@";
    $ftp->login( $user, $pass )
        or die "Cannot login ", $ftp->message;
    $ftp->cwd($remotedir)
        or die "Cannot change working directory ", $ftp->message;
    $ftp->delete($basename) or warn "delete failed ", $ftp->message;
    $ftp->binary;
    $ftp->hash( 1, 1024 * 1024 );
    $ftp->put($absname) or die "put failed ", $ftp->message;
    $ftp->quit;

    return;
}

__END__

=head1 NAME

  upload_backups.pl - Upload backup files to a remote ftp server

=head1 SYNOPSIS

  perl upload_backups.pl [options] [file ...]
    Options:
      --help              brief help message
      --man               full documentation
      -b, --backup_dir    where to store backup files
      -r, --remote_dir    remote dir in the ftp server

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
