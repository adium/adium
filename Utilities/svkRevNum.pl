#!/usr/bin/perl

use strict;

my $dirToFigure = ".";
my $line;
my @currentDirInfo;
my $depot;
my @mirrorPaths;
my $mirrorPath;
my $currentRev;
my $upstreamRev = 0;
my @mirrorDirInfo;
my $isMirrorDir = 0;
my $foundMirror=0;

$dirToFigure = $ARGV[0] if (scalar(@ARGV) > 0);
@currentDirInfo = `svk info $dirToFigure`;


foreach $line (@currentDirInfo) {
	if ($line =~ m%Depot Path: /([^/]*)/.*%) {
		$depot = $1;
	}
	if ($line =~ m%Revision: ([0-9]*)%) {
		$currentRev = $1;
	}
	if ($line =~ m%Merged From: (/.*), Rev. ([0-9]*)%) {
		if ( $upstreamRev == 0 || $2 > $upstreamRev ) {
			push(@mirrorPaths,$1);
			$upstreamRev = $2;
		}
	}
}

foreach $mirrorPath (@mirrorPaths) {
	if ($foundMirror == 0) {
		@mirrorDirInfo = `svk info /$depot/$mirrorPath`;
		foreach $line (@mirrorDirInfo) {
			if ($line =~ m%Mirrored From:%) {
				$isMirrorDir = 1;
			}
		}
		
		if ($isMirrorDir) {
			@mirrorDirInfo = `svk log -r $upstreamRev /$depot/$mirrorPath`;
			foreach $line ( @mirrorDirInfo ) {
				if ($line =~ m/r[0-9].*orig r([0-9]*).*/) {
					$upstreamRev = $1;
					$foundMirror=1;
				}
			}
		}
	}
}

print $upstreamRev . ", r" . $currentRev ."@".`hostname | sed 's/.local//'`;
