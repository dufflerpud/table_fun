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

my $DRIVER={};		# Just for debugging
$DRIVER->{pretty}	= "HTML";
$DRIVER->{mime}		= "text/html";
$DRIVER->{recognizer}	= "<table.*?>.*?<\/table>";
$DRIVER->{recopri}	= 3;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );
#&device_debug("html.pl",__LINE__,"start eval");

#########################################################################
#	Parse an html table						#
#########################################################################
$DRIVER->{input} = sub
    {
    my( $fl ) = @_;
    $fl = $2 if( $fl =~ /.*(<table.*?)>(.*?)<\/table>/ms );
    #print "input_html{ $fl }\n";
    my %output_data;
    foreach my $ln ( split(/<tr>/ms,$fl) )
        {
	my @splitrec;
	my $isin;
	foreach my $celldata ( split(/(<td|<th)/,$ln) )
	    {
	    if( $celldata eq "<td" || $celldata eq "<th" )
	        { $isin = $celldata; }
	    elsif( $isin )
	        {
		$isin =~ s/<//;
		$celldata =~ s+^[^>]*>++;
		$celldata =~ s+</th>.*++ms;
		$celldata =~ s+</td>.*++ms;
		$celldata =~ s+<.*?>++gms;
		$celldata = $1 if( $celldata =~ /^\s*?(.*?)\s*?$/ );
		push( @splitrec, $celldata );
		}
	    }
	if( scalar(@splitrec) == 1 || $output_data{byindex} )
	    { push( @{$output_data{records}}, \@splitrec ); }
	else
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
#	Output html table						#
#########################################################################
$DRIVER->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    &main::calculate_field_widths( $input_data );

    push @ret, "<table cellpadding=4 border=1 style='border-collapse:collapse'>\n";
    push @ret, "<tr>";
    foreach my $f ( @{$input_data->{print_order}} )
        {
	push @ret, "<th ", $f->{tdargs}, ">", $f->{name}, "</th>";
	}
    foreach my $rp ( @{$input_data->{records}} )
        {
	push @ret, "</tr>\n<tr>";
	if( scalar(@{$rp}) == 1 )
	    {
	    push @ret, "<th align=left colspan=",scalar(@{$input_data->{print_order}}),">", ${$rp}[0], "</th>";
	    }
	else
	    {
	    foreach my $f ( @{$input_data->{print_order}} )
		{
		my $cp = $rp->[ $f->{ind} ];
		$cp = "" if( ! defined($cp) );
		push @ret, "<td valign=top ", $f->{tdargs}, ">", $cp, "</td>";
		}
	    }
	}
    push @ret, "</tr></table>\n";
    return join("",@ret);
    };

#&device_debug("html.pl",__LINE__,"end eval");
1;
