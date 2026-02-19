#!/usr/bin/perl -w
#
#indx#	txt.pl - Driver for tables in txt files
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
#doc#	Driver for tables in txt files
########################################################################
#
#indx#	text.pl - Driver for tables in text files
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Driver for tables in text files
########################################################################
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);
$driverp->{pretty}	= "text - Text file";
$driverp->{mime}	= "text/plain";

my $COMMON_SEPS = "\t,|!:+";
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a text file						#
#########################################################################
$driverp->{input} = sub
    {
    my( $fl ) = @_;
    if( ! defined( $main::ARGS{idelimeter} ) || $main::ARGS{idelimeter} eq "" )
        {
	foreach my $try ( split(//,$COMMON_SEPS) )
	    {
	    my $sep = '\\' . $try;
	    if( $fl =~ /$sep.*$sep/ )
	        { $main::ARGS{idelimeter}=$try; last; }
	    }
	$main::ARGS{idelimeter} ||= "\t";
	}
    my $sep = '\\' . $main::ARGS{idelimeter};

    my %output_data;
    foreach my $rec ( split(/\n/ms,$fl) )
        {
	my @splitline;
	my @parts;
	my $inquote;
	foreach my $piece ( split(/(")/,$rec) )
	    {
	    my $toadd = $piece;
	    if( $piece eq '"' )
		{ $inquote = ! $inquote; }
	    elsif( ! $inquote )
		{ $toadd =~ s/$sep/\377/g; }
	    push( @parts, $toadd );
	    }
	foreach my $celldata ( split(/\377/,join("",@parts)) )
	    {
	    $celldata = $1 if( $celldata =~ /^\s*?(.*?)\s*?$/ );
	    push( @splitline, $celldata ); 
	    }
	if( scalar(@splitline) == 1 )
	    { push( @{$output_data{records}}, @splitline ); }
	elsif( $output_data{byindex} )
	    { push( @{$output_data{records}}, \@splitline ); }
	else
	    {
	    my $fldnum = 0;
	    foreach my $celldata ( @splitline )
		{
		my %fd = ( name=>$celldata, ind=>$fldnum );
		$output_data{byname}{$celldata} = \%fd;
		push( @{ $output_data{byindex} }, \%fd );
		$fldnum++;
		}
	    }
	}
    return \%output_data;
    };

#########################################################################
#	Output text							#
#########################################################################
$driverp->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    &main::calculate_field_widths( $input_data );

    $_ = join( $main::ARGS{odelimeter},
	map{ sprintf($_->{sprintf},$_->{name}) } @{$input_data->{print_order}} );
    s/\s*$//g;
    push @ret, $_,"\n";

    foreach my $rp ( @{$input_data->{records}} )
	{
	my @ln;
	foreach my $f ( @{$input_data->{print_order}} )
	    {
	    my $cp = $rp->[ $f->{ind} ];
	    $cp = "" if( ! defined($cp) );
	    push( @ln, sprintf($f->{sprintf},$cp) );
	    }
	$_ = join( $main::ARGS{odelimeter}, @ln );
	s/\s*$//g;
	push @ret, $_, "\n";
	}
    return join("",@ret);
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
