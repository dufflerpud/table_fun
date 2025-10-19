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
$DRIVER->{pretty}	= "csv";
$DRIVER->{mime}		= "text/plain";
#$DRIVER->{recognizer}	= ".*,.*,.*",

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );
#&device_debug("csv.pl",__LINE__,"start eval");

#########################################################################
#	Just like input for text driver.				#
#########################################################################
$DRIVER->{input} = sub
    {
    return &{ $main::FUNCS{text}{input} }( @_ );
    };

#########################################################################
#	Just like output text only use a comma as the delimeter.	#
#########################################################################
$DRIVER->{output} = sub
    {
    $main::ARGS{odelimeter} = ",";
    $main::ARGS{ojustify} = 0;
    return &{ $main::FUNCS{text}{output} }( @_ );
    };

#&device_debug("csv.pl",__LINE__,"end eval");
1;
