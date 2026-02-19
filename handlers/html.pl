#!/usr/bin/perl -w
#
#indx#	html.pl - Driver for tables in html files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Driver for tables in html files
########################################################################
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}		= "HTML";
$driverp->{mime}		= "text/html";
$driverp->{recognizer}	= "<table.*?>.*?<\/table>";
$driverp->{recopri}		= 3;
#&device_debug("html.pl",__LINE__,"start eval");

#########################################################################
#	Parse an html table						#
#########################################################################
$driverp->{input} = sub
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
$driverp->{output} = sub
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
