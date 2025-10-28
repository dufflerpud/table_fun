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
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);

$driverp->{pretty}		= "fields";
$driverp->{mime}		= "text/plain";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Output each field with a list of found values.			#
#########################################################################
$driverp->{output} = sub
    {
    my( $input_data ) = @_;
    my %values;
    my @ret;

#    push @ret, "Type of $main::ARGS{ifile}",
#	" is $main::ARGS{itype} based on the $main::reason.\n";
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

#&device_debug(__FILE__,__LINE__,"end eval");
1;
