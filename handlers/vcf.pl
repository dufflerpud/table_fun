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
$driverp->{pretty}	= "vcf - Virtual Contact File";
$driverp->{mime}	= "text/plain";
$driverp->{recognizer}	= "BEGIN:VCARD";
$driverp->{recopri}	= 2;
#&device_debug(__FILE__,__LINE__,"start eval");

#########################################################################
#	Parse a VCF file.						#
#########################################################################
my @VCF_MAPS =
    (
    "item",			"",
    "ADR",			"Address",
    "X-AB",			"",
    "ShowAs",			"Type",
    "^N\$",			"Name",
    "^FN",			"Full-Name",
    "^ORG",			"Organization",
    "TEL",			"Phone",
    ";type=IPHONE;type=CELL",	";type=IPHONE",
    ";type=VOICE",		"",
    ";type=INTERNET",		"",
    ";type=pref",		"",
    ";type=",			"-"
    );
my @VCF_FIELDS =
    (
    #{	F=>"COMPANY",		P=>"Company"	},
    #{	F=>"FN",		P=>"Full name"	},
    {	F=>"BEGIN",		SKIP=>1		},
    {	F=>"END",		SKIP=>1		},
    {	F=>"VERSION",		SKIP=>1		},
    {	F=>"PRODID",		SKIP=>1		},
    {	F=>"REV",		SKIP=>1		},
    {	F=>"X-ACTIVITY-ALERT",	SKIP=>1		}
    );

my %COLLAPSE_FIELDS =
    (
    "Phone"	=>[	"Phone-Iphone", "Phone-Cell", "Phone-Work",
			"Phone-Main", "Phone-Other", "Phone-Home" ],
    "Address"	=>[	"Address-Home", "Address-Other", "Address-Work" ]
    );

#########################################################################
#	Parse a VCF file (unfortunately, they are so hairy that we end	#
#	up doing lots of table based substitutions).			#
#########################################################################
$driverp->{input} = sub
    {
    my( $fl ) = @_;
    my %output_data;
    my %skips = map {$_,1} ( map {$_->{"F"}} grep($_->{"SKIP"}, @VCF_FIELDS) );
    my %mapto;
    foreach my $colkey ( %COLLAPSE_FIELDS )
        {
	grep( $mapto{$_}=$colkey, @{$COLLAPSE_FIELDS{$colkey}} );
	}

    $fl =~ s/\r//gs;
    my @inlines = split(/\n/ms,$fl);

    while( defined($_=shift @inlines)
	&& ($_ !~ /^BEGIN:VCARD/) && ($_ !~ /^END:VCARD/) )
        { }
    
    while( defined($_) && ($_ =~ /^BEGIN:VCARD/) )
        {
	my @record = ();
	my $found = 0;
	while( defined($_=shift @inlines) && ($_ !~ /^END:VCARD/) )
	    {
	    chomp( $_ );
	    if( /^([^:]*):(.*)$/ )
	        {
		my( $fname, $fval ) = ( $1, $2 );
		my $fname0 = $1;
		$fval =~ s/^/*/ if( $fname =~ /;type=pref/ );
		my @maps = @VCF_MAPS;
		while( my $map_from = shift(@maps) )
		    {
		    my $map_to = shift(@maps);
		    $fname =~ s/$map_from/$map_to/gi;
		    }
		my $fname1 = $fname;
		$fname =~ s/phone(.*)-fax(.*)/fax$1$2/i;
		$fname =~ s/([\w']+)/\u\L$1/g;
		#print STDERR "Mapped {$fname0} => {$fname1} => {$fname}\n";
		next if( $skips{uc($fname)} );
		$fval =~ s/^;*//;
		$fval =~ s/;*$//;
		#$fval =~ s/[\s\o{160}\o{130}]+//g if( $fname =~ /phone/i );
		$fval =~ s/[^\w()\-\*]+//g if( $fname =~ /phone|fax/i );
		$fval =~ s/_\$!<(.*)>!\$_/$1/g;
		$found = 1;

		if( $fval =~ /[&?]ll=([\-\d\.]+)\\,([\-\d\.]+)/ )
		    {
		    $fname = "LatLong";
		    $fval = "${1}:${2}";
		    }
		elsif( $fval =~ /(apple uses latlong)/i )
		    {
		    $fname = "Navrules";
		    $fval = lc($1);
		    }

		my @fields_to_add = ( $fname );
		my $base = ( $fname =~ /^\d+\.(.*)$/ ? $1 : $fname );
		#print STDERR "Basemap {$fname} to {$base}\n";
		push( @fields_to_add, $mapto{$base} )
		    if( defined($mapto{$base}) );

		foreach $fname ( @fields_to_add )
		    {
		    #print STDERR "Storing {$fname} in {$fval}\n";
		    my $ind = $output_data{byname}{$fname}{ind};
		    if( ! defined( $ind ) )
			{
			$ind =
			    ( defined( $output_data{byindex} )
			    ? scalar(@{$output_data{byindex}})
			    : 0 );
			my %fd = ( name=>$fname, ind=>$ind );
			$output_data{byname}{$fname} = \%fd;
			push( @{$output_data{byindex}}, \%fd );
			}
		    $record[ $ind ] = $fval if( ! defined( $record[$ind] ) );
		    }
		}
	    }
	if( $found )
	    {
	    push( @{$output_data{records}}, \@record );
	    }
	while( defined($_ = shift @inlines) && $_ =~ /^\s*$/ ) {};
	}
    return \%output_data;
    };

#########################################################################
#	Return named field from current record.				#
#########################################################################
sub field_of
    {
    my( $input_data, $rp, $fname ) = @_;
    my $ind = $input_data->{byname}{$fname}->{ind};
#    print STDERR "id->{byname}{$fname}->{ind} = ",
#	(defined($ind)?$ind:"UNDEF"), "\n";
    return
	( defined($ind)
	? &main::orempty( $rp->[ $input_data->{byname}{$fname}->{ind} ] )
	: "" );
    }

#########################################################################
#	Output vcf							#
#########################################################################
$driverp->{output} = sub
    {
    my( $input_data ) = @_;
    my @ret;

    foreach my $rp ( @{$input_data->{records}} )
        {
	my $pphone = &field_of($input_data,$rp,"Phone" );
	if( $pphone && $pphone=~ /^(\d*)-(\d*)-(\d*)$/ )
	    { $pphone="($1) $2-$3"; }
	else
	    { $pphone ||= ""; }
	push @ret,
	    "BEGIN:VCARD\nVERSION:3.0\n".
	    "N:".&field_of($input_data,$rp,"Last_name").';'.&field_of($input_data,$rp,"First_name").";;;\n".
	    "FN:".&field_of($input_data,$rp,"Last_name").';'.&field_of($input_data,$rp,"First_name").";;;\n".
	    "ORG:".&field_of($input_data,$rp,"Company").";\n".
	    "TEL;type=mobile;type=VOICE;type=pref:$pphone\n".
	    "item1.ADR;type=HOME;type=pref:;;".
		&field_of($input_data,$rp,"Address").";".
		&field_of($input_data,$rp,"State").";".
		&field_of($input_data,$rp,"Zip").";".
		"United States\n".
	    "item1.X-ABADR:us\n".
	    "END:VCARD\n";
	}
    return join("\n",@ret);
    };

#&device_debug(__FILE__,__LINE__,"end eval");
1;
