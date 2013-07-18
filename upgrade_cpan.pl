#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use CPAN;
use ExtUtils::Installed;
use Module::CoreList;
use version;
use List::Util qw(first);

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

my $upgrade_dual;
my $upgrade_installed;

my $stay_in_shell;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
    'ud'     => \$upgrade_dual,
    'ui'     => \$upgrade_installed,
    'ss'     => \$stay_in_shell,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# Init CPAN
#----------------------------------------------------------#
# force reload index
CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->force_reload;

our $report = "";

#----------------------------------------------------------#
# Install modules in @ARGV or upgrade exists
#----------------------------------------------------------#
if (@ARGV) {
    upgrade_modules(@ARGV);
}
elsif ($upgrade_dual) {
    upgrade_dual();
}
elsif ($upgrade_installed) {
    upgrade_installed();
}
else {
    upgrade_dual();
    upgrade_installed();
}

# print reports
$report = join "\n", sort split /\n/, $report;
box_message( "All modules processed\n" . $report );

END {
    if ($stay_in_shell) {
        CPAN::shell();
    }
    exit;
}

#----------------------------------------------------------#
# Subroutines
#----------------------------------------------------------#
sub box_message {
    my $message = shift;

    print "\n", "=" x 30, "\n";
    print $message, "\n";
    print "=" x 30, "\n\n";
}

sub upgrade_modules {
    my @modules = @_;

    for my $module (@modules) {
        my $mo = CPAN::Shell->expand( Module => $module );

        next unless defined $mo;
        next if $mo->cpan_file =~ /perl\-5/;  # only upgrade dual life modules

        my $cpan_version = version->parse( $mo->cpan_version );

        # upgrade or fresh install
        if ( $mo->inst_file ) {
        	my $inst_version;
            eval {
            $inst_version = version->parse( $mo->inst_version );
            };
            if ($@) {
            	warn "Unable parse the module version of [$module].\n";
            	next;
            }
            
            if ( $cpan_version > $inst_version ) {
                box_message("[$module] $cpan_version > $inst_version");

                CPAN::Shell->install($mo);

                my $new_inst_version = version->parse( $mo->inst_version );
                if ( $cpan_version == $new_inst_version ) {
                    $report
                        .= "[$module] has been upgraded from $inst_version to $cpan_version\n";
                }
                else {
                    $report
                        .= "Fail to upgrade [$module] from $inst_version to $cpan_version\n";
                }
            }
        }
        else {
            CPAN::Shell->install($mo);

            my $new_inst_version = version->parse( $mo->inst_version );
            if ( $cpan_version == $new_inst_version ) {
                $report .= "[$module] $cpan_version has been installed\n";
            }
            else {
                $report .= "Fail to install [$module] $cpan_version\n";
            }
        }
    }
}

sub upgrade_dual {

    my @cores = Module::CoreList->find_modules(qr/./);    # find core modules
    print "Find ", scalar @cores, " core modules\n";

    my @lists;
    for ( skip_filter(@cores) ) {
        my $mo = CPAN::Shell->expand( Module => $_ );
        next unless defined $mo;
        next unless $mo->inst_file;
        push @lists, $_;
    }

    upgrade_modules(@lists);
    print "Upgrading dual life modules finished\n";
}

sub upgrade_installed {

    print "Reading local .packlists\n";    # find installed modules
    my $inst    = ExtUtils::Installed->new;
    my @modules = $inst->modules;
    print "Find ", scalar @modules, " modules\n";

    @modules = skip_filter(@modules);
    upgrade_modules(@modules);
    print "Upgrading installed modules finished\n";
}

sub skip_filter {
    my @lists = @_;

    # skip these modules
    my @skips = qw {
		Ace BerkeleyDB Bio Bio::Perl Cairo Data DB_File DBD::mysql Devel::Cover
		Devel::NYTProf Event GD Glib Goo::Canvas Graphviz Growl::GNTP
		Getopt::Lucid Gtk2 KinoSearch IO::AIO IO::Socket::SSL Image::Magick
		Math::Pari Math::BigInt::GMP Math::MPC Math::MPFR Module::ScanDeps
		Net::Ping Net::Server Net::SSH2 OpenGL POE::Loop::Gtk PPM Pango Perl
		PerlCryptLib Probe::Perl Socket Term::ReadLine Test::Dependencies Text
		Text::Iconv Time::y2038 Win32API::Registry Wx Wx::GLCanvas
		Wx::PdfDocument XML::Parser::Style::EasyTree mod_perl XML::LibXML 
    };

    my @skips_qr = ( qr/compress/i, qr/SOAP/, qr/PDL/ );

    my @upgrades;
    for my $one (@lists) {
        next if first { $one eq $_ } @skips;
        next if first { $one =~ $_ } @skips_qr;
        push @upgrades, $one;
    }

    return @upgrades;
}
