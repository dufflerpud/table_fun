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
$DRIVER->{pretty}	= "lpf - one line per field";
$DRIVER->{mime}		= "text/plain";

#########################################################################
#	Recognize a lpf file.						#
#########################################################################
$DRIVER->{recognizer} = sub
    {
    return 0 if( $_[0]=~/^Subject:/ms && $_[0]=~/^From:/ && $_[0]=~/^To:/ );
    return
        ( scalar(grep(/:/,split(/^([^:\n]*:[^:\n]*)$/ms,$_[0])))>2 ||
	  scalar(grep(/=/,split(/^([^=\n]*=[^=\n]*)$/ms,$_[0])))>2 );
    };

#########################################################################
#	Parse a lpf file						#
#########################################################################
$DRIVER->{input} = sub
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
$DRIVER->{output} = sub
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
	foreach my $f ( @{$input_data->{print_order}} )
	    {
	    my $cp = $rp->[ $f->{ind} ];
	    if( defined($cp) && $cp =~ /[^\s]/ )
		{
		my $flen = $f->{width};
		push( @ret, sprintf("%-${field_name_length}s%s\n",$f->{name}.":",$cp) );
		}
	    }
	}
    return join("\n",@ret);
    };

1;
