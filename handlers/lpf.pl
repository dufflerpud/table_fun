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

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );

$cpi_drivers::this->{pretty}		= "lpf - one line per field";
$cpi_drivers::this->{mime}		= "text/plain";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Recognize a lpf file.						#
#########################################################################
$cpi_drivers::this->{recognizer} = sub
    {
    return 0 if( $_[0]=~/^Subject:/ms && $_[0]=~/^From:/ && $_[0]=~/^To:/ );
    return
        ( scalar(grep(/:/,split(/^([^:\n]*:[^:\n]*)$/ms,$_[0])))>2 ||
	  scalar(grep(/=/,split(/^([^=\n]*=[^=\n]*)$/ms,$_[0])))>2 );
    };

#########################################################################
#	Parse a lpf file						#
#########################################################################
$cpi_drivers::this->{input} = sub
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
$cpi_drivers::this->{output} = sub
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
