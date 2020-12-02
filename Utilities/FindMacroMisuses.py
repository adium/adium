#!/usr/bin/env python

"Searches the code base, starting from the current working directory, for defined macros being used inside quotes."

import optparse
parser = optparse.OptionParser(description=__doc__)
opts, args = parser.parse_args()

import subprocess
from subprocess import PIPE

# Find all macro definitions.
grep = subprocess.Popen(['grep', '-RhF', '#define', 'Frameworks', 'Plugins', 'Source', '--include=*.[hmc]'], stdout=PIPE)
# Extract the macro name.
sed = subprocess.Popen(['sed', '-nE', 's/^#define[ \\t]*([A-Za-z_0-9]+)[ \\t]*.*/\\1/p'], stdin=grep.stdout, stdout=PIPE)
# Reduce to one instance of each macro name.
sort = subprocess.Popen(['sort'], env={ 'LC_ALL': 'C' }, stdin=sed.stdout, stdout=PIPE)
uniq = subprocess.Popen(['uniq'], env={ 'LC_ALL': 'C' }, stdin=sort.stdout, stdout=PIPE)

# I tried both grep and the re module for searching for quoted macros, but the resulting regular expression is too long. --boredzo
macros_in_quotes = ['"%s"' % (line.rstrip('\n'),) for line in uniq.stdout]

import itertools
import os
for (directory, dirnames, filenames) in itertools.chain(os.walk('Frameworks'), os.walk('Plugins'), os.walk('Source')):
	if '.svn' not in dirnames:
		del dirnames[:]
	else:
		del dirnames[dirnames.index('.svn')]
		for fn in filenames:
			if os.path.splitext(fn)[-1] in ['.m', '.c', '.h']:
				path = os.path.join(directory, fn)
				for i, line in enumerate(open(path, 'r')):
					if line.startswith('#define'):
						continue
					for quoted_macro in macros_in_quotes:
						if quoted_macro in line:
							print '%s:%u:%s' % (path, i + 1, line.rstrip('\n'))
