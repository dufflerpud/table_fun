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

$main::FUNCS{po} =
$main::FUNCS{perl} =	# Eliminate "only used once" errors.
    {
    pretty	=>"perl",
    mime	=>"text/plain",
    input	=>\&input_perl,
    output	=>\&output_perl,
    recognizer	=>"{.*=>.*}"
    };

#########################################################################
#	Parse a perl file (more of a toy than actually useful)		#
#########################################################################
sub input_perl
    {
    my( $fl ) = @_;

    my $VAR1;
    $fl = "\$VAR1 = $fl" if( $fl !~ /^\$VAR1/ );
    eval( $fl );

    return &table_in_memory( $VAR1 );
    }

#########################################################################
#	Fix quoting of argument.					#
#########################################################################
sub perl_requote
    {
    my( $arg ) = @_;
    #$arg =~ s/'/\\\\'/g;
    #$arg =~ s/"/\\\\"/g;
    return $arg;
    }

#########################################################################
#	Print code suitable for inclusion in perl.			#
#									#
#	No, this cannot be done with Data::Dumper since our structure	#
#	is organized in an array and the fields aren't embedded in it.	#
#									#
#	However, it made me look at Data::Dumper and that's cool!	#
#########################################################################
sub output_perl
    {
#    my( $input_data ) = @_;
#
#    my @l;
#    foreach my $p ( @{$input_data->{records}} )
#	{
#	push( @l,
#	    "{".  join(",",
#	        map {
#		    '"'.&orempty(${_}->{name}).'"=>"' .
#		    ( defined($_->{ind})
#			? &perl_requote(&orempty($p->[$_->{ind}])) : "" ). '"'
#		    } @{$input_data->{print_order}}
#	    ) ."}" );
#	}
#    print OUT "[ ", join(",\n  ",@l), " ]\n";
    print OUT Dumper( $input_data );
    }

1;
