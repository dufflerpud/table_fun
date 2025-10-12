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
$DRIVER->{pretty}	= "fields";
$DRIVER->{mime}		= "text/plain";

#########################################################################
#	Output each field with a list of found values.			#
#########################################################################
$DRIVER->{output} = sub
    {
    my( $input_data ) = @_;
    my %values;
    my @ret;

#    push @ret, "Type of $main::ARGS{if}",
#	" is $main::ARGS{it} based on the $main::reason.\n";
    $main::reason=$main::reason;	# Eliminate "only used once" errors.

    foreach my $rp ( @{$input_data->{records}} )
	{
	foreach my $f ( @{$input_data->{print_order}} )
	    {
	    my $cp = $rp->[ $f->{ind} ];
	    push( @{$values{$f}{$cp}}, $rp )
		if( defined($cp) && $cp =~ /[^\s]/ );
	    }
	}

    foreach my $f ( @{$input_data->{print_order}} )
        {
	push @ret, $f->{name}, ":\n",
	    ( map { "\t".$_."\n" } sort keys %{$values{$f}} );
	}
    return join("",@ret);
    };

1;
