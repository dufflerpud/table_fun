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
$DRIVER->{pretty}	= "text - Text file";
$DRIVER->{mime}		= "text/plain";

my $COMMON_SEPS = "\t,|!:+";

#########################################################################
#	Parse a text file						#
#########################################################################
$DRIVER->{input} = sub
    {
    my( $fl ) = @_;
    if( ! defined( $main::ARGS{idelimeter} ) )
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
$DRIVER->{output} = sub
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

1;
