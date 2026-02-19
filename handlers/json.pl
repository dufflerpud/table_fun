#!/usr/bin/perl -w
#
#indx#	json.pl - Driver for tables in json files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#doc#	Driver for tables in json files
########################################################################
use strict;

use JSON;
use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}		= "json";
$driverp->{mime}		= "text/plain";
#$driverp->{recognizer}	= "{[A-Za-z].*:.*}";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a json file (more of a toy than actually useful)		#
#########################################################################
$driverp->{input} = sub
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
$driverp->{output} = sub
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
