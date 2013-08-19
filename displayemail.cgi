#!/usr/bin/perl

use DBI;
use CGI::Pretty qw/:standard :html3/;
use CGI::Carp  qw(fatalsToBrowser);

use strict;

my $c = new CGI;
my $this = $c->url(-relative=>1);

my $params = $c->Vars();
my $num = $params->{'num'};

my @properties = (('prefix','global','ibgp','stability','filter','loop','hijack','bh','leak','reach','inquiry','val','vis','ifc','det','saf'));

sub dbhandle {
    my $database="nanog";
    my $hostname="localhost";
    my $user = "feamster";
    my $password = "";

    my $dsn = "DBI:mysql:database=$database;host=$hostname";
    my $dbh = DBI->connect($dsn, $user, $password);
    my $drh = DBI->install_driver("mysql");
    return $dbh;
}
my $dbh = &dbhandle();

sub show_email {
    my $id = shift;
    my $get = shift;
    my $subm = shift;

    my $q;
    my $prev = $id - 1;
    my $next = $id + 1;
    my $restr;

    if ($get==1) {

	if (!$subm) {
	    foreach my $p (@properties) {
		if ($params->{$p} eq 'on' || $params->{$p}==1) {
		    $restr .= " $p=1 and";
		}
	    }
	} else {
	    foreach my $p (@properties) {
		my $sp = "_$p";
		if ($params->{$sp}==1) {
		    $restr .= " $p=1 and";
		}
	    }
	}
	$restr =~ s/ and$//;
	
	$q = "select min(id) from nanog_email where $restr";
	$q .= " and id>=$id" if defined($id);
	print "$q<p>";

	my $sth = $dbh->prepare($q);
	$sth->execute;
	($id) = $sth->fetchrow_array();

	$q = "select min(id) from nanog_email where $restr and id>$id";
	$sth = $dbh->prepare($q);
	$sth->execute;
	($next) = $sth->fetchrow_array();

	$q = "select max(id) from nanog_email where $restr and id<$id";
	$sth = $dbh->prepare($q);
	$sth->execute;
	($prev) = $sth->fetchrow_array();
    }

    


    $q = "select from_name, from_email, from_unixtime(unixtime), subject, body from nanog_email where id=$id";

#    print "$q<p>";

    my $sth = $dbh->prepare($q);
    $sth->execute;
    my ($from_name, $from_email, $datetime, $subject, $body) = $sth->fetchrow_array();


    print start_form;

    if ($get==1) {

	my $q = "select prefix,global,ibgp,stability,filter,loop,hijack,bh,leak,reach,inquiry,val,vis,ifc,det,saf from nanog_email where id=$id";
	my $sth = $dbh->prepare($q);
	$sth->execute;
	my $prop_hr = $sth->fetchrow_hashref();

	foreach my $prop (@properties) {
	    print "<input type=\"checkbox\" name=\"$prop\"";
	    print " checked=1" if ($prop_hr->{$prop}==1);
	    print ">$prop\n";
	}

    } else {

	foreach my $prop (@properties) {
	    print "<input type=\"checkbox\" name=\"$prop\">$prop\n";
	}
    }

    print br;
#    foreach my $prop (('val','vis','ifc','det','saf')) {
#	print "<input type=\"checkbox\" name=\"properties\" value=\"$prop\">$prop\n";
#    }


    print p;
    print "<input type=\"hidden\" name=\"num\" value=$id>\n";
    printf "<input type=\"hidden\" name=\"next\" value=%d>\n", $next;

    print "<input type=\"hidden\" name=\"sub\" value=1>\n";
    print "<input type=\"hidden\" name=\"get\" value=$get>\n";


    foreach my $prop (@properties) {
	if ($params->{$prop}==1 || $params->{"_$prop"}==1) {
	    print "<input type=\"hidden\" name=\"_$prop\" value=1>\n";
	}
    }


    if (!$get) {
	printf ("<a href=$this?num=%d>prev</a>  ", $prev) if $prev>0;
	printf ("<a href=$this?num=%d>next</a>", $next);
    } else {
	my $restr;
	foreach my $prop (@properties) {
	    $restr .= "&$prop=1" if ($params->{$prop} eq 'on'
				     || $params->{$prop}==1);
	}

	printf ("<a href=$this?num=%d&get=1$restr>prev</a>  ", $prev) if $prev>0;
	printf ("<a href=$this?num=%d&get=1$restr>next</a>", $next);
    }

    print p, submit,p,p;
    print end_form;

    printf "<b>ID: </b> $id<br>";
    printf "<b>Date:</b> %s<br>", $datetime;
    printf "<b>Subject:</b> %s<br>", $subject;
    printf "<b>From:</b> %s (%s)<br>", $from_name, $from_email;
    print "<pre>$body</pre>";


}


print header, start_html("Nanog Emails");
if (defined($params->{'sub'})) {
    my $num = $params->{'num'};
    foreach my $p (@properties) {
	if ($params->{$p} eq 'on') {
	    my $cmd = "update nanog_email set $p=1 where id=$num";
#	    print "$cmd<p>\n";
	    $dbh->do($cmd);
	} else {
	    my $cmd = "update nanog_email set $p=0 where id=$num";
#	    print "$cmd<p>\n";
	    $dbh->do($cmd);
	}
    }
    

    my $next = $params->{'next'};
    my $get = $params->{'get'};
    &show_email($next,$get,1);


} elsif($params->{'get'}==1) {
    &show_email($num,1);
} else {
    &show_email($num);
}

