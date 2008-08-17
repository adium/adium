#!/usr/bin/env python

code_units_per_snowman = {
	'ASCII': 1, #The '?' fallback, not an actual snowman character
	'UTF8': 3,
	'UTF16': 1,
}

dataUsingEncoding_allowLossyConversion_nulTerminate_method_fmt = """\
- (void) testDataUsing%(encoding_name)sEncodingFrom%(source_encoding_name)s%(with_without_lossy_conversion)sLossyConversion%(with_without_nul_termination)sNulTermination {
	AIWiredString *string = %(string_creation_message)s;
	AIWiredData *data = [string dataUsingEncoding:%(encoding_constant)s allowLossyConversion:%(lossy_conversion)s nulTerminate:%(nul_terminate)s];

ASSERTIONS\
}\
"""
dataUsingEncoding_allowLossyConversion_method_fmt = """\
- (void) testDataUsing%(encoding_name)sEncodingFrom%(source_encoding_name)s%(with_without_lossy_conversion)sLossyConversion {
	AIWiredString *string = %(string_creation_message)s;
	AIWiredData *data = [string dataUsingEncoding:%(encoding_constant)s allowLossyConversion:%(lossy_conversion)s];

ASSERTIONS\
}\
"""
dataUsingEncoding_method_fmt = """\
- (void) testDataUsing%(encoding_name)sEncodingFrom%(source_encoding_name)s {
	AIWiredString *string = %(string_creation_message)s;
	AIWiredData *data = [string dataUsingEncoding:%(encoding_constant)s];

ASSERTIONS\
}\
"""

success_assertions = """\
	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
"""
failure_assertions = """\
	STAssertNil(data, @"-dataUsingEncoding:%(encoding_name)s allowLossyConversion:%(lossy_conversion)s nulTerminate: should not return an object");
"""
same_character_type_equality_assertion = """\
	STAssertEquals(memcmp([data bytes], sample%(source_encoding_name)sString, sample%(source_encoding_name)sStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
"""
ascii_to_utf16_equality_assertion = """\
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	%(character_type)s %(source_encoding_name)sStringAs%(encoding_name)s[sample%(source_encoding_name)sStringLength];
	for (unsigned i = 0U; i < sample%(source_encoding_name)sStringLength; ++i) {
		%(source_encoding_name)sStringAs%(encoding_name)s[i] = sample%(source_encoding_name)sString[i];
	}
	STAssertEquals(memcmp([data bytes], %(source_encoding_name)sStringAs%(encoding_name)s, sample%(source_encoding_name)sStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
"""
utf16_to_ascii_equality_assertion = """\
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of UTF-16 to ASCII so that we can verify the contents of the data object.
	%(character_type)s %(source_encoding_name)sStringAs%(encoding_name)s[sample%(source_encoding_name)sStringLength];
	for (unsigned i = 0U; i < sample%(source_encoding_name)sStringLength; ++i) {
		if (sample%(source_encoding_name)sString[i] > 127) {
			%(source_encoding_name)sStringAs%(encoding_name)s[i] = '?';
		} else {
			%(source_encoding_name)sStringAs%(encoding_name)s[i] = sample%(source_encoding_name)sString[i];
		}
	}
	STAssertEquals(memcmp([data bytes], %(source_encoding_name)sStringAs%(encoding_name)s, sample%(source_encoding_name)sStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
"""
nul_termination_assertions = """\
	STAssertEquals((unsigned long)([data length] / sizeof(%(character_type)s)), (unsigned long)(sample%(source_encoding_name)sStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((%(character_type)s *)[data bytes])[sample%(source_encoding_name)sStringLength], (%(character_type)s)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
"""
nul_termination_with_snowman_assertions = """\
	//-%(code_units_per_snowman_in_source_encoding)u+%(code_units_per_snowman_in_destination_encoding)u: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sample%(source_encoding_name)sStringLength - %(code_units_per_snowman_in_source_encoding)uUL) + %(code_units_per_snowman_in_destination_encoding)uUL);
	STAssertEquals((unsigned long)([data length] / sizeof(%(character_type)s)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((%(character_type)s *)[data bytes])[correctLength], (%(character_type)s)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
"""

def generate_AIWiredString_tests(encodings, method_fmt, prototype_only=False):
	test_lossy_conversion = '%(lossy_conversion)s' in method_fmt
	test_nul_termination = '%(nul_terminate)s' in method_fmt

	if prototype_only:
		import re
		definition_exp = re.compile(' {.+}', re.DOTALL)

	for source_encoding_name in encodings:
		code_units_per_snowman_in_source_encoding = code_units_per_snowman[source_encoding_name]

		if source_encoding_name == 'UTF16':
			string_creation_message = '[AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]'
		else:
			string_creation_message = '[[[AIWiredString alloc] initWithBytes:sample%sString length:sample%sStringLength encoding:NS%sStringEncoding] autorelease]' % (source_encoding_name, source_encoding_name, source_encoding_name, )

		for encoding_name in encodings:
			code_units_per_snowman_in_destination_encoding = code_units_per_snowman[encoding_name]

			if encoding_name == 'UTF16':
				encoding_constant = 'NSUnicodeStringEncoding'
				character_type = 'unichar'
			else:
				encoding_constant = 'NS%sStringEncoding' % (encoding_name,)
				character_type = 'char'

			for lossy_conversion in (False, True) if test_lossy_conversion else (False,):
				assert_nil = ((not lossy_conversion) and (encoding_name == 'ASCII') and (encoding_name != source_encoding_name))
				if assert_nil:
					assertions = failure_assertions
				else:
					assertions = success_assertions

					if (encoding_name == source_encoding_name) and (not lossy_conversion):
						assertions += same_character_type_equality_assertion
					elif (source_encoding_name == 'UTF16') and (encoding_name == 'ASCII'):
						assertions += utf16_to_ascii_equality_assertion
					elif (source_encoding_name == 'ASCII') and (encoding_name == 'UTF16'):
						assertions += ascii_to_utf16_equality_assertion

				with_without_lossy_conversion = 'With' if lossy_conversion else 'Without'
				lossy_conversion = 'YES' if lossy_conversion else 'NO'

				for nul_terminate in (False, True) if test_nul_termination else (False,):
					if nul_terminate and not assert_nil:
						if source_encoding_name == 'ASCII':
							assertions += nul_termination_assertions
						else:
							assertions += nul_termination_with_snowman_assertions

					with_without_nul_termination = 'With' if nul_terminate else 'Without'
					nul_terminate = 'YES' if nul_terminate else 'NO'

					this_method_fmt = method_fmt.replace('ASSERTIONS', assertions)
					if prototype_only:
						this_method_fmt = definition_exp.sub(';', this_method_fmt)
					yield this_method_fmt % locals()

if __name__ == "__main__":
	import optparse
	parser = optparse.OptionParser()
	parser.add_option('--interface', dest='prototype_only', help='Print declarations (for @interface), rather than definitions (for @implementation).', action='store_true', default=False)
	opts, args = parser.parse_args()

	print '//-dataUsingEncoding:allowLossyConversion:nulTerminate:'
	for method in generate_AIWiredString_tests(['ASCII', 'UTF8', 'UTF16'], dataUsingEncoding_allowLossyConversion_nulTerminate_method_fmt, prototype_only=opts.prototype_only):
		print method
	print

	print '//-dataUsingEncoding:allowLossyConversion:'
	for method in generate_AIWiredString_tests(['ASCII', 'UTF8', 'UTF16'], dataUsingEncoding_allowLossyConversion_method_fmt, prototype_only=opts.prototype_only):
		print method
	print

	print '//-dataUsingEncoding:'
	for method in generate_AIWiredString_tests(['ASCII', 'UTF8', 'UTF16'], dataUsingEncoding_method_fmt, prototype_only=opts.prototype_only):
		print method
	print

