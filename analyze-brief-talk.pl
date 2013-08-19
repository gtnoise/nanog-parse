#!/usr/bin/perl

use DBI;
use Data::Dumper;
use Time::Local;

use strict;

my %problems = ();

my %totals_year = ();
my %totals_prop = ();
my %totals = ();

my %prop_hash = (
		 'ifc' => 'Attribute manipulation',
		 'filter' => 'Filtering',
		 'ibgp' => 'iBGP-related',
		 'det' => 'Oscillations',
		 'leak' => 'Leaked Routes',
		 'loop' => 'Routing Loops',
		 'reachability' => 'Blackholes',
		 'stability' => 'Routing Instability',
		 'vis' => 'Global Route Visibility',
		 'hijack' => 'Hijacked Routes');

my %prop_desc = (
		 'ifc' => 'BGP attribute manipulation (\eg, for implementing backup)',
		 'filter' => 'Filtering problems with private addresses',
		 'det' => 'Persistent route oscillations',
		 'stability' => 'Route instability (\ie "flapping")',
		 'vis' => 'Filtering new address allocations',
		 'leak' => 'AS mistakenly announcing routes (\eg, bad prefix, bad AS path, etc.) ',
		 'ibgp' => 'Apparently an iBGP problem',
		 'loop' =>' Traceroute with loop',
		 'reachability' => 'Traceroute with blackhole (or complaint)',
		 'hijack' => 'Observation of or complaint about stolen address space'
		 );
		 
my %step_hash = (
		 'ifc' => 5,
		 'filter' => 2,
		 'ibgp' => 6,
		 'det' => 4,
		 'leak' => 2,
		 'loop' => 6,
		 'reachability' => 6,
		 'stability' => 4,
		 'vis' => 3,
		 'hijack' => 2);

# 1: 1996-1998
# 2: 1999-2001
# 3: 2002-2004

my %year_bins = (#1994 => 0,
#		 1995 => 0,
		 1996 => 0,
		 1997 => 0,
		 1998 => 0,
		 1999 => 1,
		 2000 => 1,
		 2001 => 1,
		 2002 => 2,
		 2003 => 2,
		 2004 => 2);


my %bins = (0 => '1996-1998',
	    1 => '1999-2001',
	    2 => '2002-2004');


sub str_to_unixtime {
    my ($datestr) = @_;

    my ($date_date, $date_time) = split(" ", $datestr);
    my ($year, $month, $mday) = split("-", $date_date);
    my ($hour, $min, $sec) = split(":", $date_time);

    $year-=1900;
    $month--;

    return timelocal($sec, $min, $hour, $mday, $month, $year);
}


sub dbhandle {
    my $database="feamster";
    my $hostname="bgp.lcs.mit.edu";
    my $user = "feamster";
    my $password = "";

    my $dsn = "DBI:mysql:database=$database;host=$hostname";
    my $dbh = DBI->connect($dsn, $user, $password);
    my $drh = DBI->install_driver("mysql");
    return $dbh;
}
my $dbh = &dbhandle();


sub build_table {
    my $inq = shift;

#    for (my $yr=1995; $yr<2005; $yr++) {
    foreach my $yr (sort { $a <=> $b } keys %year_bins) {

	my $bin = $year_bins{$yr};
	my $yrstr = sprintf("%d-1-1 00:00:00", $yr);
	my $next_yrstr = sprintf("%d-1-1 00:00:00", $yr+1);

	my $starttime = &str_to_unixtime($yrstr);
	my $endtime = &str_to_unixtime($next_yrstr);

	foreach my $prop (('ibgp','stability','filter','loop','hijack','leak','vis','ifc','det')) {
	    my $q = "select count(*) from nanog_email where $prop=1 and unixtime>$starttime and unixtime<$endtime and inquiry=$inq";
	    my $sth = $dbh->prepare($q);
	    $sth->execute;

	    my ($cnt) = $sth->fetchrow_array();
	    $problems{$prop}->{$bin}->{$inq} += $cnt;

	    $totals_prop{$prop}->{$inq} += $cnt;
	    $totals_year{$bin}->{$inq} += $cnt;
	    $totals{$inq} += $cnt;
  	}


	# classify reachability and blackholes as the same
	my $q = "select count(*) from nanog_email where (reach=1 or bh=1) and unixtime>$starttime and unixtime<$endtime and inquiry=$inq";
	my $sth = $dbh->prepare($q);
	$sth->execute;
	my ($cnt) = $sth->fetchrow_array();
	$problems{'reachability'}->{$bin}->{$inq} += $cnt;

	$totals_prop{'reachability'}->{$inq} += $cnt;
	$totals_year{$bin}->{$inq} += $cnt;
	$totals{$inq} += $cnt;
    }


}

sub print_table {
    my $sep = " & ";
    my $lf = "\\\\\n";

    my $dotted = "\\hdashline[1pt/1pt]\n";


    # Header
    my $line = "{\\bf Property}$sep {\\bf Description}$sep";
    foreach (sort {$a <=> $b} keys %bins) {
	$line .=  "{\\bf $bins{$_}}$sep";
    }

    $line .= "{\\bf Total}$sep";
    $line =~ s/\&\s*$//;
    print $line;
    print "$lf";
    print "\\hline\n";

    my $last_step = 100;

    foreach my $prop (sort {$step_hash{$a} <=> $step_hash{$b}}
		      keys %problems) {

	if ($step_hash{$prop} > $last_step) {
	    print "$dotted";
	}
	$last_step = $step_hash{$prop};

#	my $line = "$prop_hash{$prop}$sep$step_hash{$prop}$sep ";
	my $line = "$prop_hash{$prop}$sep";
	$line .= "$prop_desc{$prop}$sep";


	# print counts per year
	#foreach my $yr (sort {$a <=> $b} keys %{$problems{$prop}}) {
	foreach my $yr (sort { $a <=> $b } keys %bins) {
	    $line .= sprintf ("%d (%d)$sep ", $problems{$prop}->{$yr}->{0},
			      $problems{$prop}->{$yr}->{0}+
			      $problems{$prop}->{$yr}->{1});
	}
	$line .= sprintf ("%d (%d)", $totals_prop{$prop}->{0},
			  $totals_prop{$prop}->{0}+
			  $totals_prop{$prop}->{1});

	$line =~ s/\&\s*$//;
	print $line;
	print "$lf";
    }



    # print all of the totals
    my $line = "\\hline\n{\\bf Total}$sep$sep";
    foreach (sort { $a <=> $b } keys %bins) {
	my $yr = $_;
	$line .= sprintf("%d (%d)$sep",
			 $totals_year{$yr}->{0},
			 $totals_year{$yr}->{0}+
			 $totals_year{$yr}->{1});
    }
    $line .= sprintf("%d (%d)$sep\n",
		     $totals{0}, $totals{0}+$totals{1});
    $line =~ s/\&\s*$//;
    print $line;
    print "$lf";



}


&build_table(1);
&build_table(0);

&print_table();
