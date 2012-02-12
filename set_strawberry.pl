#!/usr/bin/perl
use strict;
use warnings;

use Win32;
use Win32::Env;

# check admin rights
# On Windows vista and 7, you should run this script as Administrator
print Win32::GetOSDisplayName(), "\n\n";
if ( Win32::IsAdminUser() ) {
    print "Got admin rights, continue.\n\n";
}
else {
    print "Your should get admin rights first to run this script.\n\n";
    exit 1;
}

# INCLUDE, LIB and PATH
my $add = {
    INCLUDE => [
        qw{
            C:\strawberry\c\include
            C:\strawberry\perl\lib\CORE
            }
    ],
    LIB => [
        qw{
            C:\strawberry\c\lib
            C:\strawberry\perl\bin
            }
    ],
    PATH => [
        qw{
            C:\strawberry\c\bin
            C:\strawberry\perl\bin
            C:\strawberry\perl\site\bin
            }
    ],
    PKG_CONFIG_PATH => [qw{ C:\strawberry\c\lib\pkgconfig }],
};

# GTK related variables
# Move all gtk files to c/
my $add_gtk = {
    GTK_BASEPATH    => qw{ C:\strawberry\gtk },
    INCLUDE         => [qw{ C:\strawberry\gtk\include }],
    LIB             => [qw{ C:\strawberry\gtk\lib }],
    PATH            => [qw{ C:\strawberry\gtk\bin }],
    PKG_CONFIG_PATH => [qw{ C:\strawberry\gtk\lib\pkgconfig }],
};

# Misc variables
# See the follow link for details
# http://win32.perl.org/wiki/index.php?title=Environment_Variables
my $add_misc = {
    EDITOR => qw{ c:/Tools/vim/gvim.exe },
    VISUAL => qw{ c:/Tools/vim/gvim.exe },
    HOME   => $ENV{HOMEDRIVE} . $ENV{HOMEPATH},
    PGPLOT_FONT =>
        qw{ C:\strawberry\perl\site\lib\PGPLOT\pgplot_supp\grfont.dat },
    PLPLOT_LIB => qw{ c:\strawberry\perl\site\lib\PDL\plplot_supp },
    PROJ_LIB   => qw{ c:\strawberry\perl\site\lib\PDL\proj_supp },
};

# Other bin paths in D:\Tools
my $add_others = {
    PATH => [
        qw{
            c:\Tools\clustalw1.83.XP
            c:\Tools\muscle
            c:\Tools\mafft
            c:\Tools\paml\bin
            c:\Tools\Primer3
            c:\Tools\graphviz\bin
            c:\Tools\MySQL\bin
            c:\Tools\SQLite
            c:\Tools\subversion
            c:\Tools\Perforce
            c:\Tools\Git\cmd
            c:\Tools\CMake\bin
            c:\Tools\ImageMagick
            c:\Tools\GnuPG
            c:\Tools\vim
            c:\Tools\putty
            c:\Tools\python
            c:\Tools\R\bin
            c:\Tools\curl
            d:\wq\Scripts\tool
            }
    ],
};

# Actually do things
add($add)        and print "Set INCLUDE, LIB and PATH\n";
add($add_gtk)    and print "Set GTK related variables\n";
add($add_misc)   and print "Set misc variables\n";
add($add_others) and print "Set other bin paths\n";

# Associate .pl with perl
system('ASSOC .pl=PerlScript');
system('FTYPE PerlScript=C:\strawberry\perl\bin\perl.exe %1 %*');

# Pass a hashref to this sub.
# The key-value pairs are env keys and values.
# When the value is an arrayref, the content will be appended to existing
# values. When the value is a string, the content will be write directly to
# the env variable, overwriting existing one.
sub add {
    my $dispatch = shift;

    for my $key ( sort keys %$dispatch ) {
        my $value = $dispatch->{$key};
        if ( ref $value eq 'ARRAY' ) {
            my @exists;
            eval { @exists = split /;/, GetEnv( ENV_SYSTEM, $key ); };
            print $@, "\n" if $@;
            for my $add (@$value) {
                @exists = grep { lc $add ne lc $_ } @exists;
                push @exists, $add;
            }
            SetEnv( ENV_SYSTEM, $key, join( ';', @exists ) );
        }
        else {
            SetEnv( ENV_SYSTEM, $key, $value );
        }
    }

    return 1;
}
