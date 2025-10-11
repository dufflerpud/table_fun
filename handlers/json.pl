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

$main::FUNCS{json} =
$main::FUNCS{json} =	# Eliminate "only used once" errors.
    {
    pretty	=>"json",
    mime	=>"text/plain",
    input	=>\&input_json,
    output	=>\&output_json,
    #recognizer	=>"{[A-Za-z].*:.*}"
    };

#########################################################################
#	Parse a json file (more of a toy than actually useful)		#
#########################################################################
sub input_json
    {
    my( $fl ) = @_;

    return &table_in_memory( decode_json( $fl ) );
    }

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
sub output_json
    {
    my( $input_data ) = @_;

    my @l;
    foreach my $p ( @{$input_data->{records}} )
	{
	push( @l,
	    "{".  join(",",
	        map { '"'.&orempty(${_}->{name}).'":"' .
		    &json_requote(
		        ( defined($_->{ind})
			? &orempty($p->[$_->{ind}]):"") ). '"' }
			    @{$input_data->{print_order}}
	    ) ."}" );
	}
    print OUT "[ ", join(",\n  ",@l), " ]\n";
    }

1;
