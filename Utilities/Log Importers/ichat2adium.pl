#!/usr/bin/perl

# $Id$
#
# This program imports iChat logs using the program Logorrhea.  Get it from
# http://spiny.com/logorrhea/
#
# Using Logorrhea, export all of your chats.
#
# Then run this script with "ichat2adium.pl filename"  or run from the same
# directory as the exported contents.
#
# If you pass the "--usernames" flag, the script will prompt you for the
# usernames of the various aliases.
#
# The "--primary-user USERNAME" flag will set the name of the user to your
# username.
#
# Records that make no sense will be sent to "adiumLogs/bad".
#
# You should be able to drop the adiumLogs folder into ~/Library/Application
# Support/Users/YOU/Logs/.

use Time::Local;
use warnings;
use strict;

my $file;
my $users = 0;
my $primary;
my @usernames;
my @chatnames;

if(@ARGV > 0) {
    $file = $ARGV[0];
} else {
    $file = "iChat Export.txt";
}
for (my $i = 1; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--usernames") {
        $users = 1;
    }
    if($ARGV[$i] eq "--primary-user" ) {
        $primary = $ARGV[$i + 1];
    }
}
open(FILE, $file) or die qq{Unable to open "$file": $!};

$/ = "\r";

my @input = <FILE>;

my $base_out;

if ($primary) {
    $base_out = "AIM.$primary";
} else {
    $base_out = "AIM.iChatLogs";
}

umask(000);
mkdir($base_out, 0777) unless (-d $base_out);

my $outfile = "$base_out/bad";

close(FILE);

for (my $i = 0; $i < @input; $i++) {
    my ($chatname, $sender, $date, $time, $message);
    my ($day, $month, $year);
    my ($hh, $mm, $ss, $modTime);
    
    $_ = $input[$i];
    
    ($chatname, $sender, $date, $time, $message) =
    /(.*?)\t(.*?)\t(.*?)\t(.*?)\t.*?\t(.*)\r/s;

    $_ = $date;
    
    if($date) {
        ($month, $day, $year) = /(\d\d)\/(\d\d)\/(\d\d\d\d)/;
    }

    if($users && $chatname && $sender) {
        my $userfound = 0;
        for(my $j = 0; $j < @chatnames; $j++) {
            if ($chatnames[$j] eq $chatname) {
                $userfound = 1;
                $chatname = $usernames[$j];
            }
        }
        if($userfound == 0) {
            push(@chatnames, $chatname);
            print "Enter username associated with $chatname [$sender]:";
            $/ = "\n";
            my $input = <STDIN>;
            chomp($input);
            if(length($input) == 0) {
                push(@usernames, $sender);
                $chatname = $sender;
            } else {
                push(@usernames, $input);
                $chatname = $input;
            }
        }
    }

    $chatname =~ s/ //g;

    if($chatname && $sender && $date && $month && $day && $year && $message) {
        umask(000);
        mkdir("$base_out/$chatname", 0777) unless (-d "$base_out/$chatname");
        
        $outfile = "$base_out/$chatname/$chatname ($year|$month|$day).adiumLog";
        open(OUT, ">>$outfile");
        print OUT "$time $sender: $message\n";
    } else {
        $outfile = "$base_out/bad";
        open(OUT, ">>$outfile");
        print OUT "$input[$i]";
        print "Bad record found at line $i.  Logged in $base_out/bad.\n";
    }
    close OUT;
    
    ($hh, $mm, $ss) = $time =~ /(\d+):(\d+):(\d+)/;
    $modTime = timelocal($ss, $mm, $hh, $day, $month - 1, $year);
    utime time, $modTime, $outfile;
}
