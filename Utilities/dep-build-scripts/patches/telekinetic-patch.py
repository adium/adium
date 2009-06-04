#!/usr/bin/python

import os
import re
import sys
import subprocess

# Read in the patch
patch = sys.stdin.read()

# Do a dry run to see what would be dirtied
cmd = ["patch", "--dry-run", "-f"] + sys.argv[1:]
subby = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
subby.stdin.write(patch)
subby.stdin.close()
subby.wait()

dirtied = re.findall("^patching file (.*)$", subby.stdout.read(), re.IGNORECASE | re.MULTILINE)
del subby

# Get modified times for everything
times = { }
for fi in dirtied:
	statinfo = os.stat(fi)
	times[fi] = (statinfo.st_atime, statinfo.st_mtime)

# Now perform the actual patch
cmd = ["patch"] + sys.argv[1:]
subby = subprocess.Popen(cmd, stdin=subprocess.PIPE)
subby.stdin.write(patch)
subby.stdin.close()
subby.wait()
del subby

# Revert the modified times
for fi in times:
	os.utime(fi, times[fi])
