#!/usr/bin/perl
package GmailNotifier;
use Moose;
use AnyEvent;
use AnyEvent::Gmail::Feed;
use Growl::GNTP;

use FindBin;

with 'MooseX::Getopt';

has 'username' => ( is => 'rw', isa => 'Str', required => 1 );
has 'password' => ( is => 'rw', isa => 'Str', required => 1 );
has 'interval' => ( is => 'rw', isa => 'Int', default  => 60 );

binmode STDOUT if $^O eq 'MSWin32';

sub run {
    my $self = shift;

    my $growl = Growl::GNTP->new( AppName => "gmail notifier", );
    $growl->register( [ { Name => "gmail", } ] );

    AnyEvent::Gmail::Feed->new(
        username     => $self->username,
        password     => $self->password,
        interval     => $self->interval,
        on_new_entry => sub {
            my $entry = shift;
            print "[Unread mail] \n",
              "[Title] " . $entry->title . "\n",
              "[Message] " . $entry->summary . "\n",
              "\n";
            $growl->notify(
                Event   => "gmail",
                Title   => $entry->title,
                Message => $entry->summary,
                Icon    => "$FindBin::Bin/gmail.jpg",
            );

        },
    );
    AnyEvent->condvar->recv;
}

package main;
GmailNotifier->new_with_options->run;

__END__

perl gmail-nofifier.pl --username XXX --password XXX
