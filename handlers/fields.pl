#!/usr/bin/perl -w
#
#indx#	fields.pl - Driver for tables in fields files
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
#doc#	Driver for tables in fields files
########################################################################
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
