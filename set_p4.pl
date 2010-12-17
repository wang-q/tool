#!/usr/bin/perl
use strict;
use warnings;

use Win32::Env;

my $add_misc = {
    P4HOST   => qw{ wangq-laptop },
    P4PORT   => qw{ rukh.nju.edu.cn:1666 },
    P4USER   => qw{ wangq },
    P4PASSWD => qw{ 111111 },
    P4CLIENT => qw{ wangq-laptop  },
};

# Actually do things
add($add_misc) and print "Set p4 variables\n";

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
