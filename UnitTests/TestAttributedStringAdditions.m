//
//  TestAttributedStringAdditions.m
//  Adium
//
//  Created by Peter Hosey on 2009-03-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

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
	NSAttributedString *attributedString;
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
	NSAttributedString *attributedString;

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
	NSAttributedString *attributedString;
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
	NSAttributedString *attributedString;
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

	NSAttributedString *result;
	STAssertNoThrow(result = [input attributedStringByConvertingLinksToStrings], @"-attributedStringByConvertingLinksToStrings threw an exception");
	STAssertNotNil(result, @"-attributedStringByConvertingLinksToStrings returned nil");

	STAssertEqualObjects([result string], @"Adium (http://adiumx.com/) requires Growl (http://growl.info/).", @"-attributedStringByConvertingLinksToStrings did not correctly expand the links");
}

- (void) testAttributedStringByConvertingLinksToURLStrings {
	NSMutableAttributedString *input = [[[NSMutableAttributedString alloc] initWithString:@"Adium requires Growl."] autorelease];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://adiumx.com/"] range:[[input string] rangeOfString:@"Adium"]];
	[input addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://growl.info/"] range:[[input string] rangeOfString:@"Growl"]];

	NSAttributedString *result;
	STAssertNoThrow(result = [input attributedStringByConvertingLinksToURLStrings], @"-attributedStringByConvertingLinksToURLStrings threw an exception");
	STAssertNotNil(result, @"-attributedStringByConvertingLinksToURLStrings returned nil");

	STAssertEqualObjects([result string], @"http://adiumx.com/ requires http://growl.info/.", @"-attributedStringByConvertingLinksToURLStrings did not correctly expand the links");
}

@end
