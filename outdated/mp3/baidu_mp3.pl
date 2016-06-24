#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use FindBin;
use Path::Class;
use File::stat;
use List::Util qw(first);
use URI::Escape;
use Encode qw(encode decode);
use LWP::UserAgent;
use WWW::Mechanize;
use Win32::IE::Mechanize;
use Number::Format qw(:subs);

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read("$FindBin::Bin/config.ini");

my $dir       = $Config->{main}{dir};
my $overwrite = $Config->{main}{overwrite};
my $size_min  = $Config->{main}{size_min};
my $size_max  = $Config->{main}{size_max};

my ( $url, $top500, $new100 );

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'        => \$help,
    'man'           => \$man,
    'dir|d=s'       => \$dir,
    'overwrite|o=s' => \$overwrite,
    '500|5|t'       => \$top500,
    '100|1|n'       => \$new100,
    'url|u=s'       => \$url,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

if ( !$url ) {
    if ($top500) {
        $url = $Config->{url}{top500};
    }
    elsif ($new100) {
        $url = $Config->{url}{top100};
    }
    else {
        $url = $Config->{url}{default};
    }
}

unless ( -e $dir ) {
    mkdir $dir, 0777
        or die "Cannot create \"$dir\" directory: $!";
}

my $avoid_song = sub {
    first { $_[0] eq $_ } split /,/, $Config->{avoid}{songs};
};
my $avoid_singer = sub {
    first { $_[0] eq $_ } split /,/, $Config->{avoid}{singers};
};
my $avoid_url = sub {
    first { $_[0] =~ /$_/ } split /,/, $Config->{avoid}{urls};
};

#----------------------------------------------------------#
# run!!
#----------------------------------------------------------#
# init browser once, use throughout the script
my $ie_mech = Win32::IE::Mechanize->new;

print "Address: $url\n";
print "Get pages...\n";
my $main_page_obj = get_page_obj($url);

print "Parsing song urls...\n";
my @songs = get_song_links($main_page_obj);
print "Find " . scalar @songs . " songs\n";

print "Getting every songs\n";
for (@songs) {
    next unless $_->{song} and $_->{singer};
    next if $avoid_song->( $_->{song} );
    next if $avoid_singer->( $_->{singer} );

    print "[Song]\n",   $_->{song},   "\n";
    print "[Singer]\n", $_->{singer}, "\n";
    print "[Url]\n",    $_->{url},    "\n";

    my $filename = $_->{singer} . " - " . $_->{song} . ".mp3";
    $filename = file( $dir, $filename )->stringify if $dir;

    # 如果文件已存在，且$overwrite为否，则跳过当前文件
    if ( -e $filename and !$overwrite ) {
        print "$filename already exists.\n\n";
        next;
    }

    $_->{file} = $filename;

    get_the_song($_);
    print "\n";
}

exit;

#----------------------------------------------------------#
# Subroutine
#----------------------------------------------------------#
sub get_page_obj {
    my $url = shift;

    my $mech = WWW::Mechanize->new;
    $mech->get($url);

    return $mech;
}

sub get_song_links {
    my $mech = shift;
    my @links = $mech->find_all_links( url_regex => qr/.*\+.*$/ );
    my @songs;
    for (@links) {
        my $url = $_->url;
        my ( $song, $singer ) = $url =~ /word=(.*)\+(.*)\&lm/;
        $song   = uri_unescape($song);
        $singer = uri_unescape($singer);

        $song = decode( "cp936", $song );
        $song = encode( "cp936", $song );
        $singer = decode( "cp936", $singer );
        $singer = encode( "cp936", $singer );

        my $song_name = $_->text;
        push @songs, { url => $url, song => $song, singer => $singer };
    }

    return @songs;
}

sub get_file_size {
    my $url = shift;

    my $ua = LWP::UserAgent->new( timeout => 10 );

    my $res = $ua->head($url);
    if ( $res->is_success ) {
        my $headers = $res->headers;
        return $headers->content_length;
    }

    return 0;
}

sub get_the_song {
    my $song      = shift;
    my $song_name = $song->{song};
    my $filename  = $song->{file};

    my $mech = get_page_obj( $song->{url} );
    my @all_links = $mech->links( url_regex => qr/=baidusg/ );
    my @song_urls;
    for (@all_links) {
        my $link_url  = $_->url;
        my $link_text = $_->text;
        if ( $link_url =~ /word=(mp3)/ ) {
            push @song_urls, $link_url;
        }
    }
    print "Find ", scalar @all_links, " links\n";

URL: for (@song_urls) {
        $ie_mech->get($_);
        my $song_link = $ie_mech->find_link( text_regex => qr/\.\.\./ );
        next URL if !defined $song_link;    # 未找到链接
        my $song_url = $song_link->url;

        next URL if $avoid_url->($song_url);
        print "From url: $song_url\n";

        # 格式应为mp3
        $song_url =~ /mp3/ or next URL;

        # 判断文件大小
        my $remote_size = get_file_size($song_url);
        next URL unless $remote_size;
        print "Remote file size: ", format_bytes($remote_size), "\n";
        next if $remote_size == 4_510_966;    # an evil website
        next if $remote_size < $size_min;
        next if $remote_size > $size_max;

        get_file( $song_url, $filename );

        # 本地文件与远端文件大小不一致
        next URL if !-e $filename;
        if ( stat($filename)->size != $remote_size ) {
            unlink $filename;
            next URL;
        }

        print "$filename saved.\n\n";
        last;
    }

    return;
}

sub get_file {
    my $url      = shift;
    my $filename = shift;

    my $cmd = "curl $url -o \"$filename\" --max-time 180";
    print "$cmd\n";
    system($cmd );

    return;
}

__END__

=head1 NAME

    baidu_mp3.pl - 百度MP3下载工具

=head1 SYNOPSIS
    perl baidu_mp3.pl
    
    realign.pl [options]
     Options:
       --help            brief help message
       --man             full documentation
       --500 -5 -t       下载歌曲TOP500(默认下载位置)
       --100 -1 -n       下载新歌TOP100
       --url             指定下载url
       --dir             下载目录

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

