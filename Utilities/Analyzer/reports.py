import datetime
import plistlib
import re
import sgmllib

class Report(list):
	type = ""
	reportfile = ""
	sourcefile = ""
	endpathline = 0
	
	def append(self, something):
		# We don't want anything but ReportItems
		if not isinstance(something, ReportItem):
			raise TypeError
		else:
			list.append(self, something)
	
	def __eq__(self, other):
		# This is where we'll implement our logic for deciding whether or not
		# two reports refer to the same issue.
		
		# They must be in the same source file
		if self.sourcefile != other.sourcefile:
			return False
		
		# They have to have to be of the same type
		if self.type != other.type:
			return False
		
		# They should have the same path length
		if len(self) != len(other):
			return False
			
		# Compare each item in the reports
		for i in range(0, len(self)):
			
			# The lines should be within (drumroll for magic number)
			if abs(self[i].line - other[i].line) > 20:
				return False
			
			# The comments should be the same, line numbers notwithstanding
			commentA = re.sub("line [0-9]+", "xxx", self[i].comment)
			commentB = re.sub("line [0-9]+", "xxx", other[i].comment)
			if commentA != commentB:
				return False
		
		return True
	
	def __ne__(self, other):
		# If we don't define this, we can have the case that a == b and a != b
		return not self.__eq__(other)
	

class ReportItem:
	# This needs to be expanded, for instance to know about the function that
	# the error resides in.
	line = 0
	comment = ""

class ReportParser(sgmllib.SGMLParser):
	_endPath = False
	_record = False
	_buffer = ""
	_queue = [ ]
	_pathprefix = ""
	
	def __init__(self, pathprefix = ""):
		sgmllib.SGMLParser.__init__(self)
		self._pathprefix = pathprefix
		self.report = Report()
	
	def handle_comment(self, comment):
		comment = comment.strip()
		
		# We can get BUGFILE and BUGDESC from comments
		if comment.startswith("BUGFILE"):
			bugfile = comment[8:]
			if bugfile.startswith(self._pathprefix):
				bugfile = bugfile[len(self._pathprefix) + 1:]
			self.report.sourcefile = bugfile
			
		elif comment.startswith("BUGDESC"):
			self.report.type = comment[8:].lower()
	
	def start_td(self, attrs):
		attrs = dict(attrs)
		
		# Read in a line number
		if "class" in attrs and attrs["class"] == "num" and \
		   "id" in attrs and attrs["id"][:2] == "LN":
			linenum = int(attrs["id"][2:])
			
			# Add a report if we're ready
			while len(self._queue) > 0:
				ri = ReportItem()
				ri.line = linenum
				ri.comment = self._queue.pop(0)
				self.report.append(ri)
				
			if self._endPath:
				self._endPath = False
				self.report.endpathline = linenum
	
	def start_div(self, attrs):
		attrs = dict(attrs)
		
		# Is this a message?
		if "class" in attrs and attrs["class"] == "msg":
			self._record = True
			self._buffer = ""
			
			if "id" in attrs and attrs["id"] == "EndPath":
				self._endPath = True
	
	def end_div(self):
		if self._record:
			self._queue.append(self._buffer)
			self._record = False
			self._buffer = ""
	
	def handle_data(self, data):
		if self._record:
			self._buffer += data
	

def summaryPlistForReports(reports, revision = "Unknown"):
	summary = {
		"Timestamp"	: datetime.datetime.utcnow(),
		"Revision"	: str(revision),
		"Reports"	: [ ],
	}
	
	for r in reports:
		summary["Reports"].append({
			"Bug Type"				: r.type,
			"Report File"			: r.reportfile,
			"Source File"			: r.sourcefile,
			"End Path Line Number"	: r.endpathline,
			"Path"					: [ ],
		})
		
		for i in r:
			summary["Reports"][-1]["Path"].append({
				"Line Number"	: i.line,
				"Comment"		: i.comment,
			})
	
	return plistlib.writePlistToString(summary)

def summaryPlistToReports(data):
	summary = plistlib.readPlistFromString(data)
	reports = [ ]
	
	# Read in each report
	for x in summary["Reports"]:
		report = Report()
		report.type = x["Bug Type"]
		report.reportfile = x["Report File"]
		report.sourcefile = x["Source File"]
		report.endpathline = x["End Path Line Number"]
		
		for y in x["Path"]:
			item = ReportItem()
			item.line = y["Line Number"]
			item.comment = y["Comment"]
			report.append(item)
		
		reports.append(report)
	
	return reports

if __name__ == "__main__":
	print "This file should not be invoked directly."