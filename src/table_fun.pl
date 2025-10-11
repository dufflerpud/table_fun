#!/usr/bin/perl -w

#########################################################################
#	table_fun	by Christopher Caldwell, 09/16/2020		#
#	A filter/program for copying one table type to another.		#
#	Knows how to read html, text with delimited columns and others.	#
#	and many others.						#
#########################################################################
#
#	See &usage() to see how this is run as a script.
#
#	Each type has an input_ and output_ routine pointed to by %FUNCS.
#
#	Each input_xxx routine is responsible for returning a pointer to
#	a hash with the following fields:
#	@{records}	- an array (records) of arrays (data)
#	%{byname}	- a hash of hash pointers indexed by field name
#	@{byindex}	- an array of hash pointers indexed by field number
#
#	%byname and @byindex have pointers to a hash containing:
#	${name}		- field name
#	${ind}		- index in rectangular table
#	${width}	- maximum number of wide column would be
#	${justified}	- 1 means right justified, -1 means left justified
#	${tdargs}	- "align=right" or "align=left"
#	${sprintf}	- "%Xs" or "%-Xs" where X is width

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( cleanup fatal files_in );
use cpi_cgi qw( CGIreceive CGIheader );
use cpi_arguments qw( parse_arguments );

# Put constants here
our %ONLY_ONE_DEFAULTS =
    (
    "if"	=> "/dev/stdin",
    "of"	=> "/dev/stdout",
    "od"	=> " ",
    "oj"	=> 0
    );
my $HANDLER_DIR = "$cpi_vars::BASEDIR/handlers";

# Put variables here.
our %ARGS = ();
our @files = ();
our $exstat = 0;

our @problems;

our %FUNCS;
our $reason;

# Put interesting subroutines here

#########################################################################
#	Deal with unset fields.						#
#########################################################################
sub orempty
    {
    my( $arg ) = @_;
    return ( defined($arg) ? $arg : "" );
    }

#########################################################################
#	Output a table with fields to fill in including a file to	#
#	convert and a destination type.					#
#########################################################################
sub draw_screen
    {
    &CGIheader();
    print <<EOF0,
<form method=post name=form ENCTYPE="multipart/form-data">
<center><table style="border-collapse:collapse;border:solid;" border=1>
    <tr><th align=left>Input file:</th>
	<td><input type=file name=contents></td></tr>
    <tr><th align=left>Output file type:</th>
	<td><select name=output_type>
	    <option value=none>Select file type</option>
EOF0
    ( map {"<option value=$_>".$FUNCS{$_}{pretty}."</option>\n"}
	( sort keys %FUNCS ) ),
    <<EOF1;
    <tr><th colspan=2><input type=submit></th></tr>
</table></center>
EOF1
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>",
	"",
	"where <possible arguments> are one or more of:",
	"",
	"\t-if <input file>",		"\t-of <output file>",
	"\t-it <input file type>",	"\t-ot <output file type>",
	"\t-id <input field delimeter>","\t-od <output field delimeter>",
	"\t-oj <width of columns>",
	"\t-f <comma separated field list in output table defaulting to all>",
	"",
	"$cpi_vars::PROG makes reasonable guesses when arguments aren't supplied."
	);
    }

#########################################################################
#	Return index of table row to put particular field in.		#
#########################################################################
sub ind_of_field
    {
    my( $fname, $output_data_ptr ) = @_;
    my $ind = ${$output_data_ptr}{byname}{$fname}{ind};
    if( ! defined($ind) )
	{
	$ind =
	    ( defined(${$output_data_ptr}{byindex}) 
	    ? scalar( @{ ${$output_data_ptr}{byindex} } )
	    : 0 );
	my %fd = ( name=>$fname, ind=>$ind );
	${$output_data_ptr}{byname}{$fname} = \%fd;
	push( @{ ${$output_data_ptr}{byindex} }, \%fd );
	}
    return $ind;
    }

#########################################################################
#	Take a pointer to a table, probably from javascript or json	#
#	and put it into our own structure.				#
#########################################################################
sub table_in_memory
    {
    my( $pref ) = @_;
    my %output_data;
    foreach my $hashp ( @{$pref} )
        {
	my @cells;
	grep( $cells[ &ind_of_field($_,\%output_data) ] = $hashp->{$_},
	    keys %{$hashp} );
	push( @{$output_data{records}}, \@cells );
	}
    return \%output_data;
    }

#########################################################################
#	Calculate field lengths						#
#########################################################################
sub calculate_field_widths
    {
    my( $input_data ) = @_;

    foreach my $f ( @{$input_data->{byindex}} )
        {
	$f->{width} = length( $f->{name} );
	$f->{justified} = 1;
	}

    foreach my $rp ( @{$input_data->{records}} )
	{
	if( scalar( @{$rp} ) > 1 )
	    {
	    my $fldnum = 0;
	    foreach my $cp ( @{$rp} )
		{
		my $f = $input_data->{byindex}[$fldnum];
		if( defined($cp) )
		    {
		    my $l = length($cp);
		    $f->{width} = $l if( $l > $f->{width} );
		    $f->{justified} = -1 if( $cp !~ /^\s*[0-9\.\-]*\s*$/ )
		    }
		$fldnum++;
		}
	    }
	}

    foreach my $f ( @{$input_data->{byindex}} )
        {
	$f->{tdargs} = ($f->{justified} < 0 ? "align=left" : "align=right");
	$f->{sprintf} =
	    ( $ARGS{oj}
	    ? "%".($f->{justified}*$ARGS{oj})."s"
	    : "%".($f->{justified}*$f->{width})."s"
	    );
	}
    #&dump_stats( $input_data );
    }

#########################################################################
#	Figure out what input file is and employ appropriate parser.	#
#########################################################################
sub input_records
    {
    my $txt;
    if( ! $ARGS{if} || $ARGS{if} eq "/dev/stdin" )
	{ $txt = join("",<STDIN>); }
    else
	{
	open(INF,$ARGS{if}) || &fatal("Cannot open $ARGS{if}:  $!");
	$txt = join("",<INF>);
	close( INF );
	}

    if( $ARGS{it} )
        { $reason = "input arguments"; }
    else
        {
	foreach my $t (
	    sort {	($FUNCS{$b}{recopri}||0)
		<=>	($FUNCS{$a}{recopri}||0) }
		keys %FUNCS )
	    {
	    if( defined($_ = $FUNCS{$t}{recognizer}) )
	        {
		if( ref($_) )
		    {
		    if( &{$_}($txt) )
		        {
			$ARGS{it}=$t;
			$reason = "content matching routine";
			last;
			}
		    }
		elsif($txt=~/$_/msi)
		    {
		    $ARGS{it}=$t;
		    $reason = "content matching \"$_\"";
		    last;
		    }
		}
	    }

	if( $ARGS{it} )
	    {}
	elsif( $ARGS{if} =~ /.*\.([A-Za-z0-9]+)$/ && $FUNCS{$1} )
	    {
	    $ARGS{it} = $1;
	    $reason = "extension of filename";
	    }
	else
	    {
	    $ARGS{it} = "text";
	    $reason = "default";
	    }
	}

#    print "CMC 1 Type of $ARGS{if}",
#	" is $ARGS{it} based on the $reason.\n";

    return &{ $FUNCS{$ARGS{it}}{input} }( $txt );
    }

#########################################################################
#	Open file to output and invoke correct writer.			#
#########################################################################
sub output_records
    {
    my( $input_data ) = @_;

    if( ! $ARGS{ot} )
        {
	if( $ARGS{of} =~ /.*\.([A-Za-z0-9]+)$/ && $FUNCS{$1} )
	    { $ARGS{ot} = $1; }
	else
	    { $ARGS{ot} = "text"; }
	}

    @{$input_data->{print_order}} =
        ( defined( $ARGS{f} )
	? map { $input_data->{byname}{$_} } split(/,/,$ARGS{f})
	: @{$input_data->{byindex}} );

    if( ! open(OUT,"> $ARGS{of}") )
        {
	if( $ARGS{of} ne "/dev/stdout" )
	    { &fatal("Cannot write $ARGS{of}:  $!"); }
	elsif( ! open(OUT, ">&STDOUT" ) )
	    { &fatal("Cannot dup(STDOUT):  $!"); }
	}
    &{ $FUNCS{$ARGS{ot}}{output} }( $input_data );
    close( OUT );
    }

#########################################################################
#	Print information about what had read in			#
#########################################################################
sub dump_stats
    {
    my( $input_data ) = @_;
    if( ! $input_data )
        { print STDERR "dump_stats() called with no data.\n"; }
    elsif( ref($input_data) ne "HASH" )
        { print STDERR "dump_stats called with ",ref($input_data),", not a HASH.\n"; }
    else
	{
	printf STDERR ("%-24s","Number of records:");
	if( ! $input_data->{records} )
	    { print STDERR "(input_data->records not filled in)"; }
	elsif( ref($input_data->{records}) ne "ARRAY" )
	    { print STDERR "(input_data->records not an ARRAY)"; }
	else
	    { print STDERR scalar(@{$input_data->{records}}); }

	printf STDERR ("\n%-24s","Indices:");
	if( ! $input_data->{byindex} )
	    { print STDERR "(input_data->indices not filled in)"; }
	elsif( ref($input_data->{byindex}) ne "ARRAY" )
	    { print STDERR "(input_data->indices not an ARRAY)"; }
	else
	    { print STDERR join(" ",map { $_->{name} } @{$input_data->{byindex}}); }

	printf STDERR ("\n%-24s","Fields:");
	if( ! $input_data->{byname} )
	    { print STDERR "(input_data->fields not filled in)"; }
	elsif( ref($input_data->{byname}) ne "HASH" )
	    { print STDERR "(input_data->fields not an HASH)"; }
	else
	    {
	    print STDERR scalar( keys %{$input_data->{byname}} );
	    foreach my $i ( @{$input_data->{byindex}} )
	        {
		print STDERR "\n", $i->{name}, ":",
		    map { " $_=".$i->{$_} }
			sort keys %{$i};
		}
	    }
	print STDERR "\n";
	}
    return $input_data;
    }

#########################################################################
#	Convert file from FORM{contents} to file type specified in	#
#	FORM{output_type}.						#
#########################################################################
my $tmpfile;
sub do_table_conversion
    {
    $tmpfile = &tempfile();
    &write_file( $tmpfile, $cpi_vars::FORM{contents} );

    $ARGS{if} = $tmpfile;
    $ARGS{ot} = $cpi_vars::FORM{output_type};
    grep( $ARGS{$_}||=$ONLY_ONE_DEFAULTS{$_}, keys %ONLY_ONE_DEFAULTS );

    print "Content-type:  ", $FUNCS{ $cpi_vars::FORM{output_type} }{mime}, "\n\n";
    STDOUT->flush();
    &output_records( &input_records() );
    }

#########################################################################
#	Main								#
#########################################################################
#
#my @QS = &cpi_file::files_in( $HANDLER_DIR, "^[^\.].*.pl\$" );
#print "QS=[",join(",",@QS),"]\n";
#exit(0);
#opendir( D, $HANDLER_DIR ) || &fatal("Cannot opendir($HANDLER_DIR):  $!");
#foreach my $h ( map {"$HANDLER_DIR/$_"} grep( /^[^\.].*.pl$/, readdir(D) ) )
#closedir( D );
foreach my $h ( map {"$HANDLER_DIR/$_"} &files_in($HANDLER_DIR,"^[^\.].*.pl\$") )
#foreach my $h ( 1, 2, 3 )
    { do $h; }

if( $ENV{SCRIPT_NAME} )
    {
    &CGIreceive();
    if( $cpi_vars::FORM{contents} && $cpi_vars::FORM{output_type} && $cpi_vars::FORM{output_type} ne "none" )
	{ &do_table_conversion(); }
    else
	{ &draw_screen(); }
    }
else
    {
    &parse_arguments();
    &output_records( &input_records() );
    system("setclip $ARGS{of}") if( $ARGS{oc} );
    }

&cleanup( $exstat );
