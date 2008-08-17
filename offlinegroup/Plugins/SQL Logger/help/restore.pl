#!/usr/bin/perl

use warnings;
use strict;

$| = 0;
print "1.6 Logs ";
my $path = "$ENV{HOME}/Library/Application Support/Adium/Users/";
chdir $path;
foreach my $user (glob '*') {
    chdir "$user/Logs";
    foreach my $folder (glob '*') {
        chdir $folder;
        foreach my $file (glob '*.bak') {
            my $return = $file;
            $return =~ s/.bak$//;

            system("mv", $file, $return);
        }
        chdir "$path/$user/Logs";
    }
    print " .";
    chdir $path;
}
print " Done.\n";

print "2.0 Logs ";
$path = "$ENV{HOME}/Library/Application Support/Adium 2.0/Users/";
chdir "$path";
foreach  my $account (glob '*') {
    chdir "$account/Logs" or die;
    foreach my $user (glob '*') {
        chdir "$user" or die qq{Bad user $user};
        foreach my $folder (glob '*') {
            chdir $folder or die;
            foreach my $file (glob '*.bak') {
                my $return = $file;
                $return =~ s/.bak$//;

                system("mv", $file, $return);
            }
            chdir ".." or die;
        }
        print " .";
        chdir ".." or die;
    }
    chdir "$path" or die;
}
print " Done.\n";
