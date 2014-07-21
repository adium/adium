/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */
#import "TestStringAdditions.h"
#import "AIUnitTestUtilities.h"

#import <AIUtilities/AIStringAdditions.h>

@implementation TestStringAdditions

- (void)testRandomStringOfLength
{
	//Test at least two different lengths, and see what happens when we ask for 0.
	NSString *str = [NSString randomStringOfLength:6];
	STAssertEquals([str length], (NSUInteger)6U, @"+randomStringOfLength:6 did not return a 6-character string; it returned \"%@\", which is %u characters", str, [str length]);
	str = [NSString randomStringOfLength:12];
	STAssertEquals([str length], (NSUInteger)12U, @"+randomStringOfLength:12 did not return a 12-character string; it returned \"%@\", which is %u characters", str, [str length]);
	str = [NSString randomStringOfLength:0];
	STAssertEquals([str length], (NSUInteger)0U, @"+randomStringOfLength:0 did not return a 0-character string; it returned \"%@\", which is %u characters", str, [str length]);
}
- (void)testStringWithContentsOfUTF8File
{
	//Our octest file contains a sample file to read in testing this method.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *pathToFile = [bundle pathForResource:@"UTF8Snowman" ofType:@"txt"];

	char snowmanUTF8[4] = { 0xe2, 0x98, 0x83, 0 };
	NSString *snowman = [NSString stringWithUTF8String:snowmanUTF8];
	NSString *snowmanFromFile = [NSString stringWithContentsOfUTF8File:pathToFile];
	AISimplifiedAssertEqualObjects(snowman, snowmanFromFile, @"+stringWithContentsOfUTF8File: incorrectly read the file");
}
- (void)testMutableStringWithContentsOfUTF8File
{
	//Our octest file contains a sample file to read in testing this method.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *pathToFile = [bundle pathForResource:@"UTF8Snowman" ofType:@"txt"];

	char snowmanUTF8[4] = { 0xe2, 0x98, 0x83, 0 };
	NSString *snowman = [NSString stringWithUTF8String:snowmanUTF8];
	NSMutableString *snowmanFromFile = [NSMutableString stringWithContentsOfUTF8File:pathToFile];
	AISimplifiedAssertEqualObjects(snowman, snowmanFromFile, @"+stringWithContentsOfUTF8File: incorrectly read the file");
	STAssertTrue([snowmanFromFile isKindOfClass:[NSMutableString class]], @"Sending +stringWithContentsOfUTF8File: to NSMutableString should result in a mutable string");
}
- (void)testEllipsis
{
	STAssertEquals([[NSString ellipsis] length], (NSUInteger)1U, @"+ellipsis did not return a 1-character string; it returned \"%@\"", [NSString ellipsis]);
	STAssertEquals((NSUInteger)[[NSString ellipsis] characterAtIndex:0U], (NSUInteger)0x2026U, @"+ellipsis did not return a horizontal ellipsis (U+2026); it returned \"%@\" instead", [NSString ellipsis]);
}
- (void)testMutableEllipsis
{
	STAssertEquals([[NSMutableString ellipsis] length], (NSUInteger)1U, @"+ellipsis did not return a 1-character string; it returned \"%@\"", [NSString ellipsis]);
	STAssertEquals((NSUInteger)[[NSMutableString ellipsis] characterAtIndex:0U], (NSUInteger)0x2026U, @"+ellipsis did not return a horizontal ellipsis (U+2026); it returned \"%@\" instead", [NSString ellipsis]);
	STAssertTrue([[NSMutableString ellipsis] isKindOfClass:[NSMutableString class]], @"Sending +ellipsis to NSMutableString should result in a mutable string");
}
- (void)testStringByAppendingEllipsis
{
	NSString *before = @"Foo";
	NSString *after  = [before stringByAppendingEllipsis];
	STAssertEquals(([after length] - [before length]), (NSUInteger)1U, @"Appending a single character should result in a string that is one character longer. before is \"%@\"; after is \"%@\"", before, after);
	STAssertTrue([after hasSuffix:[NSString ellipsis]], @"String formed by appending [NSString ellipsis] should end with [NSString ellipsis]. before is \"%@\"; after is \"%@\"", before, after);
}
- (void)testCompactedString
{
	AISimplifiedAssertEqualObjects([@"FOO" compactedString], @"foo", @"-compactedString should lowercase an all-uppercase string");
	AISimplifiedAssertEqualObjects([@"Foo" compactedString], @"foo", @"-compactedString should lowercase a mixed-case string");
	AISimplifiedAssertEqualObjects([@"foo" compactedString], @"foo", @"-compactedString should do nothing to an all-lowercase string");
	AISimplifiedAssertEqualObjects([@"foo bar" compactedString], @"foobar", @"-compactedString should remove spaces");
}
- (void)testStringWithEllipsisByTruncatingToLength
{
	NSString *before = @"Foo";
	NSString *after;

	//First, try truncating to a greater length.
	after = [before stringWithEllipsisByTruncatingToLength:[before length] + 1];
	STAssertEqualObjects(before, after, @"Truncating to a length greater than that of the string being truncated should not change the string. before is \"%@\"; after is \"%@\"", before, after);

	//Second, try truncating to the same length.
	after = [before stringWithEllipsisByTruncatingToLength:[before length]];
	STAssertEqualObjects(before, after, @"Truncating to a length equal to that of the string being truncated should not change the string. before is \"%@\"; after is \"%@\"", before, after);

	//Third, try truncating to a shorter length. This one should actually truncate the string and append an ellipsis.
	after = [before stringWithEllipsisByTruncatingToLength:[before length] - 1];
	STAssertEquals(([before length] - [after length]), (NSUInteger)1U, @"Appending a single character should result in a string that is one character longer. before is \"%@\"; after is \"%@\"", before, after);
	//The part before the ellipsis in after should be equal to the same portion of before.
	NSUInteger cutHere = [after length] - 1;
	STAssertEqualObjects([after  substringToIndex:cutHere - 1],
	                     [before substringToIndex:cutHere - 1],
						 @"Truncating a string should not result in any changes before the truncation point before is \"%@\"; after is \"%@\"", before, after);
	STAssertTrue([after hasSuffix:[NSString ellipsis]], @"String formed by appending [NSString ellipsis] should end with [NSString ellipsis]. before is \"%@\"; after is \"%@\"", before, after);
}
- (void)testIdentityMethod
{
	NSString *str = @"Foo";
	STAssertEquals([str string], str, @"A method that returns itself must, by definition, return itself.");
}
- (void)testXMLEscaping
{
	NSString *originalXMLSource = @"<rel-date><number>Four score</number> &amp; <number>seven</number> years ago</rel-date>";
	NSString *escaped = [originalXMLSource stringByEscapingForXMLWithEntities:nil];
	NSString *unescaped = [escaped stringByUnescapingFromXMLWithEntities:nil];
	STAssertEqualObjects(originalXMLSource, unescaped, @"Round trip through scaping + unescaping did not preserve the original string.");
}
- (void)testEscapingForShell
{
	//Whitespace should be replaced by '\' followed by a character (one of [atnfr] for most of them; space simply puts a \ in front of the space).
	STAssertEqualObjects([@"\a" stringByEscapingForShell], @"\\a", @"-stringByEscapingForShell didn't properly escape the alert (bell) character");
	STAssertEqualObjects([@"\t" stringByEscapingForShell], @"\\t", @"-stringByEscapingForShell didn't properly escape the horizontal tab character");
	STAssertEqualObjects([@"\n" stringByEscapingForShell], @"\\n", @"-stringByEscapingForShell didn't properly escape the line-feed character");
	STAssertEqualObjects([@"\v" stringByEscapingForShell], @"\\v", @"-stringByEscapingForShell didn't properly escape the vertical tab character");
	STAssertEqualObjects([@"\f" stringByEscapingForShell], @"\\f", @"-stringByEscapingForShell didn't properly escape the form-feed character");
	STAssertEqualObjects([@"\r" stringByEscapingForShell], @"\\r", @"-stringByEscapingForShell didn't properly escape the carriage-return character");
	STAssertEqualObjects([@" "  stringByEscapingForShell], @"\\ ", @"-stringByEscapingForShell didn't properly escape the space character");

	//Other unsafe characters are simply backslash-escaped.
	STAssertEqualObjects([@"\\" stringByEscapingForShell], @"\\\\", @"-stringByEscapingForShell didn't properly escape the backslash character");
	STAssertEqualObjects([@"'" stringByEscapingForShell], @"\\'", @"-stringByEscapingForShell didn't properly escape the apostrophe/single-quotation-mark character");
	STAssertEqualObjects([@"\"" stringByEscapingForShell], @"\\\"", @"-stringByEscapingForShell didn't properly escape the quotation-mark character");
	STAssertEqualObjects([@"`" stringByEscapingForShell], @"\\`", @"-stringByEscapingForShell didn't properly escape the backquote character");
	STAssertEqualObjects([@"!" stringByEscapingForShell], @"\\!", @"-stringByEscapingForShell didn't properly escape the bang character");
	STAssertEqualObjects([@"$" stringByEscapingForShell], @"\\$", @"-stringByEscapingForShell didn't properly escape the dollar-sign character");
	STAssertEqualObjects([@"&"  stringByEscapingForShell], @"\\&", @"-stringByEscapingForShell didn't properly escape the ampersand character");
	STAssertEqualObjects([@"|"  stringByEscapingForShell], @"\\|", @"-stringByEscapingForShell didn't properly escape the pipe character");
}
- (void)testVolumePath
{
	STAssertEqualObjects([@"/" volumePath], @"/", @"Volume path of / is \"%@\", not /", [@"/" volumePath]);

	//Get the name of the startup volume, so that we can attempt to get the volume path of (what we hope is) a directory on it.
	OSStatus err;

	FSRef ref;
	err = FSPathMakeRef((const UInt8 *)"/", &ref, /*isDirectory*/ NULL);
	STAssertTrue(err == noErr, @"Error while attempting to determine the path of the startup volume: FSPathMakeRef returned %i", err);

	struct HFSUniStr255 volumeNameUnicode;
	err = FSGetCatalogInfo(&ref, /*whichInfo*/ 0, /*catalogInfo*/ NULL, /*outName*/ &volumeNameUnicode, /*fsSpec*/ NULL, /*parentRef*/ NULL);
	STAssertTrue(err == noErr, @"Error while attempting to determine the path of the startup volume: FSGetCatalogInfo returned %i", err);

	NSString *volumeName = [[[NSString alloc] initWithCharactersNoCopy:volumeNameUnicode.unicode length:volumeNameUnicode.length freeWhenDone:NO] autorelease];
	NSLog(@"Volume name from FSGetCatalogInfo is %@", volumeName);
	NSString *inputPath = [[@"/Volumes" stringByAppendingPathComponent:volumeName] stringByAppendingPathComponent:@"Applications"];
	NSString *outputPath = [inputPath volumePath];

	STAssertEqualObjects(outputPath, @"/", @"The volume path of %@ should be /; instead, it was \"%@\"", inputPath, outputPath);
}

- (void)testRangeOfLineBreakCharacterInRange
{
	NSRange searchRange = { 2U, 3U };
	STAssertEqualObjects([@"foo\nbar" substringWithRange:searchRange], @"o\nb", @"Search range returned an unexpected substring");

	NSRange range;

	//No line-break
	range = [@"foo bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a length of 0");

	//Line feed
	range = [@"foo\nbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return the location of the line feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return a length of 1");

	//Form feed
	range = [@"foo\fbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return the location of the form feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return a length of 1");

	//Carriage return
	range = [@"foo\rbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return a length of 1");

	//CRLF sequence
	range = [@"foo\r\nbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)2U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return a length of 2");

	//Next line
	range = [[NSString stringWithUTF8String:"foo\xc2\x85""bar"] rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return the location of the next line");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return a length of 1");

	//Line separator
	range = [@"foo\u2028bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return the location of the line separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return a length of 1");

	//Paragraph separator
	range = [@"foo\u2029bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return the location of the paragraph separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return a length of 1");
}
- (void)testRangeOfLineBreakCharacterInEmptyRange
{
	NSRange searchRange = { 3U, 0U }; //3 being the index of the line-break
	STAssertEqualObjects([@"foo\nbar" substringWithRange:searchRange], @"", @"Search range returned an unexpected substring");

	NSRange range;

	//No line-break
	range = [@"foo bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a length of 0");

	//Line feed
	range = [@"foo\nbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return a length of 0");

	//Form feed
	range = [@"foo\fbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return a length of 0");

	//Carriage return
	range = [@"foo\rbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return a length of 0");

	//CRLF sequence
	range = [@"foo\r\nbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return a length of 0");

	//Next line
	range = [@"foo\xc2\x85""bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return a length of 0");

	//Line separator
	range = [@"foo\u2028bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return a length of 0");

	//Paragraph separator
	range = [@"foo\u2029bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return a length of 0");
}
- (void)testRangeOfLineBreakCharacterInRangeNotContainingLineBreakCharacter
{
	NSRange searchRange = { 4U, 3U };
	STAssertEqualObjects([@"foo\nbar" substringWithRange:searchRange], @"bar", @"Search range returned an unexpected substring");
	NSRange searchRangeForCRLF = { searchRange.location + 1U, searchRange.length };
	STAssertEqualObjects([@"foo\r\nbar" substringWithRange:searchRangeForCRLF], @"bar", @"Search range (for CRLF)returned an unexpected substring");

	NSRange range;

	//No line-break
	range = [@"foo bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that doesn't have one, should return a length of 0");

	//Line feed
	range = [@"foo\nbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line feed, should return a length of 0");

	//Form feed
	range = [@"foo\fbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a form feed, should return a length of 0");

	//Carriage return
	range = [@"foo\rbar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a carriage return, should return a length of 0");

	//CRLF sequence
	range = [@"foo\r\nbar" rangeOfLineBreakCharacterInRange:searchRangeForCRLF];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a CRLF sequence, should return a length of 0");

	//Next line
	range = [@"foo\xc2\x85""bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a next line, should return a length of 0");

	//Line separator
	range = [@"foo\u2028bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a line separator, should return a length of 0");

	//Paragraph separator
	range = [@"foo\u2029bar" rangeOfLineBreakCharacterInRange:searchRange];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterInRange:, sent to a string that contains a paragraph separator, should return a length of 0");
}
- (void)testRangeOfLineBreakCharacterInPartiallyInvalidRange
{
	NSRange searchRange = { 5U, 3U }; //"arX" (where X = outside the string)
	STAssertThrowsSpecificNamed([@"foo\nbar" rangeOfLineBreakCharacterInRange:searchRange], NSException, NSRangeException, @"-rangeOfLineBreakCharacterInRange:, with a range that is partially outside the receiver string, should throw NSRangeException");
}
- (void)testRangeOfLineBreakCharacterInInvalidRange
{
	NSRange searchRange = { 12U, 3U }; //Length of @"foo\nbar": 7; 12 > 7, so the range is wholly invalid
	STAssertThrowsSpecificNamed([@"foo\nbar" rangeOfLineBreakCharacterInRange:searchRange], NSException, NSRangeException, @"-rangeOfLineBreakCharacterInRange:, with a range that is wholly outside the receiver string, should throw NSRangeException");
}
- (void)testRangeOfLineBreakCharacterFromIndex
{
	STAssertEqualObjects([@"foo\nbar" substringFromIndex:3U], @"\nbar", @"Search range returned an unexpected substring");

	NSRange range;

	//No line-break
	range = [@"foo bar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that doesn't have one, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that doesn't have one, should return a length of 0");

	//Line feed
	range = [@"foo\nbar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a line feed, should return the location of the line feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a line feed, should return a length of 1");

	//Form feed
	range = [@"foo\fbar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a form feed, should return the location of the form feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a form feed, should return a length of 1");

	//Carriage return
	range = [@"foo\rbar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a carriage return, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a carriage return, should return a length of 1");

	//CRLF sequence
	range = [@"foo\r\nbar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a CRLF sequence, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)2U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a CRLF sequence, should return a length of 2");

	//Next line
	range = [@"foo\xc2\x85""bar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a next line, should return the location of the next line");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a next line, should return a length of 1");

	//Line separator
	range = [@"foo\u2028bar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a line separator, should return the location of the line separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a line separator, should return a length of 1");

	//Paragraph separator
	range = [@"foo\u2029bar" rangeOfLineBreakCharacterFromIndex:3U];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a paragraph separator, should return the location of the paragraph separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacterFromIndex:, sent to a string that contains a paragraph separator, should return a length of 1");
}
- (void)testRangeOfLineBreakCharacterFromInvalidIndex
{
	NSUInteger startIdx = 7U; //Length of @"foo\nbar": 7, so this index is just outside the string (last valid index: 6).
	STAssertThrowsSpecificNamed([@"foo\nbar" rangeOfLineBreakCharacterFromIndex:startIdx], NSException, NSRangeException, @"-rangeOfLineBreakCharacterFromIndex:, with a start index that is outside the receiver string, should throw NSRangeException");
}
- (void)testRangeOfLineBreakCharacter
{
	NSRange range;

	//No line-break
	range = [@"foo bar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacter, sent to a string that doesn't have one, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacter, sent to a string that doesn't have one, should return a length of 0");

	//Line feed
	range = [@"foo\nbar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a line feed, should return the location of the line feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a line feed, should return a length of 1");

	//Form feed
	range = [@"foo\fbar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a form feed, should return the location of the form feed");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a form feed, should return a length of 1");

	//Carriage return
	range = [@"foo\rbar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a carriage return, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a carriage return, should return a length of 1");

	//CRLF sequence
	range = [@"foo\r\nbar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a CRLF sequence, should return the location of the carriage return");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)2U, @"-rangeOfLineBreakCharacter, sent to a string that contains a CRLF sequence, should return a length of 2");

	//Next line
	range = [@"foo\xc2\x85""bar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a next line, should return the location of the next line");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a next line, should return a length of 1");

	//Line separator
	range = [@"foo\u2028bar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a line separator, should return the location of the line separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a line separator, should return a length of 1");

	//Paragraph separator
	range = [@"foo\u2029bar" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)3U, @"-rangeOfLineBreakCharacter, sent to a string that contains a paragraph separator, should return the location of the paragraph separator");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)1U, @"-rangeOfLineBreakCharacter, sent to a string that contains a paragraph separator, should return a length of 1");
}
- (void)testRangeOfLineBreakCharacterInEmptyString
{
	NSRange range = [@"" rangeOfLineBreakCharacter];
	STAssertEquals((NSUInteger)range.location, (NSUInteger)NSNotFound, @"-rangeOfLineBreakCharacter, sent to an empty string, should return a location of NSNotFound");
	STAssertEquals((NSUInteger)range.length, (NSUInteger)0U, @"-rangeOfLineBreakCharacter, sent to an empty string, should return a length of 0");
}

- (void)testAllLinesWithSeparator
{
	NSString *str = @"Foo\nbar\nbaz";
	NSArray *linesWithSep = [str allLinesWithSeparator:@"Qux"];
	NSArray *expectedLines = [NSArray arrayWithObjects:@"Foo", @"Qux", @"bar", @"Qux", @"baz", nil];
	AISimplifiedAssertEqualObjects(linesWithSep, expectedLines, @"allLinesWithSeparator: did not properly split and splice the array");

	NSArray *lines = [str allLinesWithSeparator:nil];
	expectedLines = [NSArray arrayWithObjects:@"Foo", @"bar", @"baz", nil];
	AISimplifiedAssertEqualObjects(lines, expectedLines, @"allLinesWithSeparator: did not properly split the array");
}
- (void)testAllLines
{
	NSString *str = @"Foo\nbar\nbaz";
	NSArray *lines = [str allLines];
	NSArray *expectedLines = [NSArray arrayWithObjects:@"Foo", @"bar", @"baz", nil];
	AISimplifiedAssertEqualObjects(lines, expectedLines, @"allLines did not properly split the array");
}

- (void) testCaseInsensitivelyEqualToSameString {
	NSString *str = @"Adium rocks!";
	NSString *other = [NSMutableString stringWithString:str]; //Using NSMutableString guarantees that we won't simply get the same immutable string.
	STAssertTrue([str isCaseInsensitivelyEqualToString:other], @"string should be equal to itself!");
}
- (void) testCaseInsensitivelyEqualToSameStringInUppercase {
	NSString *str = @"Adium rocks!";
	NSString *other = [str uppercaseString];
	STAssertTrue([str isCaseInsensitivelyEqualToString:other], @"string should be case-insensitively equal to uppercase version of it");
}
- (void) testCaseInsensitivelyEqualToSameStringInLowercase {
	NSString *str = @"Adium rocks!";
	NSString *other = [str lowercaseString];
	STAssertTrue([str isCaseInsensitivelyEqualToString:other], @"string should be case-insensitively equal to lowercase version of it");
}
- (void) testCaseInsensitivelyEqualToStringPlusPrefix {
	NSString *str = @"Adium rocks!";
	NSString *other = [@"Verily, " stringByAppendingString:str];
	STAssertFalse([str isCaseInsensitivelyEqualToString:other], @"string should be inequal to prefixed version of it");
}
- (void) testCaseInsensitivelyEqualToStringPlusSuffix {
	NSString *str = @"Adium rocks!";
	NSString *other = [str stringByAppendingString:@" Yes it does!"];
	STAssertFalse([str isCaseInsensitivelyEqualToString:other], @"string should be inequal to suffixed version of it");
}
- (void) testCaseInsensitivelyEqualToCompletelyDifferentString {
	NSString *str = @"Adium rocks!";
	NSString *other = @"I just use iChat.";
	STAssertFalse([str isCaseInsensitivelyEqualToString:other], @"string should be inequal to completely different string");
}
- (void) testCaseInsensitivelyEqualToNil {
	NSString *str = @"Adium rocks!";
	STAssertThrows([str isCaseInsensitivelyEqualToString:nil], @"can't compare string to nil; this should have thrown");
}
- (void) testCaseInsensitivelyEqualToThingsThatAreNotStrings {
	NSString *str = @"Adium rocks!";
	STAssertThrows([str isCaseInsensitivelyEqualToString:(NSString *)[[[NSObject alloc] init] autorelease]], @"can't compare string to plain object; this should have thrown");
	STAssertThrows([str isCaseInsensitivelyEqualToString:(NSString *)[NSNumber numberWithInteger:42]], @"can't compare string to number; this should have thrown");
	STAssertThrows([str isCaseInsensitivelyEqualToString:(NSString *)[NSValue valueWithRect:NSMakeRect(0.0f, 0.0f, 128.0f, 128.0f)]], @"can't compare string to rect value; this should have thrown");
	STAssertThrows([str isCaseInsensitivelyEqualToString:(NSString *)[NSImage imageNamed:@"NSDefaultApplicationIcon"]], @"can't compare string to image; this should have thrown");
}


@end
