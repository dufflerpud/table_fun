#!/usr/bin/perl -w
#
#indx#	mwt.pl - Driver for tables in mwt files
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
#doc#	Driver for tables in mwt files
########################################################################
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}		= "mwt - Media Wiki Table";
$driverp->{mime}		= "text/plain";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a media wiki table					#
#########################################################################
$driverp->{input} = sub
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
$driverp->{output} = sub
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

#&device_debug(__FILE__,__LINE__,"end eval");
1;
