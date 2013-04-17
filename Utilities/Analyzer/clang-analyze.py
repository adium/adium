#!/usr/bin/python -Wi:tempnam
#
# clang-analyze.py
# written by Ryan Govostes (rgovostes@gmail.com) for the Adium project

import os
import re
import shutil
import subprocess
import sys

import reports

##
# Change these as you see fit.
##

analyzer_options = {
	"-checker-simple"				: False,	# Perform simple path-sensitive checks
	"-checker-cfref"				: True,		# Run the [Core] Foundation reference count checker
	"-warn-dead-stores"				: True,		# Warn about stores to dead variables
#	"-warn-uninit-values"			: False,	# Warn about uses of uninitialized variables (buggy?)
	"-warn-objc-methodsigs" 		: True,		# Warn about Objective-C method signatures with type incompatibilities
	"-warn-objc-missing-dealloc"	: True,		# Warn about Objective-C classes that lack a correct implementation of -dealloc
	"-warn-objc-unused-ivars"		: True,		# Warn about private ivars that are never used
}

build_configuration = "Debug"

##
# Some functions we'll be using...
##

def which(what, softfail = False):
	"""
	Calls the `which` program to look up the desired executable in the path. If
	it is not found, the function will look in the current working directory
	for an executable file of the name.
	
	If found, the absolute path to the program is returned. Otherwise, if the
	softfail argument is not set, the script terminates.
	"""
	
	try:
		subby = subprocess.Popen(["which", what], stdout = subprocess.PIPE)
		subby.wait()
		path = subby.stdout.read().rstrip()
	except:
		sys.exit("Failed to execute the `which` program.")
		
	if not path:
		# Check the current directory
		if os.path.isfile(what) and os.access(what, os.X_OK):
			path = os.path.realpath(what)
		elif not softfail:
			sys.exit("Could not locate the `%s` program." % what)
	
	return path

##
# Make sure we have clang and ccc-analyze.
##

missing = [ ]

if not which("clang", True):
	missing.append("Clang")

if not which("ccc-analyzer", True):
	missing.append("the ccc-analyzer script")

if len(missing) == 1:
	print >> sys.stderr, "Could not locate %s." % (missing[0])
elif len(missing) == 2:
	print >> sys.stderr, "Could not locate %s and %s." % (missing[0], missing[1])

if len(missing) > 0:
	sys.exit("""
Install the needed files in the Analyzer directory or anywhere in the path.
See <http://clang.llvm.org/StaticAnalysisUsage.html#Obtaining>.""")

##
# If Clang has been updated, we want to know about the available analysis
# options and warn the user if they've changed.
##

# Ask clang to print its usage help
subby = subprocess.Popen([which("clang"), "--help-hidden"], stdout = subprocess.PIPE)
subby.wait()

# Now we're going to look through and gather all of the analysis options
optpattern = re.compile("^    (-[^\s]+)(\s+- .*)$")
discovered_options = None

for line in subby.stdout:
	line = line.rstrip()
	
	# Look for the start marker
	if type(discovered_options) != dict:
		if line == "  Available Source Code Analyses:":
			discovered_options = { }
		continue
	
	# If we didn't match, we've gone beyond the analysis options
	option = optpattern.match(line)
	if option == None:
		break
		
	# Filter out some options we don't care about
	if option.group(1) == "-cfg-dump" or \
	   option.group(1) == "-cfg-view" or \
	   option.group(1) == "-dump-live-variables" or \
	   option.group(1) == "-warn-uninit-values":
		continue
	
	# Record the option
	discovered_options[option.group(1)] = option.group(2)

# Next we're going to see if we've set any options that don't exist
for opt in analyzer_options:
	if not opt in discovered_options:
		afterword = ""
		if analyzer_options[opt]:
			afterword = " (disabled)"
			analyzer_options[opt] = False
		print >> sys.stderr, "Analyzer option %s is not one that Clang understands%s." % (opt, afterword)

# And the other direction: are there any options we don't know about?
printedHeader = False
for opt in discovered_options:
	if not opt in analyzer_options:
		if not printedHeader:
			print "Clang supports the following options that are not used:"
			printedHeader = True
		print "\t%s%s" % (opt, discovered_options[opt])
if printedHeader:
	print
	
##
# Set up the Clang HTML output directory.
##

# Make sure the Adium.xcodeproj is here
adiumdir = os.path.realpath(os.path.join(os.pardir, os.pardir))
if not os.path.isdir(os.path.join(adiumdir, "Adium.xcodeproj")):
	print >> sys.stderr, "Could not locate Adium's Xcode project bundle. (You must run this script from the Analyzer directory.)"
	os.exit()
	
# Get the SVN revision number
revmatch = None
svnpath = which("svn", True)

if svnpath:
	subby = subprocess.Popen([svnpath, "info"], stdout = subprocess.PIPE)
	subby.wait()

	revmatch = re.search("Revision: ([0-9]+)", subby.stdout.read())

if not revmatch:
	print "Could not determine SVN revision of Adium source."
	revision = "Unknown"
else:
	revision = revmatch.group(1)
	
# Ask make to run so we can get some options from it. This is a cheat, relying
# on Adium's Makefile which reads the Xcode defaults to see if the user has
# specified a build directory.
#
# It does not, however, read the .pbxproj file to see if it has been changed.
# This would be a useful patch for the Makefile.
subby = subprocess.Popen(["make", "-p", "--dry-run", "-f" + os.path.join(adiumdir, "Makefile")], stdout = subprocess.PIPE)
(makeout, _) = subby.communicate()

# Get the build directory
buildmatch = re.search("BUILD_DIR = (.*)", makeout)
if not buildmatch:
	sys.exit("Could not determine the location of the Adium build directory.")
else:
	# This is a bit of a hack, but since we're one level deep, move up and then
	# back down
	savedcwd = os.getcwd()
	os.chdir(adiumdir)
	
	builddir = os.path.realpath(os.path.expanduser(buildmatch.group(1)))
	analyzerdir = os.path.join(builddir, "Analyzer")
	
	os.chdir(savedcwd)

# If the analyzer directory isn't available, we need to make it
if not os.path.isdir(analyzerdir):
	try:
		os.makedirs(analyzerdir)
	except:
		sys.exit("Could not create the build directory %s" % analyzerdir)
		
# Ensure we have write access
if not os.access(analyzerdir, os.W_OK):
	sys.exit("Cannot write to build directory %s" % analyzerdir)

# Now we're going to make a directory for this revision. We're going to rename
# the old version if it exists.
htmldir = os.path.join(analyzerdir, "r" + revision)
if os.path.exists(htmldir):
	oldhtmldir = htmldir + "-" + str(int(os.stat(htmldir).st_ctime))
	try:
		shutil.move(htmldir, oldhtmldir)
	except:
		sys.exit("Could not move previous output files out of the way.")
	
os.mkdir(htmldir)

##
# Set up the Clang environment. Most of the code in this section is adapted from
# Clang's scan-build script. Many of the comments are lifted from it.
##

# Start with our environment as it is and build on it
clangenv = { }
for key in os.environ:
	clangenv[key] = os.environ[key]

# Rather than use GCC, we will use ccc-analyzer, the GCC interceptor provided
# with Clang.
clangenv["CC"] = which("ccc-analyzer")

# We need to specify where Clang is
clangenv["CLANG"] = which("clang")

# This is the HTML directory to output to
clangenv["CCC_ANALYZER_HTML"] = htmldir

# These are the analyses to run, as set at the head of the file
analyses = ""
for opt in analyzer_options:
	if analyzer_options[opt]:
		analyses += opt + " "
clangenv["CCC_ANALYZER_ANALYSIS"] = analyses

# These are for debugging verbosity
clangenv["CCC_ANALYZER_VERBOSE"] = "1"
clangenv["CCC_ANALYZER_LOG"] = "1"
		
# When $CC is set, xcodebuild uses it to do all linking, even if we are linking
# C++ object files. Set $LDPLUSPLUS so that xcode uses `g++` when linking them.
clangenv["LDPLUSPLUS"] = which("g++")

##
# Construct the command we will use to build.
##

# Here's the basic command, based on the Adium Makefile
buildcmd = [which("xcodebuild"), "-project", "Adium.xcodeproj", "-configuration", build_configuration, "build"]

# Now add on some extra options, courtesy of the scan-build folks
buildcmd.append("-nodistribute")						# Disable distributed builds
buildcmd.append("GCC_PRECOMPILE_PREFIX_HEADER=NO")		# Disable PCH files until Clang supports them
#buildcmd.append("-PBXBuildsContinueAfterErrors=YES")	# Continue building even if a build error occurs

##
# Run the build
##

# To ensure that we get a complete build, we want to move the build
# configuration directory out of the way. If they interrupt the process,
# we have to move it back.
configdir = os.path.join(builddir, build_configuration)
needsRestore = os.path.exists(configdir)
if needsRestore:
	tempdir = os.tempnam(builddir, build_configuration + "-")
	try:
		shutil.move(configdir, tempdir)
	except:
		sys.exit("Could not move build files out of the way.")

# The following code has to be run in a try...except block so that if the user
# interrupts, we can revert changes.
interrupted = False
try:
	
	# This will start us going
	subby = subprocess.Popen(buildcmd, stdout = subprocess.PIPE, env = clangenv, cwd = os.path.join(os.getcwd(), os.pardir, os.pardir))
	print "Building Adium using %s configuration." % build_configuration
	
	sys.stdout.write("Waiting for static analysis to begin...")
	sys.stdout.flush()
	prevlen = len("Waiting for static analysis to begin...")
	
	# Read in each line of output to see if it's of interest to us
	pattern = re.compile("^ANALYZE\s*(.*?): (.*?\.[mc]) (.*)$")
	for line in subby.stdout:
		line = line.rstrip()
		match = pattern.match(line)
		if match:
			analysisBegun = True
			
			path = match.group(2)[len(adiumdir) + 1:]
			output = "Analyzing " + os.path.basename(path) + "..."
			
			lendiff = prevlen - len(output)
			if lendiff > 0:
				output = output + " " * lendiff + "\x08" * lendiff
			prevlen -= lendiff
			
			sys.stdout.write("\r" + output)
			sys.stdout.flush()

# Shut Python's default KeyboardInterrupt message up
except KeyboardInterrupt:
	interrupted = True
	pass
	
# Now whatever happened, we want to move the build directory back	
finally:
	# Print out our current status
	if interrupted:
		output = "User interrupted build process -- gracefully aborting."
	else:
		output = "Static analysis complete. "
		numreports = len(os.listdir(htmldir))
		if numreports == 0:
			output += "No reports generated."
		elif numreports == 1:
			output += "1 report generated."
		else:
			output += "%d reports generated." % numreports
	
	lendiff = prevlen - len(output)
	if lendiff > 0:
		output = output + " " * lendiff + "\x08" * lendiff
	print "\r" + output
	
	if needsRestore:
		try:
			if os.path.exists(configdir):
				shutil.rmtree(configdir)
			shutil.move(tempdir, configdir)
		except:
			print "Could not restore original build files from %s" % tempdir[len(adiumdir) + 1:]
	
	if interrupted:
		sys.exit()

##
# Postprocess the generated reports.
##

# Walk the report directory and parse stuff
if numreports > 0:
	output = "Post-processing reports..."
	prevlen = len("Post-processing reports...")
	sys.stdout.write(output)
	sys.stdout.flush()

	reportlist = [ ]
	for f in os.listdir(htmldir):
		pth = os.path.join(htmldir, f)
		
		if not os.path.isfile(pth) or not f.startswith("report-"):
			continue
		
		# Print what we're doing
		output = "Post-processing report %s" % f

		lendiff = prevlen - len(output)
		if lendiff > 0:
			output = output + " " * lendiff + "\x08" * lendiff
		prevlen -= lendiff

		sys.stdout.write("\r" + output)
		sys.stdout.flush()

		# Feed the file into the parser
		p = reports.ReportParser(adiumdir)
		fd = open(pth)
		p.feed(fd.read())
		fd.close()

		# Remember the reports
		p.report.reportfile = f
		reportlist.append(p.report)
		p.close()
		# time.sleep(0.2)

	output = "Done post-processing reports."
	lendiff = prevlen - len(output)
	if lendiff > 0:
		output = output + " " * lendiff + "\x08" * lendiff
	prevlen -= lendiff

	sys.stdout.write("\r" + output + "\n")
	sys.stdout.flush()

##
# Write out a property list that contains all of the report summaries. Later we
# can compare this with different summaries to see which problems are new.
##

print "Writing out Summary.plist file...",

# Open up the output file
outfile = open(os.path.join(htmldir, "Summary.plist"), "w")
outfile.write(reports.summaryPlistForReports(reportlist, revision))
outfile.close()
print "done."
