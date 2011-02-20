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

#import "TestAttributedStringAdditions.h"

#import <AIUtilities/AIAttributedStringAdditions.h>

@implementation TestAttributedStringAdditions

- (void) testLinkedAttributedString
{
	NSString *linkLabel = @"Adium";
	NSString *linkURLString = @"http://adiumx.com/";
	NSURL *linkURL = [NSURL URLWithString:linkURLString];
	NSRange linkRange = { 0UL, 0UL };
	id linkValue;
	NSAttributedString *attributedString = nil;
	NSRange attributedStringRange;

	//First, try a string containing a URL.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithLinkLabel:linkLabel linkDestination:linkURLString], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:0UL effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Link range is not the entire range of the attributed string");

	//Next, try an NSURL object.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithLinkLabel:linkLabel linkDestination:linkURL], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:0UL effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Link range is not the entire range of the attributed string");
}
- (void) testAttributedStringWithLinkedSubstring
{
	NSString *linkLabel = @"Download Adium now!";
	NSString *linkURLString = @"http://adiumx.com/";
	NSURL *linkURL = [NSURL URLWithString:linkURLString];
	NSRange intendedLinkRange = { 9UL, 5UL }; //@"Adium"
	NSRange linkRange = { 0UL, 0UL };
	id linkValue;
	NSAttributedString *attributedString = nil;

	//First, try a string containing a URL.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURLString], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:intendedLinkRange.location effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	STAssertEquals(linkRange, intendedLinkRange, @"Link range is not the range we wanted to link");

	//Next, try an NSURL object.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURL], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:intendedLinkRange.location effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	STAssertEquals(linkRange, intendedLinkRange, @"Link range is not the range we wanted to link");
}
- (void) testAttributedStringWithLinkedEntireStringUsingSubstringMethod
{
	NSString *linkLabel = @"Adium";
	NSString *linkURLString = @"http://adiumx.com/";
	NSURL *linkURL = [NSURL URLWithString:linkURLString];
	NSRange intendedLinkRange = { 0UL, [linkLabel length] };
	NSRange linkRange = { 0UL, 0UL };
	id linkValue;
	NSAttributedString *attributedString = nil;
	NSRange attributedStringRange;

	//First, try a string containing a URL.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURLString], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:0UL effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Link range is not the entire range of the attributed string");

	//Next, try an NSURL object.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURL], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:0UL effectiveRange:&linkRange];
	STAssertNotNil(linkValue, @"Attributed string does not have a link");
	STAssertTrue([linkValue isKindOfClass:[NSURL class]], @"Link value is not an NSURL");
	STAssertEqualObjects(linkValue, linkURL, @"Link value is not equal to the URL we provided");
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Link range is not the entire range of the attributed string");
}
- (void) testAttributedStringWithLinkedEmptySubstring
{
	NSString *linkLabel = @"Download Adium now!";
	NSString *linkURLString = @"http://adiumx.com/";
	NSURL *linkURL = [NSURL URLWithString:linkURLString];
	NSRange intendedLinkRange = { 9UL, 0UL }; //@""
	NSRange linkRange = { 0UL, 0UL };
	id linkValue;
	NSAttributedString *attributedString = nil;
	NSRange attributedStringRange;

	//First, try a string containing a URL.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURLString], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:intendedLinkRange.location effectiveRange:&linkRange];
	STAssertNil(linkValue, @"Attributed string has a link");
	//linkRange, at this point, should be the range that does not have a link, which should be the entire string.
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Non-link range is not the entire string");

	//Next, try an NSURL object.
	STAssertNoThrow(attributedString = [NSAttributedString attributedStringWithString:linkLabel linkRange:intendedLinkRange linkDestination:linkURL], @"attributedStringWithLinkLabel:linkDestination: threw an exception");
	STAssertNotNil(attributedString, @"attributedStringWithLinkLabel:linkDestination: returned nil");
	STAssertEqualObjects([attributedString string], linkLabel, @"Attributed string's text is not equal to the original string");
	STAssertEquals([attributedString length], [linkLabel length], @"Attributed string is not the same length (%lu) as the original string (%lu)", [attributedString length], [linkLabel length]);
	linkValue = [attributedString attribute:NSLinkAttributeName atIndex:intendedLinkRange.location effectiveRange:&linkRange];
	STAssertNil(linkValue, @"Attributed string has a link");
	//linkRange, at this point, should be the range that does not have a link, which should be the entire string.
	attributedStringRange = (NSRange){ 0UL, [attributedString length] };
	STAssertEquals(linkRange, attributedStringRange, @"Non-link range is not the entire string");
}

- (void) testAttributedStringByConvertingLinksToStrings {
	NSMutableAttributedString *input = [[[NSMutableAttributedString alloc] initWithString:@"Adium requires Growl."] autorelease];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://adiumx.com/"] range:[[input string] rangeOfString:@"Adium"]];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://growl.info/"] range:[[input string] rangeOfString:@"Growl"]];

	NSAttributedString *result = nil;
	STAssertNoThrow(result = [input attributedStringByConvertingLinksToStrings], @"-attributedStringByConvertingLinksToStrings threw an exception");
	STAssertNotNil(result, @"-attributedStringByConvertingLinksToStrings returned nil");

	STAssertEqualObjects([result string], @"Adium (http://adiumx.com/) requires Growl (http://growl.info/).", @"-attributedStringByConvertingLinksToStrings did not correctly expand the links");
}

- (void) testAttributedStringByConvertingLinksToURLStrings {
	NSMutableAttributedString *input = [[[NSMutableAttributedString alloc] initWithString:@"Adium requires Growl."] autorelease];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://adiumx.com/"] range:[[input string] rangeOfString:@"Adium"]];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://growl.info/"] range:[[input string] rangeOfString:@"Growl"]];

	NSAttributedString *result = nil;
	STAssertNoThrow(result = [input attributedStringByConvertingLinksToURLStrings], @"-attributedStringByConvertingLinksToURLStrings threw an exception");
	STAssertNotNil(result, @"-attributedStringByConvertingLinksToURLStrings returned nil");

	STAssertEqualObjects([result string], @"http://adiumx.com/ requires http://growl.info/.", @"-attributedStringByConvertingLinksToURLStrings did not correctly expand the links");
}

@end
