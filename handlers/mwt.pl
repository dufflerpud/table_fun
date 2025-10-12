#!/usr/bin/perl -w
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
use strict;

my $DRIVER||={};	# Just for debugging
$DRIVER->{pretty}	= "mwt - Media Wiki Table",
$DRIVER->{mime}		= "text/plain",

#########################################################################
#	Parse a media wiki table					#
#########################################################################
$DRIVER->{input} = sub
    {
    my( $fl ) = @_;
    $fl = $2 if( $fl =~ /.*({\|[^!\|]*)(.*?)\|}/ms );

    my %output_data;
    foreach my $rc ( split(/\|-/ms,$fl) )
        {
	my @splitrec;
	foreach my $rcp ( split(/\n/ms,$rc) )
	    {
	    my $isin;
	    my $args;
	    foreach my $pc ( split(/\|/,$rcp) )
	        {
		if( ! defined($isin) )
		    {
		    if( $pc =~ /^!(.*)/ )
			{ $isin = "th"; $args=$1; }
		    else
		        { $isin = "td"; $args=$pc; }
		    }
		elsif( $pc =~ /^\s*(.*?)\s*$/ )
		    {
		    push( @splitrec, $1 );
		    $isin = undef;
		    }
		}
	    }
	if( scalar(@splitrec) == 1 || $output_data{byindex} )
	    {
	    push( @{$output_data{records}}, \@splitrec )
	        if( scalar(@splitrec) > 0 );
	    }
	elsif( scalar(@splitrec) > 1 )
	    {
	    my $fldnum = 0;
	    foreach my $celldata ( @splitrec )
		{
		my %fd = ( name=>$celldata, ind=>$fldnum );
		$output_data{byname}{$celldata} = \%fd;
		push( @{ $output_data{byindex} }, \%fd );
		$fldnum++;
		}
	    }
	}
    return \%output_data;
    };

#########################################################################
#	Output a media wiki table					#
#########################################################################
$DRIVER->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    &main::calculate_field_widths( $input_data );

    push @ret, "{| border=1 cellspacing=0\n";
    foreach my $f ( @{$input_data->{print_order}} )
        {
	push @ret, "!", $f->{tdargs}, "|", $f->{name}, "\n";
	}
    push @ret, "|-\n";
    foreach my $rp ( @{$input_data->{records}} )
        {
	if( scalar(@{$rp}) == 1 )
	    {
	    push @ret, "| colspan=",scalar(@{$input_data->{print_order}}),"|", ${$rp}[0];
	    }
	else
	    {
	    foreach my $f ( @{$input_data->{print_order}} )
		{
		my $cp = $rp->[ $f->{ind} ];
		$cp = "" if( ! defined($cp) );
		push @ret, "|", $f->{tdargs}, "|", $cp, "\n";
		}
	    }
	push @ret, "|-\n";
	}
    push @ret, "|}\n";
    return join("",@ret);
    };

1;
