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

use Data::Dumper;

my $DRIVER={};		# Just for debugging
$DRIVER->{pretty}	= "perl";
$DRIVER->{mime}		= "text/plain";
$DRIVER->{recognizer}	= "{.*=>.*}";
use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );
#&device_debug("perl.pl",__LINE__,"start eval");

#########################################################################
#	Parse a perl file (more of a toy than actually useful)		#
#########################################################################
$DRIVER->{input} = sub
    {
    my( $fl ) = @_;

    my $VAR1;
    $fl = "\$VAR1 = $fl" if( $fl !~ /^\$VAR1/ );
    eval( $fl );

    return &main::table_in_memory( $VAR1 );
    };

#########################################################################
#	Fix quoting of argument.					#
#########################################################################
$DRIVER->{requote} = sub
    {
    my( $arg ) = @_;
    #$arg =~ s/'/\\\\'/g;
    #$arg =~ s/"/\\\\"/g;
    return $arg;
    };

#########################################################################
#	Print code suitable for inclusion in perl.			#
#									#
#	No, this cannot be done with Data::Dumper since our structure	#
#	is organized in an array and the fields aren't embedded in it.	#
#									#
#	However, it made me look at Data::Dumper and that's cool!	#
#########################################################################
$DRIVER->{output} = sub
    {
    my( $input_data ) = @_;

#    my @l;
#    foreach my $p ( @{$input_data->{records}} )
#	{
#	push( @l,
#	    "{".  join(",",
#	        map {
#		    '"'.&main::orempty(${_}->{name}).'"=>"' .
#		    ( defined($_->{ind})
#			? &{$DRIVER->{requote}}(&main::orempty($p->[$_->{ind}])) : "" ). '"'
#		    } @{$input_data->{print_order}}
#	    ) ."}" );
#	}
#    push @ret, "[ ", join(",\n  ",@l), " ]\n";
    return Dumper( $input_data );
    };

#&device_debug("perl.pl",__LINE__,"end eval");
1;
