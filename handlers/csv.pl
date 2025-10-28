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

$cpi_drivers::this->{pretty}		= "csv";
$cpi_drivers::this->{mime}		= "text/plain";
#$cpi_drivers::this->{recognizer}	= ".*,.*,.*",

#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Just like input for text driver.				#
#########################################################################
$cpi_drivers::this->{input} = sub
    {
    return &{ $main::FUNCS{text}{input} }( @_ );
    };

#########################################################################
#	Just like output text only use a comma as the delimeter.	#
#########################################################################
$cpi_drivers::this->{output} = sub
    {
    $main::ARGS{odelimeter} = ",";
    $main::ARGS{ojustify} = 0;
    return &{ $main::FUNCS{text}{output} }( @_ );
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
