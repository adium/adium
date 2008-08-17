#!/usr/bin/perl

# This script converts Proteus logs to Adium ones.
#
# It will create a folder with your username that you can drop into Adium's
# log folder or copy the contents.
#
# Run it by doing "./proteus2adium.pl"

use warnings;
use strict;

my $proteus_log_file = "$ENV{HOME}/Library/Application Support/Proteus/Profile/History.db";

my $user_name;
my @service_type;
my $base_out;

my @messages;

# Proteus makes a table for each service, let's get them.

my $query = ".tables";

open( QUERYPIPE, './sqlite "' . $proteus_log_file . '" "' . $query . '" |' ) or die "Could not open the pipe: $!";

while(<QUERYPIPE>) {
    chomp;
    @service_type = split(' ');
}

# The proteus tables are dumb.
# the schema for each is:
# identifier TEXT, (the username)
# date text,
# message text,
# incoming int,
# type int,
# url text
#
# I'm not actually sure what type and URL are for.
# Type seems to always be 1, and URL seems to always be empty.

foreach my $service (@service_type) {
    print "Please enter the username for $service: ";
    $user_name = <STDIN>;
    chomp($user_name);
    $base_out = $service . "." . $user_name;

    $query = "select substr(date, 0, 10), identifier, \'<div class=\\\"\' || case when incoming=1 then \'receive\' else \'send\' end || \'\\\"><span class=\\\"timestamp\\\">\' || substr(date, 12, 8) || \'</span><span class=\\\"sender\\\">\' || case when incoming = 1 then identifier else \'$user_name\' end || \': </span><pre class=\\\"message\\\">\' || message || \'</pre></div>\' from \\\"$service\\\"";

    open( QUERYPIPE, './sqlite "' . $proteus_log_file . '" "' . $query . '" |' ) or die "Could not open the pipe: $!";

    umask(000);

    # make sure the basic output dir exists
    mkdir($base_out, 0777) unless (-d $base_out);

    my $history_line = '';

    while ( <QUERYPIPE> )
    {
        chomp;

        # some of the records coming from the proteus logs are multi-line
        # so we build $history_line by appending the record to it
        $history_line .= $_;

        # if the pattern matches, we have the whole record
        if ( $history_line =~ /(\d*)-(\d*)-(\d*)\|(.*)\|(<div.*<\/div>)/s )
        {
            my ($year, $month, $day, $ident, $message) = ($1, $2, $3, $4, $5);

            #make sure the output dir exists for the current contact
            mkdir( "$base_out/$ident/", 0777 ) unless ( -d "$base_out/$ident" );

            my $output_file = "$base_out/$ident/$ident ($year|$month|$day).html";
            open( OUTFILE, ">>$output_file" ) or die( "Could not open output file $output_file: $!" );

            print OUTFILE "$message\n";

            close OUTFILE or warn( "Could not close the output file $output_file: $!" );

            # clear history_line in preparation for the next record
            $history_line = '';
        }
        else
        {
            # adium uses <BR> to separate lines instead of \n
            $history_line .= "<BR>";
        }
    }
}
