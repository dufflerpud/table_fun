#!/usr/bin/perl -w
#
#indx#	lpf.pl - Driver for tables in lpf files
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
#doc#	Driver for tables in lpf files
########################################################################
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}		= "lpf - one line per field";
$driverp->{mime}		= "text/plain";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Recognize a lpf file.						#
#########################################################################
$driverp->{recognizer} = sub
    {
    return 0 if( $_[0]=~/^Subject:/ms && $_[0]=~/^From:/ && $_[0]=~/^To:/ );
    return
        ( scalar(grep(/:/,split(/^([^:\n]*:[^:\n]*)$/ms,$_[0])))>2 ||
	  scalar(grep(/=/,split(/^([^=\n]*=[^=\n]*)$/ms,$_[0])))>2 );
    };

#########################################################################
#	Parse a lpf file						#
#########################################################################
$driverp->{input} = sub
    {
    my( $fl ) = @_;
    my %output_data;

    foreach my $rec ( split(/\n[^\w]*\n/ms,$fl) )
        {
	my @cells;
	#print STDERR "Processing {$rec}\n";
	foreach my $celldata ( split(/\n/ms,$rec) )
	    {
	    if( $celldata =~ /^\s*(\w+)\s*[:=]\s*"(.*?)"/
	     || $celldata =~ /^\s*(\w+)\s*[:=]\s*'(.*?)'/
	     || $celldata =~ /^\s*(\w+)\s*[:=]\s*(.*?)$/ )
		{
	        my( $fname, $fval ) = ( $1, $2 );
		$cells[&main::ind_of_field($fname,\%output_data)] = $fval;
		}
	    }
	push( @{$output_data{records}}, \@cells );
	}
    return \%output_data;
    };

#########################################################################
#	Output one line per field					#
#########################################################################
$driverp->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    &main::calculate_field_widths( $input_data );

    my $field_name_length = -1;
    foreach my $f ( @{$input_data->{print_order}} )
        {
	my $l = length( $f->{name} );
	$field_name_length = $l if( $l > $field_name_length );
	}
    $field_name_length+=2;

    foreach my $rp ( @{$input_data->{records}} )
	{
	my @records;
	foreach my $f ( @{$input_data->{print_order}} )
	    {
	    my $cp = $rp->[ $f->{ind} ];
	    if( defined($cp) && $cp =~ /[^\s]/ )
		{
		my $flen = $f->{width};
		push( @records, sprintf("%-${field_name_length}s%s\n",$f->{name}.":",$cp) );
		}
	    }
	push( @ret, join("",@records) );
	}
    return join("\n",@ret);
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
