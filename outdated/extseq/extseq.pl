#!/usr/bin/perl
use strict;
use warnings;

package MyApp;
use Wx;
use base 'Wx::App';

use FindBin;
use lib "$FindBin::Bin/lib";
require Dialog;

sub OnInit {
    my $self = shift;
    
    my $dialog = Dialog->new;
    $self->SetTopWindow( $dialog );
    $dialog->Show(1);
    
    return 1;
}

package main;

my $app = MyApp->new;
$app->MainLoop;
