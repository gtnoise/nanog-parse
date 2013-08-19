#!/usr/bin/perl

use strict;

my $wget = "/usr/local/bin/wget";
my @mos = (qw(1 2 3 4 5 6 7 8 9 10 11 12));
my @yrs = (qw(1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004));

foreach my $yr (@yrs) {
    foreach my $mo (@mos) {
	next if ($mo < 4 && $yr <= 1994);
#	next if ($yr < 2001);
#	next if ($yr == 2001 && $mo < 8);
	next if ($mo > 1 && $yr >= 2004);

	my $datestr = sprintf ("%.2d%.2d",
			       $yr % 100,
			       $mo % 100);

	system("mkdir -p ./$datestr/");
	my $listfile = "./$datestr/date.html";

	my $url = "http://www.irbs.net/internet/nanog/$datestr/date.html";
	print STDERR "$url\n";

	system("$wget $url -O $listfile");

	open(LIST, "$listfile") || die "can't open $listfile: $!\n";
	while (<LIST>) {
	    if ($_ =~ /a\s+href=\"*(\d{4}\.html)\"*/i) {
		my $url = "http://www.irbs.net/internet/nanog/$datestr/$1";
		my $msgfile = "./$datestr/$1";
		print STDERR "$url\n";
		system ("$wget -O $msgfile $url");
	    }
	}


    }
}
