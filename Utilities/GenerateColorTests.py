#!/usr/bin/env python

"This program generates the implementations of the test methods for +colorWithHTMLString:."

import sys
#Iterators are our friends.
from itertools import izip as zip

prototype = '- (void)testColorWith%(num_digits)uDigitHTMLStringFor%(color)s%(case)scase'
declaration = prototype + ';'
implementation = prototype + """
{
	NSString *string = @"%(html_string)s";
	NSColor *%(color_lowercase)s = [NSColor colorWithHTMLString:string];
	STAssertEquals([%(color_lowercase)s   redComponent], %(red)sf,   @"Red component of %(color_human_readable)s should be %(red)s");
	STAssertEquals([%(color_lowercase)s greenComponent], %(green)sf, @"Green component of %(color_human_readable)s should be %(green)s");
	STAssertEquals([%(color_lowercase)s  blueComponent], %(blue)sf,  @"Blue component of %(color_human_readable)s should be %(blue)s");
!!! Alpha 1 line
	STAssertEquals([%(color_lowercase)s alphaComponent], %(alpha)sf, @"Alpha component of %(color_human_readable)s should be %(alpha)s");
}\
"""

color_names_to_rgba = {
	# Alpha = 1
	'Red':     (1.0, 0.0, 0.0, 1.0),
	'Yellow':  (1.0, 1.0, 0.0, 1.0),
	'Green':   (0.0, 1.0, 0.0, 1.0),
	'Cyan':    (0.0, 1.0, 1.0, 1.0),
	'Blue':    (0.0, 0.0, 1.0, 1.0),
	'Magenta': (1.0, 0.0, 1.0, 1.0),
	'White':   (1.0, 1.0, 1.0, 1.0),
	'Black':   (0.0, 0.0, 0.0, 1.0),
	# Alpha = 0
	'TransparentRed':     (1.0, 0.0, 0.0, 0.0),
	'TransparentYellow':  (1.0, 1.0, 0.0, 0.0),
	'TransparentGreen':   (0.0, 1.0, 0.0, 0.0),
	'TransparentCyan':    (0.0, 1.0, 1.0, 0.0),
	'TransparentBlue':    (0.0, 0.0, 1.0, 0.0),
	'TransparentMagenta': (1.0, 0.0, 1.0, 0.0),
	'TransparentWhite':   (1.0, 1.0, 1.0, 0.0),
	'TransparentBlack':   (0.0, 0.0, 0.0, 0.0),
}
color_names = (
	'Red',
	'Yellow',
	'Green',
	'Cyan',
	'Blue',
	'Magenta',
	'White',
	'Black',
)
transparent_color_names = (
	'TransparentRed',
	'TransparentYellow',
	'TransparentGreen',
	'TransparentCyan',
	'TransparentBlue',
	'TransparentMagenta',
	'TransparentWhite',
	'TransparentBlack',
)

# Make sure we're not missing any from either set.
all_color_names = set(color_names + transparent_color_names)
if all_color_names != set(color_names_to_rgba):
	# List both sets and exit.
	color_names_to_rgba = set(color_names_to_rgba)

	# None-extend the shorter set.
	if len(all_color_names) > len(color_names_to_rgba):
		diff = len(all_color_names) - len(color_names_to_rgba)
		color_names_to_rgba = tuple(color_names_to_rgba) + (None,) * diff
	elif len(color_names_to_rgba) > len(all_color_names):
		diff = len(color_names_to_rgba) - len(all_color_names)
		all_color_names = tuple(all_color_names) + (None,) * diff

	for names in zip(all_color_names, color_names_to_rgba):
		print >>sys.stderr, '\t'.join(('%r',) * len(names)) % names
	sys.exit('Cannot continue because our lists of color names are not equal')

def rgba_to_html_string(rgba, num_digits=6, use_uppercase=False):
	"Returns an HTML color literal, such as #ff0000, for an RGBA color. num_digits can be 6, 3, 8, or 4; if it's 8 or 4, the result string will include a fourth, alpha component."


	if num_digits >= 6:
		segment_formatter = '%02X' if use_uppercase else '%02x'
		num_components = 4 if num_digits >= 8 else 3
		multiplier = 0xff
	else:
		segment_formatter = '%01X' if use_uppercase else '%01x'
		num_components = 4 if num_digits >= 4 else 3
		multiplier = 0xf

	format = '#' + (segment_formatter * num_components)
	values = [int(component * multiplier) for component in rgba[:num_components]]
	try:
		return format % tuple(values)
	except:
		print >>sys.stderr, 'Got an exception while trying to format %r with values %r' % (format,)
		raise

################################################################################
if __name__ == "__main__":

	import optparse
	parser = optparse.OptionParser()
	parser.add_option('-d', '--generate-declarations', action='store_true', default=False, help='Generate method declarations instead of method implementations')
	opts, args = parser.parse_args()

	noun = 'method declaration' if opts.generate_declarations else 'method'
	print "//These methods are automatically generated! If you want to change them, please change the program in the Utilities folder instead. Otherwise, your changes may be clobbered by the next person.".replace('method', noun)

	import re
	camel_case_sep_exp = re.compile('[A-Z]')
	def camel_case_sep_sub(match):
		return ' ' + match.group(0).lower()

	# Grouping:
	#	Transparency (handled below, with separate color_names lists)
	#		Number of hex digits
	#			Color name
	#				Case of hex digits greater than 9
	def method_implementations(color_names, generate_implementations=True):
		format = implementation if generate_implementations else declaration
		for num_digits in (6, 3, 8, 4):
			# If the number of digits is a multiple of 4, then:
			# * num_digits % 4 is 0.
			# * We want to include alpha.
			include_alpha = not (num_digits % 4)

			for color in color_names:
				# Lowercase the first character.
				color_lowercase = color[:1].lower() + color[1:]
				color_human_readable = camel_case_sep_exp.sub(camel_case_sep_sub, color_lowercase)

				rgba = color_names_to_rgba[color]
				red, green, blue, alpha = rgba

				for case, use_uppercase in zip(('Lower', 'Upper'), (False, True)):
					html_string = rgba_to_html_string(rgba, num_digits, use_uppercase=use_uppercase)
					method = format % locals()

					# Strip out the '!!! Alpha' command that tells us which lines are alpha-related code.
					lines = method.split('\n')

					i = 0
					while i < len(lines):
						line = lines[i]
						if line.startswith('!!! '):
							line = line.replace('!!! ', '', 1)
							if line.lower().startswith('alpha'):
								if include_alpha:
									# Delete only the !!! line. Don't delete the alpha code.
									num_lines = 0
								else:
									line = line[len('Alpha '):]
									try:
										whitespace_index = line.index(' ')
									except ValueError:
										# Not found
										pass
									else:
										# Found; delete it and everything after it
										line = line[:whitespace_index]
									num_lines = int(line)

								del lines[i : i + num_lines + 1]
								continue
						i += 1

					method = '\n'.join(lines)

					yield method

			yield '' # Evil hax: This is here in order to print a new line between groups of methods with each number of digits.

	for method in method_implementations(color_names, generate_implementations=not opts.generate_declarations):
		print method
	for method in method_implementations(transparent_color_names, generate_implementations=not opts.generate_declarations):
		print method

	print "//End of automatically-generated methods".replace('method', noun)
