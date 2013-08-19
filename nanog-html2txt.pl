#!/usr/bin/perl

use strict;

my $h2a = "/usr/local/bin/html2ascii";
my $sep = "_________________________________________________________________";

sub convert_to_ascii {
    my $mailfile = shift;

    my $state = 0;
    my ($subj, $from, $date);
    my $body;

    open (F, "$h2a $mailfile |") || die "can't parse/open $mailfile: $!\n";
    while (<F>) {
	if ($_ =~ /$sep/) {
	    $state++;
	    if (!($date eq '')) { $state=2; }
	    next;
	}

	if ($state==0) {

	    if ($_ =~ /\S+/ && $subj eq '') {
		$subj = $_;
		$subj =~ s/^\s+//g;
		$subj =~ s/\s+$//g;
	    }

	    if ($_ =~ /From:\s+(.*)/) {
		$from = $1;
	    }
	    if ($_ =~ /Date:\s+(.*)/) {
		$date = $1;
	    }

	}

	if ($state==1) {

	    if ($_ =~ /Subject:\s+(.*)/) {
		$subj = $1;
	    }
	    if ($_ =~ /From:\s+(.*)/) {
		$from = $1;
	    }
	    if ($_ =~ /Date:\s+(.*)/) {
		$date = $1;
	    }

	} if ($state==2) {

	    if ($_ =~ /Next message:/i) {
		$state++;
		next;
	    }
	    if ($_ =~ /References/i) {
		$state++;
		next;
	    }

	    $body .= $_;

	}

    }

    my $name;
    my $email;
    my $cleanfrom = $from;

    if ($from =~ /(.*?)\((.*)\)/) {
	$name = $1;
	$email = $2;
	$email =~ s/\s+at\s+/\@/;
	$email =~ s/\s+dot\s+/\./g;
	$cleanfrom = "$name <$email>";
    } 
    


    my $cleandate = $date;
    if ($date =~ /(.*)\s+(\d{4})\s+\-\s+(\d{2}:\d{2}:\d{2})\s+([A-Z]+)/) {
	my $day = $1;
	my $year = $2;
	my $time = $3;
	my $tz = $4;
	$cleandate = "$day $time $year $tz";
    }

    print "\nFrom $email $cleandate\n";
    print "From: $cleanfrom\n";
    print "Date: $date\n";
    print "Subject: $subj\n";
    print "\n\n";
    print "$body\n";

};

&convert_to_ascii($ARGV[0]);
