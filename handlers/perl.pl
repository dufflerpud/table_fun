#!/usr/bin/perl -w
#
#indx#	po.pl - Driver for tables in po files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Driver for tables in po files
########################################################################
#
#indx#	perl.pl - Driver for tables in perl files
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Driver for tables in perl files
########################################################################
use strict;

use Data::Dumper;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}		= "perl";
$driverp->{mime}		= "text/plain";
$driverp->{recognizer}	= "{.*=>.*}";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a perl file (more of a toy than actually useful)		#
#########################################################################
$driverp->{input} = sub
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
$driverp->{requote} = sub
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
$driverp->{output} = sub
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
#			? &{$driverp->{requote}}(&main::orempty($p->[$_->{ind}])) : "" ). '"'
#		    } @{$input_data->{print_order}}
#	    ) ."}" );
#	}
#    push @ret, "[ ", join(",\n  ",@l), " ]\n";
    return Dumper( $input_data );
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
