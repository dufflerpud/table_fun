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

$main::FUNCS{csv} =
$main::FUNCS{csv} =	# Eliminate "only used once" errors.
    {
    pretty	=>"csv",
    mime	=>"text/plain",
    input	=>\&input_text,
    output	=>\&output_csv,
    #recognizer	=>".*,.*,.*",
    };

#########################################################################
#	Just like output text only use a comma as the delimeter.	#
#########################################################################
sub output_csv
    {
    $main::ARGS{od} = ",";
    $main::ARGS{oj} = 0;
    &output_text( @_ );
    }

1;
