#!/usr/bin/env python

"""
Usage:
AppcastReplaceItem <path-to-appcast> <old-version> <new-version> <path-to-dmg>

Example: AppcastReplaceItem appcast-release.xml 1.1.4 1.2 Release/build/Adium_1.2.dmg
"""

# Configurable variables.
app_name = 'Adium'
changelog_fmt = 'http://www.adium.im/changelogs/%(version)s.html'
enclosure_fmt = '        <enclosure sparkle:md5Sum="%(md5)s" sparkle:version="%(version)s" url="%(url)s" length="%(file_size)s" type="application/octet-stream"/>\n'
# End of configurable variables.

import xml.etree.cElementTree as ElementTree
import sys
import os
import time
import subprocess
from stat import *

args = dict(zip(('appcast_path', 'old_version', 'version', 'dmg_pathname'), sys.argv[1:]))
try:
	appcast_path = args['appcast_path']
	old_version  = args['old_version']
	version      = args['version']
	dmg_pathname = args['dmg_pathname']
except KeyError:
	sys.exit(__doc__.strip())
else:
	args['app_name'] = app_name

	# Get the length and modification time of the dmg file.
	sb = os.stat(dmg_pathname)
	file_size = args['file_size'] = sb[ST_SIZE]
	dmg_mod_time = time.localtime(sb[ST_MTIME])

	# Suffix for the day of the month.
	th = (['st', 'nd', 'rd'] + ['th'] * 7) * 4

	# GMT offset in hours.
	gmt_offset = '%+i' % (-int(time.timezone / 3600),)

	# Format, which we must fill in with the above items first.
	time_fmt = '%A, %B %dth, %Y %H:%M:%S GMT+0'.replace('th', th[dmg_mod_time.tm_mday - 1]).replace('+0', gmt_offset)
	dmg_mod_date = args['dmg_mod_date'] = time.strftime(time_fmt, dmg_mod_time)

	openssl_md5 = subprocess.Popen(['openssl', 'md5', dmg_pathname], stdout=subprocess.PIPE)
	# Skip the prefix
	openssl_md5.stdout.read(len('MD5(') + len(dmg_pathname) + len(')= '))
	md5 = args['md5'] = openssl_md5.stdout.read().strip()
	exit_status = openssl_md5.wait()
	if exit_status != 0: sys.exit('openssl md5 exited with status ' + str(exit_status))
	# An MD5 hash is 16 bytes, which is 32 digits hexadecimal.
	assert len(md5) == 32, 'MD5 sum is %u bytes' % (len(md5),)

	dmg_filename = os.path.split(dmg_pathname)[1]
	url = args['url'] = 'http://adiumx.cachefly.net/' + dmg_filename

# Because XML parsing with the standard library is a PITA, we're going to do it the hackish way.
xmlfile = file(appcast_path)
lines = []
is_in_item = False
is_correct_item = False
found_correct_item = False
for line in xmlfile:
	if not is_in_item:
		if '<item>' in line:
			is_in_item = True
	else:
		if '</item>' in line:
			is_in_item = False
			is_correct_item = False
		elif '<title>' in line:
			if '>%(app_name)s %(old_version)s<' % args in line:
				line = line.replace(old_version, version)
				is_correct_item = found_correct_item = True
		elif is_correct_item:
			if'<pubDate>' in line:
				line = '        <pubDate>%(dmg_mod_date)s</pubDate>\n' % args
			elif '<sparkle:releaseNotesLink>' in line:
				line = '        <sparkle:releaseNotesLink>%s</sparkle:releaseNotesLink>\n' % (changelog_fmt % args,)
			elif '<enclosure' in line:
				line = enclosure_fmt % args
	lines.append(line)

if not found_correct_item:
	sys.exit('No item found for version %(old_version)s' % args)

xmlfile = file(appcast_path, 'w')
xmlfile.writelines(lines)
