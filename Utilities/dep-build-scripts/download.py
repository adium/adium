#!/usr/bin/env python

"""
Downloader
by Peter Hosey

This is a multi-tasking file downloader with automatic unpacking. It uses curl to download files, and tar or unzip to unpack the files.

Usage: download.py [options] url url url ...

By default, the program will only download one file at a time. If you specify the -j option, it will download that many files at a time, except that it imposes an internal limit of one download per server (so as to not rudely swamp a single server with concurrent download requests).

You may also pass the -v option if you want to read debugging information.

After the options, the program takes one or more URLs to download. You can set up a pipe from the xargs utility if you would like to read URLs from a file.
"""

verbose = False
def debug_log(msg, *pieces):
	if not verbose: return

	import sys, os

	# Change pieces to be all but the last; it starts out being all but the first.
	all = ((msg,) + pieces)
	pieces, last = all[:-1], all[-1]

	print >>sys.stderr, os.getpid(),
	for x in pieces:
		print >>sys.stderr, x,
	print >>sys.stderr, last

def print_argv(argv):
	if verbose: print os.getpid(),
	print '>',
	for arg in argv: print arg,
	print

def strip_newlines(seq):
	for line in seq:
		if line.endswith('\n'):
			line = line[:-1]
		yield line

import optparse

# This doesn't go by URL alone because we don't want to let the user spawn 20 jobs that download from a single server. That would be rude to the server.
parser = optparse.OptionParser(usage='%prog [options] url [url [url ...]]')
parser.add_option('-f', '--input-file', help='file to read for URLs', default=None)
parser.add_option('-j', '--jobs', help='number of domains to download from at once', type='int', default=1)
parser.add_option('-v', '--verbose', help='print debug logging', default=False, action='store_true')

opts, args = parser.parse_args()
verbose = opts.verbose

if opts.input_file:
	input_file = open(opts.input_file, 'r')
	# Prepend the URLs from the file in front of the URLs from the command line.
	# Also, ignore comments in the file.
	args = [URL for URL in strip_newlines(input_file) if URL and not URL.startswith('#')] + args

download_urls = {} # Domain => [URL]

argvs = {
	'tar.gz':  ['tar', 'xz'],
	'tgz':     ['tar', 'xz'],
	'tar.bz2': ['tar', 'xj'],
	'tbz':     ['tar', 'xj'],
	'zip':     ['unzip'],
}
def argv_from_filename(filename):
	# Look through the extensions we know we can handle. Stop looking if we find the extension of this filename.
	chunks = filename.split('.')
	for range_len in xrange(1, len(chunks) + 1):
		# Join the last range_len chunks.
		ext = '.'.join(chunks[-range_len:])
		try:             argv = argvs[ext]
		except KeyError: pass
		else:
			# Include our filename as the last argument.
			# Remember to copy the list here, so we don't modify the list in the dictionary.
			argv = list(argv)
			if argv[0] != 'tar':
				argv.append(filename)
			return argv
known_extensions = set()
for key in argvs:
	# Add these extensions to the set by union.
	known_extensions.update(set(key.split('.')))

import os, sys
children = []

import urlparse
for url in args:
	parsed = urlparse.urlparse(url)

	# Find out whether this URL has already been downloaded and unpacked. If it has, ask the user whether we should clobber it (as in the case of an aborted download). We could just use tar -U, but letting the user answer no here saves bandwidth usage when redownloading isn't necessary.
	path = parsed.path
	filename = os.path.split(path)[1]
	chunks = filename.rsplit('.', 1) #For example: 'SurfWriter-1.0.tar', 'gz'
	while chunks[1] in known_extensions:
		chunks = chunks[0].rsplit('.', 1)
	else:
		#Last part isn't a filename extension. For example, it may be the 0 in 'SurfWriter-1.0'. Summon all the horses and all the king's men.
		dirname = '.'.join(chunks)

	if os.path.exists(dirname):
		# Note: We can't use raw_input here because it reads from stdin, and we may be running under xargs. We must use the terminal instead.
		tty = file('/dev/tty', 'r+')
		tty.write('%s already exists. Remove and redownload it? [yN] ' % (dirname,))
		tty.flush()
		answer = tty.readline()
		# lstrip: Remove leading whitespace.
		# [:1]: Get only the first character, returning empty (rather than raising IndexError) if the string is empty.
		# lower: Drop case of all (one) characters.
		if answer.lstrip()[:1].lower() == 'y':
			pid = os.fork()
			if pid > 0:
				children.append(pid)
			else:
				assert pid == 0
				dirname_old = dirname + '-old'
				os.rename(dirname, dirname_old)
				os.execvp('rm', ['rm', '-Rf', dirname_old])
		else:
			# Skip this URL by not adding it to download_urls.
			continue

	# netloc = domain[:port]. Split on the port number (if present) and get everything before it.
	domain = urlparse.urlparse(url).netloc.rsplit(':', 1)[0]
	download_urls.setdefault(domain, [])
	download_urls[domain].append(url)

import time
debug_log(download_urls)
for domain in download_urls:
	# If we have the maximum number of child processes already, wait for one to exit before spawning more.
	debug_log('children:', children)
	while len(children) >= opts.jobs:
		exited_pid, exit_status = os.waitpid(-1, os.WNOHANG)
		if exited_pid > 0:
			# A child exited! We can proceed.
			# Don't forget to remove it from the list of children, so we don't have to wait for it anymore.
			del children[children.index(exited_pid)]
			break
		time.sleep(1)

	child = os.fork()
	if child > 0:
		# We're the parent.
		children.append(child)
		# This sleep is mainly so the debug logs from different children don't collide.
		time.sleep(0.1)
		continue

	assert child == 0

	downloaded_files = set()

	urls = download_urls[domain]
	debug_log('URLs to download:', urls)
	for url in urls:
		curl_argv = ['curl', url]
		filename = os.path.split(urlparse.urlparse(url).path)[-1]
		tar_argv = argv_from_filename(filename)
		if tar_argv[0] != 'tar':
			tar_argv = None
			#Insert the -O option just before the URL, since we'll be saving the archive file to disk to pass to the unpacker.
			curl_argv.insert(3, '-O')
		whole_argv = (curl_argv + ['|'] + tar_argv) if tar_argv else curl_argv
		print_argv(whole_argv)

		pid = os.fork()
		if pid == 0:
			# We are the child, which will become curl or tar.
			read_end, write_end = os.pipe() if tar_argv else (None, None)

			curl_pid = os.fork()
			assert curl_pid >= 0
			if curl_pid == 0:
				if write_end is not None: os.dup2(write_end, sys.stdout.fileno())
				os.close(read_end)
				# We are the grandchild that will become curl.
				os.execvp(curl_argv[0], curl_argv)

			if not tar_argv:
				tar_pid = None
			else:
				tar_pid = os.fork()
				assert tar_pid >= 0
				if tar_pid == 0:
					# We are the grandchild that will become tar.
					os.dup2(read_end, sys.stdin.fileno())
					os.close(write_end)
					os.execvp(tar_argv[0], tar_argv)

			# Only the grandchildren need the pipe. Close our copies of both ends of it.
			os.close(read_end)
			os.close(write_end)

			# We're still the child; wait for the grandchildren to exit.
			exited_pid, curl_exit_status = os.waitpid(curl_pid, 0)
			if tar_pid is None:
				tar_exit_status = 0 # for sys.exit below
			else:
				exited_pid, tar_exit_status = os.waitpid(tar_pid, 0)

			if curl_exit_status:
				print >>sys.stderr, 'curl exited with status', curl_exit_status
				sys.exit(curl_exit_status if curl_exit_status else tar_exit_status)
			if tar_exit_status:
				print >>sys.stderr, 'tar exited with status', tar_exit_status
			sys.exit(tar_exit_status)

		assert pid > 0
		exited_pid, exit_status = os.waitpid(pid, 0)
		if exit_status == 0:
			if not tar_argv:
				# We need to unzip this, so add it to the set of filenames to invoke unzip for.
				# The filename is the last component of the pathname.
				downloaded_files.add(url.rsplit('/', 1)[1])

	debug_log('Files to unpack:', list(downloaded_files))
	if downloaded_files:
		# Unpack all the files.

		# It's now more convenient to have this as a sequence than a set.
		downloaded_files = list(downloaded_files)

		# Use spawnvp (which creates a new process) for all but the last.
		for filename in downloaded_files[:-1]:
			debug_log('Unpacking file:', filename)
			argv = argv_from_filename(filename)
			if argv:
				print_argv(argv)
				os.spawnvp(os.P_WAIT, argv[0], argv)
			else:
				print >>sys.stderr, 'Unrecognized or no extension on filename:', filename
		else:
			filename = downloaded_files[-1]
			# Use execvp (which reuses this process) for the last.
			debug_log('Unpacking file:', filename)
			argv = argv_from_filename(filename)
			if argv:
				print_argv(argv)
				os.execvp(argv[0], argv)
			else:
				print >>sys.stderr, 'Unrecognized or no extension on filename:', filename
	else: #if not downloaded_files:
		# If no files were successfully downloaded, then we're not going to exec to an unpacker. Exit, so we don't leak this child process (particularly because if we do, it will go do a bunch of duplicate downloading).
		# We exit with status 1 because we must have had at least one URL to download to even get here, but none of our URLs worked.
		sys.exit(1)

# Clean up all our child processes.
exit_status = 0
for child in children:
	exited_pid, tmp_exit_status = os.waitpid(child, 0)
	if tmp_exit_status != 0:
		exit_status = tmp_exit_status
sys.exit(exit_status)
