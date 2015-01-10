#!/bin/perl
use strict;
use warnings;
use autodie;
use utf8;
use Encode qw(decode);
no locale;

binmode( STDOUT, ":utf8" );

my $general=0; #Si és 1, versió "general" del corrector
if ( grep( /^-catalan$/, @ARGV ) ) {
  $general=1;
}


my $modelsdir = $ARGV[0]."/";
my @files = glob($modelsdir."*.model");
@files = sort (@files);
my $modelscount = 0;
my $afffile = $ARGV[1];
open( my $ofh, ">:encoding(UTF-8)", $afffile );
foreach my $file (@files) {
    next if ($file !~ /\.model$/);
    $modelscount++;
    my $sufix= sprintf ("%02X", $modelscount);

    open( my $modelfh,  "<:encoding(UTF-8)", $file );
    my $infinitiu=decode("utf8",$file);
    $infinitiu =~ s/$modelsdir(.*)\.model/$1/;
    my @lines = <$modelfh>;
    my $numlines = @lines;
    close ($modelfh);
    print $ofh "\n# Model de conjugació: $infinitiu\n";
    print $ofh "SFX $sufix Y $numlines\n";
    open( $modelfh,  "<:encoding(UTF-8)", $file );
    LINE: while (my $modelline = <$modelfh>) {
	if ($modelline =~ /^(.+) (.+) (.+) (.+) #.*$/) {
	    my $trau = $1;
	    my $afegeix = $2;
	    my $condiciofinal = $3;
	    my $postag = $4;
	    my $afixos="";
	    my $forma=$infinitiu;
	    if ($forma =~ /^(.*)$trau$/) {
		$forma = $1;
	    }
	    else {
		print $ofh "!!!!ERROR en $forma\n";
	    }
	    if ($afegeix !~ /^0$/) {
		$forma .= $afegeix;
	    }

	    #Elimina accentuació valenciana del diccionari general
	    if ($general) {
		next LINE if ($postag =~ /^V.P.*$/ && $forma =~ /és$/);
		next LINE if ($postag =~ /^V.N.*/ && $forma =~ /é(ixer|nyer|ncer)$/ && $forma !~ /(cr|acr|decr|n|p|recr|ren|sobrecr|sobren)éixer$/);
	    }

	    if ($postag =~ /^V.N.*$/) {
		if ($forma =~ /[^e]$/) {
		    $afixos="_C_Y"; #infinitiu acabat en consonant
		} else {
		    $afixos="_D_Y"; #infinitiu acabat en vocal
		}
	    } elsif ($postag =~ /^V.G.*$/) {
		$afixos="_C"; #gerundi
	    } elsif ($postag =~ /^V.P..SM.$/) {
		$afixos="_V_Y"; #participi MS
	    } elsif ($postag =~ /^V.P..SF.$/) {
		$afixos="_Y"; #participi FS **** Falta afegir l'apostrofació l' (_V) en la forma evitant les excepcions. 
	    } elsif ($postag =~ /^V.P..P..$/) {
		$afixos="_Y"; #participi P
	    } elsif ($postag =~ /^V.M.*$/) {
		if ($forma =~ /[aeiï]$/) {
		    $afixos="_D"; #imperatiu acabat en vocal: a, e, i, ï 
		} else {
		    $afixos="_C"; #imperatiu acabat en consonat o u
		}		
	    }
	    else {
		$afixos="_Z";
	    }
	    print $ofh "SFX $sufix $trau $afegeix/$afixos $condiciofinal\n";
	}
    }
    close ($modelfh);

}

close ($ofh);
