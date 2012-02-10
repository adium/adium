#!/usr/bin/python

import os.path
import plistlib
import sys

import reports

# Print the usage text if needed
if len(sys.argv) != 3:
	print "Usage: python compare-summaries.py Summary1.plist Summary2.plist"
	sys.exit()

# Read in the files they named
infileA = open(sys.argv[1], "r")
dataA = infileA.read()
infileA.close()

infileB = open(sys.argv[2], "r")
dataB = infileB.read()
infileB.close()

# Get dictionaries for both
dictA = plistlib.readPlistFromString(dataA)
dictB = plistlib.readPlistFromString(dataB)

# Which is older? Use that as the left comparison
if (dictA["Revision"] == "Unknown" or dictB["Revision"] == "Unknown") \
   or (dictA["Revision"] == dictB["Revision"]):
	if dictA["Timestamp"] < dictB["Timestamp"]:
		leftDict = dictA
		rightDict = dictB
	else:
		rightDict = dictA
		leftDict = dictB
else:
	if int(dictA["Revision"]) < int(dictB["Revision"]):
		leftDict = dictA
		rightDict = dictB
	else:
		rightDict = dictA
		leftDict = dictB

# This is inefficient, but who cares. Get reports for each
leftReports  = reports.summaryPlistToReports(plistlib.writePlistToString(leftDict))
rightReports = reports.summaryPlistToReports(plistlib.writePlistToString(rightDict))

# Try to pair up reports
recurringBugs = 0
newBugs = 0

for r in rightReports:
	found = False
	
	for l in leftReports:
		if l == r:
			found = True
			break
	
	if found:
		recurringBugs += 1
	else:
		newBugs += 1

print "%i recurring bugs" % recurringBugs
print "%i new bugs" % newBugs
print "%i fixed bugs" % (len(leftReports) - recurringBugs)