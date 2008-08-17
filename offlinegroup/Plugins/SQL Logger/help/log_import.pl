#!/usr/bin/perl

# Jeffrey Melloy <jmelloy@visualdistortion.org>
# $URL: http://svn.visualdistortion.org/repos/projects/sqllogger/adium/log_import.pl $
# $Rev: 1046 $ $Date$
#
# Script will parse Adium logs >= 2.0 and put them in postgresql table.
# Table is created with "im.sql"
#
# If --verbose is passed, will print out name of every log file.
# If --no-vacuum, will not vacuum table at end (not recommended).
# if --quiet, will print nothing.

use warnings;
use strict;
use CGI qw(-no_debug escapeHTML);

my $vacuum = 1;
my $verbose = 1;
my $quiet = 0;
my $debug = 0;
my $status = 1;

my $username = $ENV{USER};

for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--verbose") {
        $verbose = 1;
    }

    if ($ARGV[$i] eq "--no-vacuum") {
        $vacuum = 0;
    }

    if ($ARGV[$i] eq "--quiet") {
        $quiet = 1;
    }

    if ($ARGV[$i] eq "--disable-status") {
        $status = 0;
    }
}

my $outtext;
open(OUT, "| psql >/dev/null") or die $!;

my $path = "$ENV{HOME}/Library/Application Support/Adium 2.0/Users/";
chdir "$path" or die qq{Path does not exist.};

foreach my $outer_user (glob '*') {
    chdir "$outer_user/Logs";
    foreach my $service_user (glob '*') {
        my $service;
        my $user;
        chdir "$service_user";
        print($service_user . "\n");
        $_ = $service_user;
        ($service, $user) = /(\w*).([\w\.\_\@\+\-]*)/;
        print OUT "insert into im.users (username, service, login) select
        \'$user\', \'$service\', true where not exists (select 'x' from
        im.users where username = \'$user\' and service = \'$service\');"
            or die qq{Could not insert login users: $!};

        foreach my $folder (glob '*') {
            !$quiet && print "\t" . $folder;
            chdir $folder;
            !$quiet && print "\t" . `ls -1 | wc -l`;
            my $counter = 0;
            foreach my $file (glob '*.adiumLog *.html') {
                $verbose && print "\t\t" . $file . "\n";
                if (++$counter % 50 == 0) {
                    !$quiet && print $counter . "\n";
                }

                my $date;
                my $recdName;
                my $sentName = $user;
                my $time;
                my $sender;
                my $receiver;
                my $message;

                $_ = $file;
                ($recdName, $date) = /([\w\@\.\_\+\-]*)\s.*(\d\d\d\d\|\d\d\|\d\d)/
                    or die "Unable to parse date in $file: $!";
                if(/adiumLog$/) {

                    undef $/;
                    open (FILE, $file) or die qq{Unable to open file "$file": $!};
                    my $content = <FILE>;
                    close(FILE);

                    unlink($file);

                    open(FFILE, ">>$file.bak") or die qq{Unable to open file "$file.bak": $!};

                    print FFILE $content;

                    close(FFILE);

                    $content = escapeHTML($content);
                    $content =~
                    s/\n((?!\(\d\d\:\d\d\:\d\d\)[\w\_\.\@\+\-]*\:|(\&lt\;\w*\s.*\d\d\:\d\d\:\d\d.*\&gt\;)))/<br>$1/g
                        or die qq{Could not split content: $!};

                    my @filecontents = split(/\n/, $content);

                    for (my $i = 1; $i < @filecontents; $i++) {

                        $_ = $filecontents[$i];

                        ($time, $sender) = /^\((\d\d\:\d\d\:\d\d)\)([\w\@\_\.\+\-]*)\:/
                            or ($time) = /^\&lt\;.*(\d\d\:\d\d\:\d\d)/
                            or die "Could not grab time and sender.  $file:\n$!";

                        if (/^\&lt\;.*\&gt\;/) {
                            $sender = $recdName;
                        }

                        if ($sender eq $sentName) {
                            $receiver = $recdName;
                        }
                        else {
                            $receiver = $sentName;
                        }

                        if(/\)[\w\@\_\.\+\-]*\:(.*)/) {
                            $message = $1;
                        } else {
                            $message = $_;
                        }

                        $message =~ s/\\/\\\\/g;
                        $message =~ s/\'/\\\'/g;

                        my $timestamp = $date . " " . $time;

                        my $query = "insert into im.message_v
                            (sender_sn, recipient_sn, message, message_date,
                            sender_service, recipient_service)
                            values
                            (\'$sender\',
                            \'$receiver\',
                            \'$message\',
                            \'$timestamp\',
                            \'$service\',
                            \'$service\');\n";

                        if($debug) {
                            print "$query";
                        }

                        $outtext .= $query;
                    }

                } elsif (/html$/) {

                    $/ = "</div>\n";

                    open (FILE, $file) or die qq{Unable to open file "$file": $!};
                    my @contents = <FILE>;
                    close(FILE);

                    open(FFILE, ">>$file.bak") or die qq{Unable to open file "$file.bak": $!};
                    foreach(@contents){
                        print FFILE $_;
                    }
                    close(FFILE);

                    for(my $i = 0; $i < @contents; $i++) {
                        my $message_type;

                        $_ = $contents[$i];

                        ($message_type, $message) =
                        /.*class\=\"(.*?)\"\>(.*)\<\/div\>/s;

                        if($message_type ne "status") {
                            ($message_type, $time, $sender, $message) =
                            /.*class\=\"(.*)\"\>.*?\"timestamp\"\>(\d\d\:\d\d\:\d\d).*?sender\"\>(.*)\:.*?message\"\>(.*)\<\/.*?\>\<\/div\>/s
                            or warn "$file:$_\n$!\n$i\n$contents[$i]";
                        } else {
                            $sender = $recdName;
                            $message = "&lt;" . $message . "&gt;";
                            ($time) = /.*(\d\d\:\d\d\:\d\d).*/;
                        }

                        $sender =~ s/\s//g;
                        $sender = lc($sender);

                        $message =~ s/\\/\\\\/g;
                        $message =~ s/\'/\\\'/g;

                        if ($sender eq $sentName) {
                            $receiver = $recdName;
                        }
                        else {
                            $receiver = $sentName;
                        }

                        my $timestamp = $date . " " . $time or die qq{bad date: $date $time};

                        my $query = "insert into im.message_v
                            (sender_sn, recipient_sn, message, message_date,
                            sender_service, recipient_service)
                            values (\'$sender\',
                            \'$receiver\',
                            \'$message\',
                            \'$timestamp\',
                            \'$service\',
                            \'$service\');\n";

                        if($debug) {
                            print $query;
                        }

                        if($status || $message_type ne "status") {
                            $outtext .= $query;
                        }
                    }
                }
                print OUT $outtext or die qq{$outtext};
                $outtext = "";

                unlink($file);

            }
            chdir "$path/$outer_user/Logs/$service_user";
        }
        chdir "$path/$outer_user/Logs/";
    }
    chdir $path;
}
print "Done with logs\n";

print OUT "insert into im.user_display_name (user_id, display_name,
effdate) select user_id, username, '-infinity' from im.users where not exists
(select 'x' from im.user_display_name where user_display_name.user_id =
users.user_id and user_display_name.effdate = '-infinity');\n";

print "Done inserting\n";
if ($vacuum) {
	print"Starting vacuum analyze\n";
    print OUT "vacuum analyze;\n";
}

close OUT;
