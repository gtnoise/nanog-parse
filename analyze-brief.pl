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
		 'ifc' => 'Attribute manip.',
		 'filter' => 'Filtering',
		 'ibgp' => 'iBGP-related',
		 'det' => 'Oscillations',
		 'leak' => 'Leaked Routes',
		 'loop' => 'Routing Loops',
		 'reachability' => 'Blackholes',
		 'stability' => 'Routing Instability',
		 'vis' => 'Global Route Visibility',
		 'hijack' => 'Hijacked Routes');
		 
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

    for (my $yr=1994; $yr<2005; $yr++) {


	my $yridx = int($yr/100);

	my $yrstr = sprintf("%d-1-1 00:00:00", $yr);
	my $next_yrstr = sprintf("%d-1-1 00:00:00", $yr+1);

	my $starttime = &str_to_unixtime($yrstr);
	my $endtime = &str_to_unixtime($next_yrstr);

	foreach my $prop (('ibgp','stability','filter','loop','hijack','leak','vis','ifc','det')) {
	    my $q = "select count(*) from nanog_email where $prop=1 and unixtime>$starttime and unixtime<$endtime and inquiry=$inq";
	    my $sth = $dbh->prepare($q);
	    $sth->execute;

	    my ($cnt) = $sth->fetchrow_array();
	    $problems{$prop}->{$yridx}->{$inq} += $cnt;

	    $totals_prop{$prop}->{$inq} += $cnt;
	    $totals_year{$yridx}->{$inq} += $cnt;
	    $totals{$inq} += $cnt;
  	}


	# classify reachability and blackholes as the same
	my $q = "select count(*) from nanog_email where (reach=1 or bh=1) and unixtime>$starttime and unixtime<$endtime and inquiry=$inq";
	my $sth = $dbh->prepare($q);
	$sth->execute;
	my ($cnt) = $sth->fetchrow_array();
	$problems{'reachability'}->{$yridx}->{$inq} += $cnt;

	$totals_prop{'reachability'}->{$inq} += $cnt;
	$totals_year{$yridx}->{$inq} += $cnt;
	$totals{$inq} += $cnt;
    }


}

sub print_table {
    my $sep = " & ";
    my $lf = "\\\\\n";

    my $dotted = "\\hdashline[1pt/1pt]\n";


    my $line = "Property$sep";
    for (my $yr=19; $yr<21; $yr++) {
	$line .= "$yr$sep"
    }
    $line .= "Total$sep";
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
	foreach my $yr (sort {$a <=> $b} keys %{$problems{$prop}}) {
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



    my $line = "\\hline\nTotal$sep";
    for (my $yr=19; $yr<21; $yr++) {
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
