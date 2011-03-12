#!/usr/bin/env perl
#
# Trivial script to anonymize Adium debug logs.  It's a hack, and was
# put together with little time or effort.  I'm sure that it could be
# made better, if someone cared enough to do so.

# 29 Dec 2007: Minor updates / fixes (e.g., add libpurple into search
# strings instead of libgaim).

# 29 Apr 2007: This script works for all the data in the log that I
# need to submit; I'm quite sure that it is *not* comprehensive.  I
# only anonymized AIM, Jabber, and Sametime data that I found in my
# log; there is no support for the other protocols, and I'm guessing
# that this script won't anonymize *all* data from AIM/Jabber/Sametime
# -- just the stuff that I found in my log.

use strict;

# Get the filename
my $filename = $ARGV[0];
if (! $filename) {
    print "Usage: $0 <filename>\n";
    exit(1);
}

# Do the work
print "Anonymizing...\n";
my $temp = "ANONYMIZE_TEMP_REPLACE_SENTINEL_STRING";
my $contents = read_file($filename);
replace_aim_names($contents);
replace_sametime_names($contents);
replace_jabber_names($contents);
replace_group_names($contents);
replace_accounts($contents);
replace_uids($contents);
replace_dns($contents);
replace_email($contents);
write_file("$filename.anonymous", $contents);

# All done
exit(0);

###########################################################################

sub read_file {
    my $filename = shift;
    my $contents;
    open (F, $filename) || die "Cannot open $filename";
    $contents .= $_
        while (<F>);
    close(F);
    \$contents;
}

###########################################################################

sub replace_accounts {
    my $contents = shift;
    my $account_index = 1;
    while ($$contents =~ m/connecting to account (.+)$/im) {
        my $account_name = $1;
        my $replace_str = "ACCOUNT_#$account_index";
        print "Found account: $account_name -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/connecting to account $account_name$/$temp $replace_str/igm;
        # Replace with the anonymized string everywhere else, too
        $$contents =~ s/$account_name/$replace_str/gm;
        ++$account_index;
    }

    # Put the original string back
    $$contents =~ s/$temp/connecting to account/gm;
}

###########################################################################

sub replace_uids {
    my $contents = shift;
    my $uid_index = 1;
    while ($$contents =~ m/created PurpleAccount 0x[0-9a-f]+ with uid (.+),/im) {
        my $uid = $1;
        if ($uid !~ /^ACCOUNT_#/) {
            my $replace_str = "UID_#$uid_index";
            print "Found UID: $uid -> $replace_str\n";
            # Put in a sentinel string so that we don't find it again
            $$contents =~ s/with uid $uid/$temp $replace_str/igm;
            # Replace with the anonymized string everywhere else, too
            $$contents =~ s/$uid/$replace_str/gm;
            ++$uid_index;
        } else {
            $$contents =~ s/with uid $uid/$temp $uid/igm;
        }
    }

    # Put the original string back
    $$contents =~ s/$temp/with UID/gm;
}

###########################################################################

sub replace_dns {
    my $contents = shift;
    my $dns_index = 1;
    while ($$contents =~ m/dns query for '(.+)' queued$/im) {
        my $ip_name = $1;
        my $name_replace_str = "IP_NAME_#$dns_index";
        my $addr_replace_str = "IP_ADDRESS_#$dns_index";
        print "Found DNS name: $ip_name -> $name_replace_str\n";

        # Is the name an IP address already?
        my $ip_address;
        if ($ip_name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
            $ip_address = $ip_name;
            print "DNS name already resolved: $ip_address\n";
        }

        # Nope, not already resolved.  Find the corresponding resolved
        # IP address
        else {
            if ($$contents =~ m/ip resolved for $ip_name\n\d\d:\d\d:\d\d: \(libpurple: proxy\) attempting connection to (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i ||
                $$contents =~ m/ip resolved for $ip_name\n\d\d:\d\d:\d\d: \(lbigaim: proxy\) attempting connection to (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i) {
                $ip_address = $1;
                print "Found corresponding IP address: $ip_name -> $ip_address -> $addr_replace_str\n";
            }
        }

        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/dns query for '$ip_name' queued$/$temp '$name_replace_str' queued/igm;
        # Replace with the anonymized strings everywhere else, too
        $$contents =~ s/$ip_name/$name_replace_str/gm;
        $$contents =~ s/$ip_address/$addr_replace_str/gm
            if ($ip_address);
        ++$dns_index;
    }

    # Put the original string back
    $$contents =~ s/$temp/DNS query for/gm;
}

###########################################################################

sub replace_email {
    my $contents = shift;
    my $email_index = 1;
    while ($$contents =~ m/ E-mail: (.+)$/im) {
        my $email = $1;
        my $replace_str = "EMAIL_#$email_index";
        print "Found Email: $email -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ E-mail: $email$/ $temp $replace_str/gm;
        ++$email_index;
    }
    while ($$contents =~ m/ Email: (.+)$/im) {
        my $email = $1;
        my $replace_str = "EMAIL_#$email_index";
        print "Found Email: $email -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ Email: $email$/ $temp $replace_str/gm;
        ++$email_index;
    }

    # Put the original string back
    $$contents =~ s/$temp/E-mail:/gm;
}

###########################################################################

sub replace_aim_names {
    my $contents = shift;
    my $aim_name_index = 1;
    while ($$contents =~ m/ AIM\.(\w+)/im) {
        my $aim_name = $1;
        my $replace_str = "AIM_ID_#$aim_name_index";
        print "Found AIM ID: $aim_name -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ AIM\.$aim_name/ $temp.$replace_str/igm;
        # Replace with the anonymized strings everywhere else, too
        $$contents =~ s/(\W)$aim_name(\W)/\1$replace_str\2/igm;
        ++$aim_name_index;
    }

    # Put the original string back
    $$contents =~ s/$temp/AIM/gm;
}

###########################################################################

sub replace_sametime_names {
    my $contents = shift;
    my $st_index = 1;
    while ($$contents =~ m/ Sametime\.uid=(.+?)>/im) {
        my $st_name = $1;
        my $replace_str = "SAMETIME_ID_#$st_index";
        print "Found Sametime ID: $st_name -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ Sametime\.uid=$st_name/ $temp$replace_str/igm;
        # Replace with the anonymized strings everywhere else, too
        $$contents =~ s/(\W)uid=$st_name(\W)/\1$replace_str\2/igm;
        ++$st_index;
    }

    # Put the original string back
    $$contents =~ s/ $temp/ Sametime.uid=/gm;
}

###########################################################################

sub replace_jabber_names {
    my $contents = shift;
    my $jabber_index = 1;
    while ($$contents =~ m/ jabber\.(.+?)>/im) {
        my $jabber_name = $1;
        my $replace_str = "JABBER_ID_#$jabber_index";
        print "Found Jabber ID: $jabber_name -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ Jabber\.$jabber_name/ $temp$replace_str/igm;
        # Replace with the anonymized strings everywhere else, too
        $$contents =~ s/(\W)$jabber_name(\W)/\1$replace_str\2/igm;
        ++$jabber_index;
    }

    # Put the original string back
    $$contents =~ s/ $temp/ Jabber./gm;
}

###########################################################################

sub replace_group_names {
    my $contents = shift;
    my $group_index = 1;
    while ($$contents =~ m/ Group\.(.+?)>/im) {
        my $group_name = $1;
        my $replace_str = "GROUP_ID_#$group_index";
        print "Found Group ID: $group_name -> $replace_str\n";
        # Put in a sentinel string so that we don't find it again
        $$contents =~ s/ Group\.$group_name/ $temp$replace_str/igm;
        # Replace with the anonymized strings everywhere else, too
        $$contents =~ s/(\W)$group_name(\W)/\1$replace_str\2/igm;
        ++$group_index;
    }

    # Put the original string back
    $$contents =~ s/ $temp/ Group./gm;
}

###########################################################################

sub write_file {
    my ($filename, $contents) = @_;

    open (F, ">$filename") || die("Cannot open output file $filename");
    print F $$contents;
    close(F);
}

