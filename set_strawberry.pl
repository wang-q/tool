#!/usr/bin/perl
use strict;
use warnings;

use Win32::Env;

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
    GTK_BASEPATH    => qw{ C:\strawberry\c },
    INCLUDE         => [qw{ C:\strawberry\c\include }],
    LIB             => [qw{ C:\strawberry\c\lib }],
    PATH            => [qw{ C:\strawberry\c\bin }],
    PKG_CONFIG_PATH => [qw{ C:\strawberry\c\lib\pkgconfig }],
};

# Misc variables
# See the follow link for details
# http://win32.perl.org/wiki/index.php?title=Environment_Variables
my $add_misc = {
    EDITOR      => qw{ D:/Tools/vim/gvim.exe },
    VISUAL      => qw{ D:/Tools/vim/gvim.exe },
    HOME        => $ENV{HOMEDRIVE} . $ENV{HOMEPATH},
    PGPLOT_FONT => qw{ C:\strawberry\perl\bin\grfont.dat },
};

# Other bin paths in D:\Tools
my $add_others = {
    PATH => [
        qw{
            D:\Tools\clustalw1.83.XP
            D:\Tools\muscle
            D:\Tools\paml\bin
            D:\Tools\Primer3
            D:\Tools\graphviz\bin
            D:\Tools\MySQL\bin
            D:\Tools\SQLite
            D:\Tools\subversion
            D:\Tools\Perforce
            D:\Tools\Git\cmd
            D:\Tools\CMake\bin
            D:\Tools\ImageMagick
            D:\Tools\GnuPG
            D:\Tools\vim
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
            my @exists = split /;/, GetEnv( ENV_SYSTEM, $key );
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
