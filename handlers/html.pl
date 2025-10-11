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

$main::FUNCS{html} = $main::FUNCS{htm} =
    {
    pretty	=>"HTML",
    mime	=>"text/html",
    input	=>\&input_html,
    output	=>\&output_html,
    recognizer	=>"<table.*?>.*?<\/table>",
    recopri	=>3
    };

#########################################################################
#	Parse an html table						#
#########################################################################
sub input_html
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
    }

#########################################################################
#	Output html table						#
#########################################################################
sub output_html
    {
    my( $input_data ) = @_;

    &calculate_field_widths( $input_data );

    print OUT "<table cellpadding=4 border=1 style='border-collapse:collapse'>\n";
    print OUT "<tr>";
    foreach my $f ( @{$input_data->{print_order}} )
        {
	print OUT "<th ", $f->{tdargs}, ">", $f->{name}, "</th>";
	}
    foreach my $rp ( @{$input_data->{records}} )
        {
	print OUT "</tr>\n<tr>";
	if( scalar(@{$rp}) == 1 )
	    {
	    print OUT "<th align=left colspan=",scalar(@{$input_data->{print_order}}),">", ${$rp}[0], "</th>";
	    }
	else
	    {
	    foreach my $f ( @{$input_data->{print_order}} )
		{
		my $cp = $rp->[ $f->{ind} ];
		$cp = "" if( ! defined($cp) );
		print OUT "<td valign=top ", $f->{tdargs}, ">", $cp, "</td>";
		}
	    }
	}
    print OUT "</tr></table>\n";
    }

1;
