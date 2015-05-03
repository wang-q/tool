#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use Pod::Usage;
use YAML qw(Dump Load DumpFile LoadFile);

use Path::Class;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $backup_dir = dir( $ENV{HOME}, 'software', 'Backup', 'Mac' )->stringify;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
    'd|dir'  => \$backup_dir,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# directories to be backuped
#----------------------------------------------------------#
my %backup_of = (

    package_list => {
        action => sub {
            system "brew tap > $ENV{HOME}/brew_tap.txt";
            system "brew list > $ENV{HOME}/brew_list.txt";
            system "brew cask list > $ENV{HOME}/brew_cask_list.txt";
            system "pip list > $ENV{HOME}/pip_list.txt";
            system
                "ls $ENV{HOME}/Library/R/3.1/library/ > $ENV{HOME}/r_list.txt";
            system "tlmgr list --only-installed > $ENV{HOME}/tlmgr_list.txt";
        },
        file => [
            file( $ENV{HOME}, 'brew_tap.txt' ),
            file( $ENV{HOME}, 'brew_list.txt' ),
            file( $ENV{HOME}, 'brew_cask_list.txt' ),
            file( $ENV{HOME}, 'pip_list.txt' ),
            file( $ENV{HOME}, 'r_list.txt' ),
            file( $ENV{HOME}, 'tlmgr_list.txt' ),
        ],

    },

    Firefox => {
        dir =>
            [ dir( $ENV{HOME}, 'Library', 'Application Support', 'Firefox' ), ],
    },

    ActiveState => {
        dir => [
            dir( $ENV{HOME}, 'Library', 'Application Support', 'KomodoIDE' ),
            dir( $ENV{HOME}, 'Library', 'Application Support', 'Komodo IDE' ),
            dir( $ENV{HOME}, 'Library', 'Application Support', 'ActiveState' ),
        ],
        file => [
            file(
                $ENV{HOME},            'Library',
                'Application Support', 'ActiveState',
                'ActiveState.lic'
            ),
        ],
    },

    dots => {
        dir => [
            dir( $ENV{HOME}, '.crossftp' ),
            dir( $ENV{HOME}, '.ssh' ),
            dir( $ENV{HOME}, '.parallel' ),
            dir( $ENV{HOME}, '.vim' ),
            dir( $ENV{HOME}, '.vimperator' ),
        ],
        file => [
            file( $ENV{HOME}, '.bash_profile' ),
            file( $ENV{HOME}, '.bashrc' ),
            file( $ENV{HOME}, '.gitconfig' ),
            file( $ENV{HOME}, '.ncbirc' ),
            file( $ENV{HOME}, '.wgetrc' ),
            file( $ENV{HOME}, '.screenrc' ),
            file( $ENV{HOME}, '.vimrc' ),
            file( $ENV{HOME}, '.vimperatorrc' ),
        ],
    },

    Scripts => { dir => [ dir( $ENV{HOME}, 'Scripts' ), ], },

    zotero => { dir => [ dir( $ENV{HOME}, 'zotero' ), ], },

    ultraedit => {
        dir => [
            dir( '/Applications', 'UltraEdit.app' ),
            dir( $ENV{HOME}, 'Library', 'Application Support', 'UltraEdit' ),
        ],
    },

    beyondcompare => {
        dir => [
            dir( '/Applications', 'Beyond Compare.app' ),
            dir($ENV{HOME},            'Library',
                'Application Support', 'Beyond Compare'
            ),
        ],
    },
);

#----------------------------------------------------------#
# Start
#----------------------------------------------------------#
BACKUP: for my $key ( keys %backup_of ) {
    my $zipped_file = file( $backup_dir, "$key.zip" );
    if ( -e $zipped_file ) {
        print "=== $zipped_file already exists, skip it\n\n";
        next BACKUP;
    }

    print "=== Start backuping [$key] as $zipped_file\n";

    my $zip = Archive::Zip->new;
    my @temp_files;

    # execute actions before backup
    if ( exists $backup_of{$key}->{action} ) {
        print "Execute actions of [$key]\n";
        $backup_of{$key}->{action}->();
    }

    # delete directories
    if ( exists $backup_of{$key}->{delete} ) {
        for my $del ( @{ $backup_of{$key}->{delete} } ) {
            next if !-e $del;
            if ( !-d $del ) {
                warn "$del is not a directory!\n";
                warn "Stop backuping [$key]\n";
                next BACKUP;
            }
            print "Delete directory tree $del\n";
            $del->rmtree;
        }
    }

    # backup directories
    if ( exists $backup_of{$key}->{dir} ) {
        for my $dir ( @{ $backup_of{$key}->{dir} } ) {
            if ( !-d $dir ) {
                warn "$dir is not a directory!\n";
                warn "Stop backuping [$dir]\n";
                next;
            }
            print "Add directory tree $dir to archive\n";
            $zip->addTree( "$dir", $dir->dir_list(-1) );    # stringify
        }
    }

    # backup files
    if ( exists $backup_of{$key}->{file} ) {
        for my $file ( @{ $backup_of{$key}->{file} } ) {
            if ( !-e $file ) {
                warn "$file does not exist!\n";
                warn "Stop backuping [$file]\n";
                next;
            }
            print "Add file $file to archive\n";
            $zip->addFile( "$file", $file->basename );    # stringify
        }
    }

    # comments attached to the archive
    $backup_of{$key}->{time} = scalar localtime;
    $zip->zipfileComment( "Backup comments:\n" . Dump $backup_of{$key} );

    # write backup file to disks
    unless ( $zip->writeToFileNamed("$zipped_file") == AZ_OK ) {
        die "write error\n";
    }

    # clear temporary files
    for (@temp_files) {
        unlink $_;
    }

    print "=== Finish backuping [$key]\n\n";
}

exit;

__END__

=head1 NAME

make_backups.pl - Backup directories and files in your machine

=head1 SYNOPSIS

perl make_backups.pl [options] [file ...]
  Options:
    --help              brief help message
    --man               full documentation
    -d, --backup_dir    where to store backup files

=cut
