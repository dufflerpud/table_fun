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
