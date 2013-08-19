#!/usr/bin/perl

use strict;
use DBI;
use Mail::MboxParser;
use Date::Manip;

my @mbox_files = (qw(
		     nanog04-mbox));

#		     nanog94-mbox
#		     nanog95-mbox
#		     nanog96-mbox
#		     nanog97-mbox
#		     nanog98-mbox
#		     nanog99-mbox
#		     nanog00-mbox
#		     nanog01-mbox
#		     nanog02-mbox
#		     nanog03-mbox

		     
my $id = 1;
my $maxtime = 0;

##############################

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


sub set_id {
    my $q = "select max(id) from nanog_email";
    my $sth = $dbh->prepare($q);
    $sth->execute;
    
    my ($maxid) = $sth->fetchrow_array();
    if (defined($maxid) && $maxid > 1) {
	$id = $maxid+1;
    }

}

sub set_maxtime {
    my $q = "select max(unixtime) from nanog_email";
    my $sth = $dbh->prepare($q);
    $sth->execute;
    
    ($maxtime) = $sth->fetchrow_array();

}




sub lax_mbox_parse{
    my $mboxfile = shift;
    my $all = shift;
    my $msg; 

    my %seen_subject = ();
    my $count = 0;
    my $relevant;

    my $nanog_email = "nanog_email";
    $nanog_email = "nanog_email_all" if $all;

    open(MB, "$mboxfile") || die "$mboxfile: $!\n";

    while (<MB>) {
	
	$relevant = 0;

	if ($_ =~ /^Date:\s+(.*)/) {
	    $msg->{date} = $1;;
	}

	if ($_ =~ /^From:\s+(.*)/) {
	    $msg->{from} = $1;;
	}


	if ($_ =~ /^Subject:\s+(.*)/) {
	    $msg->{subject} = $1;
	}

	if (defined($msg->{date}) &&
	    defined($msg->{from}) &&
	    defined($msg->{subject})) {
	

	    my $subj = $msg->{subject};

	    my $clean_subj = $subj;
	    $clean_subj =~ s/re:\s*//ig;
	    
	    next if ($seen_subject{$clean_subj});


	    if ($all ||
		$subj =~ /outage/i ||
		$subj =~ /BGP/i ||
		$subj =~ /routes/i ||
		$subj =~ /prefix/i ||
		$subj =~ /1918/ ||
		$subj =~ /leak/i ||
		$subj =~ /blackhol/i ||
		$subj =~ /loop/i ||
		$subj =~ /collapse/i ||
		$subj =~ /problem/i ||
		$subj =~ /issue/i ||
		$subj =~ /stability/i ||
		$subj =~ /filter/i 
		) {
		$seen_subject{$clean_subj} = 1;
		
		printf ("%s\n%s\n%s\n\n",
			       $msg->{from},
			       $msg->{date},
			       $msg->{subject});

		$count++;
		$relevant = 1;
	    }



	    my $line = $_;
	    my $body;
	    while ($line !~ /^From\s+/ && $line) {
		$line = <MB>;
		$body .= "$line";
	    }

#	    print "$body" if $relevant;
	    my $from_name = $msg->{from};
	    my $from_email;

	    if ($from_name =~ /(.*?)\<(.*?)\>/) {
		$from_name = $1;
		$from_email = $2;
	    }


	    if ($relevant) {

		my $unixtime = &UnixDate($msg->{date}, "%s");

		next if ($unixtime<$maxtime);

		$msg->{subject} =~ s/\'//g;
		$msg->{subject} =~ s/\"//g;
		$from_name =~ s/\'//g;
		$from_name =~ s/\"//g;
		$from_email =~ s/\'//g;
		$from_email =~ s/\"//g;
		$body =~ s/\'//g;
		$body =~ s/\"//g;

		my $cmd = sprintf("insert into $nanog_email values ('%d','%s','%s','%lu','%s',\"%s\",'%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d')",
				  $id++, $from_name, $from_email,
				  $unixtime,
				  $msg->{subject},
				  $body, 
				  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		$dbh->do($cmd);
	    }




	    undef $msg->{date};
	    undef $msg->{from};
	    undef $msg->{subject};
	    
	}

    }
    printf ("%d messages in total\n", $count);
}

sub strict_mbox_parse {
    my $mboxfile = shift;

    my $mb = Mail::MboxParser->new($mboxfile,
				   decode     => 'ALL');

    my %seen_subject = ();
    my $count = 0;
    
############################################################

    while (my $msg = $mb->next_message) {
	my $subj = $msg->header->{subject};

	my $clean_subj = $subj;
	$clean_subj =~ s/re:\s*//ig;

	next if ($seen_subject{$clean_subj});

	if ($subj =~ /outage/i ||
	    $subj =~ /BGP/i ||
	    $subj =~ /routes/i ||
	    $subj =~ /prefix/i ||
	    $subj =~ /1918/ ||
	    $subj =~ /leak/i ||
	    $subj =~ /blackhol/i ||
	    $subj =~ /loop/i ||
	    $subj =~ /collapse/i ||
	    $subj =~ /problems/i ||
	    $subj =~ /instability/i ||
	    $subj =~ /filter/i 
	    ) {
	    $seen_subject{$clean_subj} = 1;

	    printf ("%s\n%s\n%s\n\n",
		    $msg->header->{from},
		    $msg->header->{date},
		    $msg->header->{subject});
	    $count++;

	}
    }

    printf ("%d messages in total\n", $count);
}


foreach my $mbox (@mbox_files) {
    &set_id();
    &set_maxtime();
    &lax_mbox_parse("/home/feamster/nanog-archives/$mbox");
}

