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

use JSON;
use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );

$cpi_drivers::this->{pretty}		= "json";
$cpi_drivers::this->{mime}		= "text/plain";
#$cpi_drivers::this->{recognizer}	= "{[A-Za-z].*:.*}";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a json file (more of a toy than actually useful)		#
#########################################################################
$cpi_drivers::this->{input} = sub
    {
    my( $fl ) = @_;

    return &main::table_in_memory( decode_json( $fl ) );
    };

#########################################################################
#	Fix quoting of argument.					#
#########################################################################
sub json_requote
    {
    my( $arg ) = @_;
    $arg =~ s/'/\\\\'/g;
    $arg =~ s/"/\\\\"/g;
    return $arg;
    }

#########################################################################
#	Print code suitable for inclusion in javascript.		#
#########################################################################
$cpi_drivers::this->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    foreach my $p ( @{$input_data->{records}} )
	{
	push( @ret,
	    "{".  join(",",
	        map { '"'.&main::orempty(${_}->{name}).'":"' .
		    &json_requote(
		        ( defined($_->{ind})
			? &main::orempty($p->[$_->{ind}]):"") ). '"' }
			    @{$input_data->{print_order}}
	    ) ."}" );
	}
    return join("", "[ ", join(",\n  ",@ret), " ]\n");
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
