package Dialog;
use strict;
use warnings;

use Wx qw(
    :sizer :textctrl :staticline :id :font :color
    :filedialog :dirdialog
);
use Wx::Event qw(
    EVT_BUTTON EVT_CLOSE EVT_CHOICE
);
use base qw(Wx::Dialog);
use base qw(Class::Accessor);

use Cwd;
use File::Spec;
use Bio::Seq;
use Bio::SeqIO;

use YAML qw(Dump Load DumpFile LoadFile);

use FindBin;
use lib "$FindBin::Bin/lib";

# these attributes are all wxWidgets object, which should be accessed by
# set_value and get_value
__PACKAGE__->mk_accessors(
    qw(
        filename format seq_start seq_end
        outdir wrap_seq wrap_length upper_case
        )
);

# these attributes should be accessed directly
__PACKAGE__->mk_accessors(
    qw( previous_directory )
);

sub new {
    my $ref  = shift;
    my $self = $ref->SUPER::new(
        undef,                 # parent window
        -1,                    # ID -1 means any
        'Extract Sequence',    # title
        [ -1, -1 ],            # default position
        [ -1, -1 ],            # size
    );

    $self->build_window;

    EVT_CLOSE( $self, \&event_close_window );

    return $self;
}

sub build_panel {
    my $self  = shift;
    my $panel = shift;
    my $sizer = shift;

    {    # use GridBagSizer
        my $gb_sizer = Wx::GridBagSizer->new;
        $gb_sizer->AddGrowableCol(1);
        $sizer->Add( $gb_sizer, 0, wxGROW, 0 );

        # filename
        $self->add_gb_static_text( $panel, $gb_sizer, "Filename:", [ 0, 0 ] );
        $self->add_gb_text_ctrl(
            $panel, $gb_sizer, "filename",
            [ 0,  1 ],
            [ 1,  5 ],
            [ 80, -1 ]
        );

        $self->add_gb_bitmap_button( $panel, $gb_sizer,
            $self->get_bitmap_open, \&event_open_file, [ 0, 6 ],
        );

        # extract
        $self->add_gb_static_text( $panel, $gb_sizer, "Extract", [ 1, 0 ] );

        $self->add_gb_static_text( $panel, $gb_sizer, "from", [ 1, 1 ] );
        $self->add_gb_text_ctrl(
            $panel, $gb_sizer, "seq_start", [ 1, 2 ],
            [ 1, 1 ], [ 80, -1 ]
        );
        $self->add_gb_static_text( $panel, $gb_sizer, "to", [ 1, 3 ] );
        $self->add_gb_text_ctrl(
            $panel, $gb_sizer, "seq_end",
            [ 1,  4 ],
            [ 1,  2 ],
            [ 80, -1 ]
        );

        $self->add_gb_bitmap_button( $panel, $gb_sizer,
            $self->get_bitmap_info, \&about_dialog, [ 1, 6 ],
        );

        # output dir
        $self->add_gb_static_text( $panel, $gb_sizer, "Output dir:",
            [ 2, 0 ] );
        $self->add_gb_text_ctrl(
            $panel, $gb_sizer, "outdir",
            [ 2,  1 ],
            [ 1,  4 ],
            [ 80, -1 ]
        );

        $self->add_gb_bitmap_button( $panel, $gb_sizer,
            $self->get_bitmap_auto, \&event_auto_output_dir, [ 2, 5 ],
        );

        $self->add_gb_bitmap_button( $panel, $gb_sizer,
            $self->get_bitmap_open, \&event_open_output_dir, [ 2, 6 ],
        );
    }

    {
        $self->add_static_line( $panel, $sizer );

        my $boxsizer = $self->add_boxsizer_h($sizer);

        my $option_boxsizer = $self->add_boxsizer_v($boxsizer);

        $self->add_choice( $panel, $option_boxsizer, "format",
            [qw{Fasta Genbank EMBL}] );

        my $wrap_boxsizer = $self->add_boxsizer_h($option_boxsizer);
        $self->add_check_box( $panel, $wrap_boxsizer, "wrap_seq", "Wrap" );
        $self->add_text_ctrl( $panel, $wrap_boxsizer, "wrap_length", 0, 0,
            [ 30, -1 ] );

        $self->add_check_box( $panel, $option_boxsizer, "upper_case",
            "Upper case" );

        $boxsizer->AddSpacer(10);

        $self->add_button( $panel, $boxsizer, "Get and Save",
            \&event_get_and_save, 1 );
    }

    return;
}

sub build_window {
    my $self = shift;

    # init sizer
    my $main_sizer = Wx::BoxSizer->new(wxVERTICAL);
    $self->SetSizer($main_sizer);
    

    $self->build_panel( $self, $main_sizer );

    # automatic layout, size the window optimally and set its minimal size
    $self->SetAutoLayout(1);
    $self->SetSizerAndFit($main_sizer);
    $main_sizer->SetSizeHints($self);

    $self->set_value( 'wrap_seq',    1 );
    $self->set_value( 'wrap_length', 60 );
    $self->set_value( 'upper_case',  1 );

    return;
}

#----------------------------#
# setter and getter of object attrs which are all textctrl or checkbox
#----------------------------#
sub set_value {
    my $self  = shift;
    my $attr  = shift;
    my $value = shift;

    $self->{$attr}->SetValue($value) if defined $value;

    return;
}

sub get_value {
    my $self = shift;
    my $attr = shift;

    if ( ref $self->{$attr} eq "Wx::Choice" ) {
        return $self->{$attr}->GetStringSelection;
    }
    return $self->{$attr}->GetValue;
}

#----------------------------#
# methods creating unified widgets
#----------------------------#
sub add_static_text {
    my $self   = shift;
    my $parent = shift;
    my $sizer  = shift;
    my $text   = shift;

    my $static_text = Wx::StaticText->new( $parent, -1, $text );
    my $flag = wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxALL;
    $sizer->Add( $static_text, 0, $flag, 2 );

    return;
}

sub add_gb_static_text {
    my $self        = shift;
    my $parent      = shift;
    my $sizer       = shift;
    my $text        = shift;
    my $gb_position = shift;
    my $gb_span     = shift || [ 1, 1 ];

    my $static_text = Wx::StaticText->new( $parent, -1, $text );
    my $flag = wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT | wxALL;
    $sizer->AddWindow(
        $static_text,
        Wx::GBPosition->new( @{$gb_position} ),
        Wx::GBSpan->new( @{$gb_span} ),
        $flag, 2,
    );

    return;
}

sub add_text_ctrl {
    my $self           = shift;
    my $parent         = shift;
    my $sizer          = shift;
    my $object_attr    = shift;
    my $stretch_factor = shift || 0;
    my $text_style     = shift || 0;
    my $size           = shift || [ -1, -1 ];

    my $text_ctrl = Wx::TextCtrl->new( $parent, -1, '', [ -1, -1 ], $size,
        $text_style );
    my $flag = wxGROW | wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->Add( $text_ctrl, $stretch_factor, $flag, 2 );

    my $font = Wx::Font->new( 10, wxSWISS, wxNORMAL, wxNORMAL, 0, "Arial" );
    $text_ctrl->SetFont($font);

    $self->{$object_attr} = $text_ctrl;

    return;
}

sub add_gb_text_ctrl {
    my $self        = shift;
    my $parent      = shift;
    my $sizer       = shift;
    my $object_attr = shift;
    my $gb_position = shift;
    my $gb_span     = shift || [ 1, 1 ];
    my $size        = shift || [ -1, -1 ];

    my $text_ctrl = Wx::TextCtrl->new( $parent, -1, '', [ -1, -1 ], $size );
    my $flag = wxGROW | wxALIGN_CENTER_VERTICAL | wxALL;

    $sizer->AddWindow(
        $text_ctrl,
        Wx::GBPosition->new( @{$gb_position} ),
        Wx::GBSpan->new( @{$gb_span} ),
        $flag, 2,
    );

    my $font = Wx::Font->new( 10, wxSWISS, wxNORMAL, wxNORMAL, 0, "Arial" );
    $text_ctrl->SetFont($font);

    $self->{$object_attr} = $text_ctrl;

    return;
}

sub add_button {
    my $self           = shift;
    my $parent         = shift;
    my $sizer          = shift;
    my $text           = shift;
    my $event          = shift;
    my $stretch_factor = shift || 0;

    my $button = Wx::Button->new( $parent, -1, $text );
    my $flag = wxGROW | wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->Add( $button, $stretch_factor, $flag, 0 );

    EVT_BUTTON( $self, $button, $event );

    return;
}

sub add_bitmap_button {
    my $self   = shift;
    my $parent = shift;
    my $sizer  = shift;
    my $bitmap = shift;
    my $event  = shift;

    my $button = Wx::BitmapButton->new( $parent, -1, $bitmap );
    my $flag = wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->Add( $button, 0, $flag, 0 );

    EVT_BUTTON( $self, $button, $event );

    return;
}

sub add_gb_bitmap_button {
    my $self        = shift;
    my $parent      = shift;
    my $sizer       = shift;
    my $bitmap      = shift;
    my $event       = shift;
    my $gb_position = shift;
    my $gb_span     = shift || [ 1, 1 ];

    my $button = Wx::BitmapButton->new( $parent, -1, $bitmap );
    my $flag = wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->AddWindow(
        $button,
        Wx::GBPosition->new( @{$gb_position} ),
        Wx::GBSpan->new( @{$gb_span} ),
        $flag, 2,
    );

    EVT_BUTTON( $self, $button, $event );

    return;
}

sub add_check_box {
    my $self        = shift;
    my $parent      = shift;
    my $sizer       = shift;
    my $object_attr = shift;
    my $text        = shift || $object_attr;

    my $check_box = Wx::CheckBox->new( $parent, -1, $text, );
    my $flag = wxGROW | wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->Add( $check_box, 0, $flag, 2 );

    $self->{$object_attr} = $check_box;

    return;
}

sub add_choice {
    my $self        = shift;
    my $parent      = shift;
    my $sizer       = shift;
    my $object_attr = shift;
    my $choices     = shift || [$object_attr];
    my $selection   = shift || 0;

    my $choice
        = Wx::Choice->new( $parent, -1, [ -1, -1 ], [ 70, -1 ], $choices, );
    $choice->SetSelection($selection);
    my $flag = wxGROW | wxALIGN_CENTER_VERTICAL | wxALL;
    $sizer->Add( $choice, 0, $flag, 2 );

    $self->{$object_attr} = $choice;

    return;
}

sub add_static_line {
    my $self   = shift;
    my $parent = shift;
    my $sizer  = shift;

    my $static_line = Wx::StaticLine->new(
        $parent, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL
    );
    $sizer->AddWindow( $static_line, 0,
        wxGROW | wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    return;
}

sub add_boxsizer_h {
    my $self         = shift;
    my $parent_sizer = shift;

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $parent_sizer->Add( $sizer, 0, wxGROW, 0 );

    return $sizer;
}

sub add_boxsizer_v {
    my $self         = shift;
    my $parent_sizer = shift;

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $parent_sizer->Add( $sizer, 0, wxGROW, 0 );

    return $sizer;
}

#----------------------------#
# top panel callback events
#----------------------------#
sub event_close_window {
    my ( $self, $event ) = @_;

    $self->Destroy;
    return;
}

sub about_dialog {
    my $self = shift;
    my $info = Wx::AboutDialogInfo->new;

    $info->SetName('Extract Sequence');
    $info->SetVersion('0.4.0');
    $info->SetDescription("Extract Sequence");
    $info->SetCopyright("(C) 2005-2008 Wang Qiang");
    $info->SetLicense( "This program is free software;\n"
            . "you can redistribute it and/or modify\n"
            . "it under the same terms as Perl itself.\n" );
    $info->SetWebSite( 'http://where.can.I.find.you/',
        'We have no website yet' );
    $info->AddDeveloper('Wang Qiang <wangqiang1997@gmail.com>');
    $info->AddArtist('Wang Qiang <wangqiang1997@gmail.com>');
    $info->AddDocWriter('No documnets! Help me!');

    Wx::AboutBox($info);
    return;
}

sub event_open_file {
    my $self  = shift;
    my $event = shift;

    my $dialog = Wx::FileDialog->new(
        $self,
        "Select a file",
        $self->previous_directory || cwd,
        '',
        (   join '|',
            'All files (*.*)|*.*',
            'Fasta files (*.fa)|*.fa',
            'Genbank files (*.gb)|*.gb',
            'EMBL files (*.embl)|*.embl',
            'Text files (*.txt)|*.txt',
        ),
        wxFD_OPEN | wxFD_MULTIPLE
    );

    if ( $dialog->ShowModal == wxID_OK ) {
        my ($file) = $dialog->GetPaths;    # May return multiple files
        $self->set_value( "filename", $file );
        $self->previous_directory( $dialog->GetDirectory );
    }

    $dialog->Destroy;
    return;
}

sub event_open_output_dir {
    my $self  = shift;
    my $event = shift;

    my $dialog
        = Wx::DirDialog->new( $self, "Select a dir", $self->outdir || cwd(),
        );

    if ( $dialog->ShowModal == wxID_OK ) {
        my $dir = $dialog->GetPath;
        $self->set_value( "outdir", $dir );
    }

    $dialog->Destroy;
    return;
}

sub event_auto_output_dir {
    my $self  = shift;
    my $event = shift;

    my $outdir;
    my $filename = $self->get_value("filename");
    if ($filename) {
        my ( $volume, $directory, undef ) = File::Spec->splitpath($filename);
        $outdir = File::Spec->catpath( $volume, $directory );
    }
    else {
        $outdir = cwd();
    }
    $self->set_value( "outdir", $outdir );

    return;
}

sub event_get_and_save {
    my $self  = shift;
    my $event = shift;

    my $filename = $self->get_value('filename');
    return unless $filename;
    my $format = $self->get_value('format');
    my $outdir = $self->get_value('outdir');
    if ( !$outdir ) {
        $outdir = cwd();
        $self->set_value( "outdir", $outdir );
    }

    my $seqin = Bio::SeqIO->new(
        -file   => $filename,
        -format => $format
    );

    my $seq_obj = $seqin->next_seq;
    return unless $seq_obj;
    my $whole_seq    = $seq_obj->seq;
    my $total_length = length $whole_seq;

    my $seq_start = $self->get_value('seq_start');
    my $seq_end   = $self->get_value('seq_end');
    if ( !$seq_start ) {
        $seq_start = 1;
        $self->set_value( 'seq_start', $seq_start );
    }
    if ( !$seq_end ) {
        $seq_end = $total_length;
        $self->set_value( 'seq_end', $seq_end );
    }

    my $seq_length = $seq_end - $seq_start + 1;
    my $extract_seq = substr $whole_seq, $seq_start - 1, $seq_length;

    # Write output file.
    my ( undef, undef, $basename ) = File::Spec->splitpath($filename);
    my $outfile = File::Spec->catfile( $outdir,
        $basename . ".$seq_start-$seq_end.fasta" );

    open my $outfh, '>', $outfile or croak $!;
    print {$outfh} ">$basename|$seq_length|$seq_start-$seq_end\n";

    # Print in UPPER CASE or not.
    if ( $self->get_value('upper_case') ) {
        $extract_seq = uc $extract_seq;
    }
    else {
        $extract_seq = lc $extract_seq;
    }

    # Print in wrap mode or not.
    my $wrap_seq    = $self->get_value('wrap_seq');
    my $wrap_length = $self->get_value('wrap_length');
    if ( $wrap_seq and $wrap_length ) {
        for ( my $pos = 0; $pos < $seq_length; $pos += $wrap_length ) {
            print {$outfh} substr( $extract_seq, $pos, $wrap_length ), "\n";
        }
    }
    else {
        print {$outfh} $extract_seq, "\n";
    }
    close $outfh;

    return;
}

#----------------------------------------------------------#
# get bitmap icons
#----------------------------------------------------------#
sub get_bitmap_open {
    my $self = shift;

    my $xpm = <<'END';
/* XPM */
static char * shell32046_xpm[] = {
"16 16 256 2",
"   c #000000",
" * c #800000",
" . c #008000",
" o c #808000",
" # c #000080",
" + c #800080",
" @ c #008080",
" O c #C0C0C0",
" $ c #C0DCC0",
" 8 c #A6CAF0",
" 1 c #000033",
" u c #330000",
" g c #330033",
" c c #003333",
" m c #161616",
" s c #1C1C1C",
"*  c #222222",
"** c #292929",
"*. c #555555",
"*o c #4D4D4D",
"*# c #424242",
"*+ c #393939",
"*@ c #FF7C80",
"*O c #FF5050",
"*$ c #D60093",
"*8 c #CCECFF",
"*1 c #EFD6C6",
"*u c #E7E7D6",
"*g c #ADA990",
"*c c #33FF00",
"*m c #660000",
"*s c #990000",
".  c #CC0000",
".* c #003300",
".. c #333300",
".o c #663300",
".# c #993300",
".+ c #CC3300",
".@ c #FF3300",
".O c #006600",
".$ c #336600",
".8 c #666600",
".1 c #996600",
".u c #CC6600",
".g c #FF6600",
".c c #009900",
".m c #339900",
".s c #669900",
"o  c #999900",
"o* c #CC9900",
"o. c #FF9900",
"oo c #00CC00",
"o# c #33CC00",
"o+ c #66CC00",
"o@ c #99CC00",
"oO c #CCCC00",
"o$ c #FFCC00",
"o8 c #66FF00",
"o1 c #99FF00",
"ou c #CCFF00",
"og c #00FF33",
"oc c #3300FF",
"om c #660033",
"os c #990033",
"#  c #CC0033",
"#* c #FF0033",
"#. c #0033FF",
"#o c #333333",
"## c #663333",
"#+ c #993333",
"#@ c #CC3333",
"#O c #FF3333",
"#$ c #006633",
"#8 c #336633",
"#1 c #666633",
"#u c #996633",
"#g c #CC6633",
"#c c #FF6633",
"#m c #009933",
"#s c #339933",
"+  c #669933",
"+* c #999933",
"+. c #CC9933",
"+o c #FF9933",
"+# c #00CC33",
"++ c #33CC33",
"+@ c #66CC33",
"+O c #99CC33",
"+$ c #CCCC33",
"+8 c #FFCC33",
"+1 c #33FF33",
"+u c #66FF33",
"+g c #99FF33",
"+c c #CCFF33",
"+m c #FFFF33",
"+s c #000066",
"@  c #330066",
"@* c #660066",
"@. c #990066",
"@o c #CC0066",
"@# c #FF0066",
"@+ c #003366",
"@@ c #333366",
"@O c #663366",
"@$ c #993366",
"@8 c #CC3366",
"@1 c #FF3366",
"@u c #006666",
"@g c #336666",
"@c c #666666",
"@m c #996666",
"@s c #CC6666",
"O  c #009966",
"O* c #339966",
"O. c #669966",
"Oo c #999966",
"O# c #CC9966",
"O+ c #FF9966",
"O@ c #00CC66",
"OO c #33CC66",
"O$ c #99CC66",
"O8 c #CCCC66",
"O1 c #FFCC66",
"Ou c #00FF66",
"Og c #33FF66",
"Oc c #99FF66",
"Om c #CCFF66",
"Os c #FF00CC",
"$  c #CC00FF",
"$* c #009999",
"$. c #993399",
"$o c #990099",
"$# c #CC0099",
"$+ c #000099",
"$@ c #333399",
"$O c #660099",
"$$ c #CC3399",
"$8 c #FF0099",
"$1 c #006699",
"$u c #336699",
"$g c #663399",
"$c c #996699",
"$m c #CC6699",
"$s c #FF3399",
"8  c #339999",
"8* c #669999",
"8. c #999999",
"8o c #CC9999",
"8# c #FF9999",
"8+ c #00CC99",
"8@ c #33CC99",
"8O c #66CC66",
"8$ c #99CC99",
"88 c #CCCC99",
"81 c #FFCC99",
"8u c #00FF99",
"8g c #33FF99",
"8c c #66CC99",
"8m c #99FF99",
"8s c #CCFF99",
"1  c #FFFF99",
"1* c #0000CC",
"1. c #330099",
"1o c #6600CC",
"1# c #9900CC",
"1+ c #CC00CC",
"1@ c #003399",
"1O c #3333CC",
"1$ c #6633CC",
"18 c #9933CC",
"11 c #CC33CC",
"1u c #FF33CC",
"1g c #0066CC",
"1c c #3366CC",
"1m c #666699",
"1s c #9966CC",
"u  c #CC66CC",
"u* c #FF6699",
"u. c #0099CC",
"uo c #3399CC",
"u# c #6699CC",
"u+ c #9999CC",
"u@ c #CC99CC",
"uO c #FF99CC",
"u$ c #00CCCC",
"u8 c #33CCCC",
"u1 c #66CCCC",
"uu c #99CCCC",
"ug c #CCCCCC",
"uc c #FFCCCC",
"um c #00FFCC",
"us c #33FFCC",
"g  c #66FF99",
"g* c #99FFCC",
"g. c #CCFFCC",
"go c #FFFFCC",
"g# c #3300CC",
"g+ c #6600FF",
"g@ c #9900FF",
"gO c #0033CC",
"g$ c #3333FF",
"g8 c #6633FF",
"g1 c #9933FF",
"gu c #CC33FF",
"gg c #FF33FF",
"gc c #0066FF",
"gm c #3366FF",
"gs c #6666CC",
"c  c #9966FF",
"c* c #CC66FF",
"c. c #FF66CC",
"co c #0099FF",
"c# c #3399FF",
"c+ c #6699FF",
"c@ c #9999FF",
"cO c #CC99FF",
"c$ c #FF99FF",
"c8 c #00CCFF",
"c1 c #33CCFF",
"cu c #66CCFF",
"cg c #99CCFF",
"cc c #CCCCFF",
"cm c #FFCCFF",
"cs c #33FFFF",
"m  c #66FFCC",
"m* c #99FFFF",
"m. c #CCFFFF",
"mo c #FF6666",
"m# c #66FF66",
"m+ c #FFFF66",
"m@ c #6666FF",
"mO c #FF66FF",
"m$ c #66FFFF",
"m8 c #A50021",
"m1 c #5F5F5F",
"mu c #777777",
"mg c #868686",
"mc c #969696",
"mm c #CBCBCB",
"ms c #B2B2B2",
"s  c #D7D7D7",
"s* c #DDDDDD",
"s. c #E3E3E3",
"so c #EAEAEA",
"s# c #F1F1F1",
"s+ c #F8F8F8",
"s@ c #FFFBF0",
"sO c #A0A0A4",
"s$ c #808080",
"s8 c #FF0000",
"s1 c #00FF00",
"su c #FFFF00",
"sg c #0000FF",
"sc c #FF00FF",
"sm c #00FFFF",
"ss c None",
"ss818181O1O1O8O8O8O881#sssssssss",
"ss818181818188gogogo++o##sssssss",
"ss81gogo1 81O888*1+++++@+@#sssss",
"ss81gogogo1 O888+++++@+@+@+@#ss#",
"ss81gogo1 1 O8+++++++@m#m#++++#s",
"ss811 1 1 1 O88888++m#m#+@++ssss",
"ss811 1 1 1 O88888++8O+@++8$ssss",
"ss811 1 1 81O#O8O8+++@++O8O8ssss",
"ssO11 818181O#O8++++++O8so+.ssss",
"ssO881818181+.++++#s+$O8so+.ssss",
"ssO881818188+.O#O#O8O8O8so+.ssss",
"ssO8818188O8+.+.+.O8+$+$u1+.ssss",
"ssO88888O8O8+.+.+.+$+$+$uo+.ssss",
"ssO888O8O8O8+.+.+.+$+$+$+$O#ssss",
"ssO8O8O8O8O8+.+.+.+.+.+.O#*1ssss",
"sss@*u*188O8+.*1s#ssssssssssssss"};
END

    my $bitmap = [ map { m/^"(.*)"/ ? ($1) : () } split "\n", $xpm ];

    return Wx::Bitmap->newFromXPM($bitmap);
}

sub get_bitmap_info {
    my $self = shift;

    my $xpm = <<'END';
/* XPM */
static char * shell32222_xpm[] = {
"16 16 256 2",
"   c #000000",
" * c #800000",
" . c #008000",
" o c #808000",
" # c #000080",
" + c #800080",
" @ c #008080",
" O c #C0C0C0",
" $ c #C0DCC0",
" 8 c #A6CAF0",
" 1 c #000033",
" u c #330000",
" g c #330033",
" c c #003333",
" m c #161616",
" s c #1C1C1C",
"*  c #222222",
"** c #292929",
"*. c #555555",
"*o c #4D4D4D",
"*# c #424242",
"*+ c #393939",
"*@ c #FF7C80",
"*O c #FF5050",
"*$ c #D60093",
"*8 c #CCECFF",
"*1 c #EFD6C6",
"*u c #E7E7D6",
"*g c #ADA990",
"*c c #33FF00",
"*m c #660000",
"*s c #990000",
".  c #CC0000",
".* c #003300",
".. c #333300",
".o c #663300",
".# c #993300",
".+ c #CC3300",
".@ c #FF3300",
".O c #006600",
".$ c #336600",
".8 c #666600",
".1 c #996600",
".u c #CC6600",
".g c #FF6600",
".c c #009900",
".m c #339900",
".s c #669900",
"o  c #999900",
"o* c #CC9900",
"o. c #FF9900",
"oo c #00CC00",
"o# c #33CC00",
"o+ c #66CC00",
"o@ c #99CC00",
"oO c #CCCC00",
"o$ c #FFCC00",
"o8 c #66FF00",
"o1 c #99FF00",
"ou c #CCFF00",
"og c #00FF33",
"oc c #3300FF",
"om c #660033",
"os c #990033",
"#  c #CC0033",
"#* c #FF0033",
"#. c #0033FF",
"#o c #333333",
"## c #663333",
"#+ c #993333",
"#@ c #CC3333",
"#O c #FF3333",
"#$ c #006633",
"#8 c #336633",
"#1 c #666633",
"#u c #996633",
"#g c #CC6633",
"#c c #FF6633",
"#m c #009933",
"#s c #339933",
"+  c #669933",
"+* c #999933",
"+. c #CC9933",
"+o c #FF9933",
"+# c #00CC33",
"++ c #33CC33",
"+@ c #66CC33",
"+O c #99CC33",
"+$ c #CCCC33",
"+8 c #FFCC33",
"+1 c #33FF33",
"+u c #66FF33",
"+g c #99FF33",
"+c c #CCFF33",
"+m c #FFFF33",
"+s c #000066",
"@  c #330066",
"@* c #660066",
"@. c #990066",
"@o c #CC0066",
"@# c #FF0066",
"@+ c #003366",
"@@ c #333366",
"@O c #663366",
"@$ c #993366",
"@8 c #CC3366",
"@1 c #FF3366",
"@u c #006666",
"@g c #336666",
"@c c #666666",
"@m c #996666",
"@s c #CC6666",
"O  c #009966",
"O* c #339966",
"O. c #669966",
"Oo c #999966",
"O# c #CC9966",
"O+ c #FF9966",
"O@ c #00CC66",
"OO c #33CC66",
"O$ c #99CC66",
"O8 c #CCCC66",
"O1 c #FFCC66",
"Ou c #00FF66",
"Og c #33FF66",
"Oc c #99FF66",
"Om c #CCFF66",
"Os c #FF00CC",
"$  c #CC00FF",
"$* c #009999",
"$. c #993399",
"$o c #990099",
"$# c #CC0099",
"$+ c #000099",
"$@ c #333399",
"$O c #660099",
"$$ c #CC3399",
"$8 c #FF0099",
"$1 c #006699",
"$u c #336699",
"$g c #663399",
"$c c #996699",
"$m c #CC6699",
"$s c #FF3399",
"8  c #339999",
"8* c #669999",
"8. c #999999",
"8o c #CC9999",
"8# c #FF9999",
"8+ c #00CC99",
"8@ c #33CC99",
"8O c #66CC66",
"8$ c #99CC99",
"88 c #CCCC99",
"81 c #FFCC99",
"8u c #00FF99",
"8g c #33FF99",
"8c c #66CC99",
"8m c #99FF99",
"8s c #CCFF99",
"1  c #FFFF99",
"1* c #0000CC",
"1. c #330099",
"1o c #6600CC",
"1# c #9900CC",
"1+ c #CC00CC",
"1@ c #003399",
"1O c #3333CC",
"1$ c #6633CC",
"18 c #9933CC",
"11 c #CC33CC",
"1u c #FF33CC",
"1g c #0066CC",
"1c c #3366CC",
"1m c #666699",
"1s c #9966CC",
"u  c #CC66CC",
"u* c #FF6699",
"u. c #0099CC",
"uo c #3399CC",
"u# c #6699CC",
"u+ c #9999CC",
"u@ c #CC99CC",
"uO c #FF99CC",
"u$ c #00CCCC",
"u8 c #33CCCC",
"u1 c #66CCCC",
"uu c #99CCCC",
"ug c #CCCCCC",
"uc c #FFCCCC",
"um c #00FFCC",
"us c #33FFCC",
"g  c #66FF99",
"g* c #99FFCC",
"g. c #CCFFCC",
"go c #FFFFCC",
"g# c #3300CC",
"g+ c #6600FF",
"g@ c #9900FF",
"gO c #0033CC",
"g$ c #3333FF",
"g8 c #6633FF",
"g1 c #9933FF",
"gu c #CC33FF",
"gg c #FF33FF",
"gc c #0066FF",
"gm c #3366FF",
"gs c #6666CC",
"c  c #9966FF",
"c* c #CC66FF",
"c. c #FF66CC",
"co c #0099FF",
"c# c #3399FF",
"c+ c #6699FF",
"c@ c #9999FF",
"cO c #CC99FF",
"c$ c #FF99FF",
"c8 c #00CCFF",
"c1 c #33CCFF",
"cu c #66CCFF",
"cg c #99CCFF",
"cc c #CCCCFF",
"cm c #FFCCFF",
"cs c #33FFFF",
"m  c #66FFCC",
"m* c #99FFFF",
"m. c #CCFFFF",
"mo c #FF6666",
"m# c #66FF66",
"m+ c #FFFF66",
"m@ c #6666FF",
"mO c #FF66FF",
"m$ c #66FFFF",
"m8 c #A50021",
"m1 c #5F5F5F",
"mu c #777777",
"mg c #868686",
"mc c #969696",
"mm c #CBCBCB",
"ms c #B2B2B2",
"s  c #D7D7D7",
"s* c #DDDDDD",
"s. c #E3E3E3",
"so c #EAEAEA",
"s# c #F1F1F1",
"s+ c #F8F8F8",
"s@ c #FFFBF0",
"sO c #A0A0A4",
"s$ c #808080",
"s8 c #FF0000",
"s1 c #00FF00",
"su c #FFFF00",
"sg c #0000FF",
"sc c #FF00FF",
"sm c #00FFFF",
"ss c None",
"sssssss+s.s#sssssss+ugs.ssssssss",
"sssssos#ssssug@@mssssssss*ssssss",
"sssosossssss$u+s$@ssssssssuussss",
"sos.sssss+sssscgs+sss#s+ssssmcss",
"ugs#sss#sss u+u+u+sss#*8s+ss 8ug",
"mms#s+s#s+s.$@+s$@ss*8*8*8s#*8s$",
" Os#s#*8*8ssuu #$uss*8*8*8*8cc1m",
" O*8*8*8*8s+u+ #$us+*8*8*8*8 81m",
"uu*8*8*8*8s+uu+s$us+*8*8*8*88*1m",
"s*uu*8*8*8s#u# #1@*8*8*8 8uu@+ug",
"ssuuuu 8*8 81cc+u#u#*8 8uu@@1mss",
"ssssu+8*uu 8*8*8m. 8uu8*@+1mssss",
"sssssss*1m$u$uu+ 88*@+@@msssssss",
"ssssssssssssmm$u*8$u Ossssssssss",
"ssssssssssssss Ou#$us*ssssssssss",
"sssssssssssssssss*1ms*ssssssssss"};
END

    my $bitmap = [ map { m/^"(.*)"/ ? ($1) : () } split "\n", $xpm ];

    return Wx::Bitmap->newFromXPM($bitmap);
}

sub get_bitmap_auto {
    my $self = shift;

    my $xpm = <<'END';
/* XPM */
static char * shell32145_xpm[] = {
"16 16 256 2",
"   c #000000",
" * c #800000",
" . c #008000",
" o c #808000",
" # c #000080",
" + c #800080",
" @ c #008080",
" O c #C0C0C0",
" $ c #C0DCC0",
" 8 c #A6CAF0",
" 1 c #000033",
" u c #330000",
" g c #330033",
" c c #003333",
" m c #161616",
" s c #1C1C1C",
"*  c #222222",
"** c #292929",
"*. c #555555",
"*o c #4D4D4D",
"*# c #424242",
"*+ c #393939",
"*@ c #FF7C80",
"*O c #FF5050",
"*$ c #D60093",
"*8 c #CCECFF",
"*1 c #EFD6C6",
"*u c #E7E7D6",
"*g c #ADA990",
"*c c #33FF00",
"*m c #660000",
"*s c #990000",
".  c #CC0000",
".* c #003300",
".. c #333300",
".o c #663300",
".# c #993300",
".+ c #CC3300",
".@ c #FF3300",
".O c #006600",
".$ c #336600",
".8 c #666600",
".1 c #996600",
".u c #CC6600",
".g c #FF6600",
".c c #009900",
".m c #339900",
".s c #669900",
"o  c #999900",
"o* c #CC9900",
"o. c #FF9900",
"oo c #00CC00",
"o# c #33CC00",
"o+ c #66CC00",
"o@ c #99CC00",
"oO c #CCCC00",
"o$ c #FFCC00",
"o8 c #66FF00",
"o1 c #99FF00",
"ou c #CCFF00",
"og c #00FF33",
"oc c #3300FF",
"om c #660033",
"os c #990033",
"#  c #CC0033",
"#* c #FF0033",
"#. c #0033FF",
"#o c #333333",
"## c #663333",
"#+ c #993333",
"#@ c #CC3333",
"#O c #FF3333",
"#$ c #006633",
"#8 c #336633",
"#1 c #666633",
"#u c #996633",
"#g c #CC6633",
"#c c #FF6633",
"#m c #009933",
"#s c #339933",
"+  c #669933",
"+* c #999933",
"+. c #CC9933",
"+o c #FF9933",
"+# c #00CC33",
"++ c #33CC33",
"+@ c #66CC33",
"+O c #99CC33",
"+$ c #CCCC33",
"+8 c #FFCC33",
"+1 c #33FF33",
"+u c #66FF33",
"+g c #99FF33",
"+c c #CCFF33",
"+m c #FFFF33",
"+s c #000066",
"@  c #330066",
"@* c #660066",
"@. c #990066",
"@o c #CC0066",
"@# c #FF0066",
"@+ c #003366",
"@@ c #333366",
"@O c #663366",
"@$ c #993366",
"@8 c #CC3366",
"@1 c #FF3366",
"@u c #006666",
"@g c #336666",
"@c c #666666",
"@m c #996666",
"@s c #CC6666",
"O  c #009966",
"O* c #339966",
"O. c #669966",
"Oo c #999966",
"O# c #CC9966",
"O+ c #FF9966",
"O@ c #00CC66",
"OO c #33CC66",
"O$ c #99CC66",
"O8 c #CCCC66",
"O1 c #FFCC66",
"Ou c #00FF66",
"Og c #33FF66",
"Oc c #99FF66",
"Om c #CCFF66",
"Os c #FF00CC",
"$  c #CC00FF",
"$* c #009999",
"$. c #993399",
"$o c #990099",
"$# c #CC0099",
"$+ c #000099",
"$@ c #333399",
"$O c #660099",
"$$ c #CC3399",
"$8 c #FF0099",
"$1 c #006699",
"$u c #336699",
"$g c #663399",
"$c c #996699",
"$m c #CC6699",
"$s c #FF3399",
"8  c #339999",
"8* c #669999",
"8. c #999999",
"8o c #CC9999",
"8# c #FF9999",
"8+ c #00CC99",
"8@ c #33CC99",
"8O c #66CC66",
"8$ c #99CC99",
"88 c #CCCC99",
"81 c #FFCC99",
"8u c #00FF99",
"8g c #33FF99",
"8c c #66CC99",
"8m c #99FF99",
"8s c #CCFF99",
"1  c #FFFF99",
"1* c #0000CC",
"1. c #330099",
"1o c #6600CC",
"1# c #9900CC",
"1+ c #CC00CC",
"1@ c #003399",
"1O c #3333CC",
"1$ c #6633CC",
"18 c #9933CC",
"11 c #CC33CC",
"1u c #FF33CC",
"1g c #0066CC",
"1c c #3366CC",
"1m c #666699",
"1s c #9966CC",
"u  c #CC66CC",
"u* c #FF6699",
"u. c #0099CC",
"uo c #3399CC",
"u# c #6699CC",
"u+ c #9999CC",
"u@ c #CC99CC",
"uO c #FF99CC",
"u$ c #00CCCC",
"u8 c #33CCCC",
"u1 c #66CCCC",
"uu c #99CCCC",
"ug c #CCCCCC",
"uc c #FFCCCC",
"um c #00FFCC",
"us c #33FFCC",
"g  c #66FF99",
"g* c #99FFCC",
"g. c #CCFFCC",
"go c #FFFFCC",
"g# c #3300CC",
"g+ c #6600FF",
"g@ c #9900FF",
"gO c #0033CC",
"g$ c #3333FF",
"g8 c #6633FF",
"g1 c #9933FF",
"gu c #CC33FF",
"gg c #FF33FF",
"gc c #0066FF",
"gm c #3366FF",
"gs c #6666CC",
"c  c #9966FF",
"c* c #CC66FF",
"c. c #FF66CC",
"co c #0099FF",
"c# c #3399FF",
"c+ c #6699FF",
"c@ c #9999FF",
"cO c #CC99FF",
"c$ c #FF99FF",
"c8 c #00CCFF",
"c1 c #33CCFF",
"cu c #66CCFF",
"cg c #99CCFF",
"cc c #CCCCFF",
"cm c #FFCCFF",
"cs c #33FFFF",
"m  c #66FFCC",
"m* c #99FFFF",
"m. c #CCFFFF",
"mo c #FF6666",
"m# c #66FF66",
"m+ c #FFFF66",
"m@ c #6666FF",
"mO c #FF66FF",
"m$ c #66FFFF",
"m8 c #A50021",
"m1 c #5F5F5F",
"mu c #777777",
"mg c #868686",
"mc c #969696",
"mm c #CBCBCB",
"ms c #B2B2B2",
"s  c #D7D7D7",
"s* c #DDDDDD",
"s. c #E3E3E3",
"so c #EAEAEA",
"s# c #F1F1F1",
"s+ c #F8F8F8",
"s@ c #FFFBF0",
"sO c #A0A0A4",
"s$ c #808080",
"s8 c #FF0000",
"s1 c #00FF00",
"su c #FFFF00",
"sg c #0000FF",
"sc c #FF00FF",
"sm c #00FFFF",
"ss c None",
"ssssssssssssssssssssssss*1O#8#*1",
"sssssssssssssssssssssss#@sO+O+@s",
"ssssssssssssssssssssss81O+O+O+@s",
"ssssssssssssssssssss81O#O+O+@s*1",
"ssssssssssssssssss*u@sO+O+O#81ss",
"ssssssssssssssssss8#O+O+O+@ss+ss",
"ssssssssssssssss81@sO+O+@s*1ssss",
"sss#*1ssssssss*u@sO+O+@s81ssssss",
"81@sO#8#s#ssss8#O+O+#c@sssssssss",
"@sO+O+O+8#*1*1@sO++o@s*1ssssssss",
"81O+O+O+O+@s@s+o#c#g81ssssssssss",
"s+8#O#O+O+O+@s#c#c@ss@ssssssssss",
"ssss81@sO++o#c#c#g*1ssssssssssss",
"ssssss81@s#c#c#gO#ssssssssssssss",
"ssssssss81#g#c#g*1ssssssssssssss",
"ssssssssss81@s81ssssssssssssssss"};
END

    my $bitmap = [ map { m/^"(.*)"/ ? ($1) : () } split "\n", $xpm ];

    return Wx::Bitmap->newFromXPM($bitmap);
}

1;

