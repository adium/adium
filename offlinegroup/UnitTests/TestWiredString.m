//
//  TestWiredString.m
//  Adium
//
//  Created by Peter Hosey on 2008-07-03.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import "TestWiredString.h"

#import <AIUtilities/AIWiredString.h>
#import <AIUtilities/AIWiredData.h>

//Lengths in code points (NumCharacters) or code units (Length), not including NUL in either case.
enum {
	sampleASCIIStringNumCharacters = 11U,
	sampleASCIIStringLength = (sampleASCIIStringNumCharacters - 0U) + 0U,
	sampleUTF8StringNumCharacters = 21U,
	sampleUTF8StringLength = (sampleUTF8StringNumCharacters - 1U) + 3U, //Three code units (bytes, in this case) for the snowman
	sampleUTF16StringNumCharacters = 21U,
	sampleUTF16StringLength = (sampleUTF16StringNumCharacters - 0U) + 0U, //One code unit for the snowman
};
static const char sampleASCIIString[sampleASCIIStringLength + 1U] = "Hello world";
static const char sampleUTF8String[sampleUTF8StringLength + 1U] = "This (\xe2\x98\x83) is a snowman";
static const unichar sampleUTF16String[sampleUTF16StringLength + 1U] = { 'T', 'h', 'i', 's', ' ', '(', 0x2603, ')', ' ', 'i', 's', ' ', 'a', ' ', 's', 'n', 'o', 'w', 'm', 'a', 'n', '\0' };

//Non-character for testing getCharacters:
enum { PERMANENTLY_UNASSIGNED_CHARACTER = 0xFFFF };

@interface AIWiredString (MethodsCurrentlyPrivate)
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding allowLossyConversion:(BOOL)allowLossyConversion nulTerminate:(BOOL)nulTerminate;
@end

@implementation TestWiredString

#pragma mark Testing autoreleased factories

//+string
- (void) testEmptyAutoreleasedString {
	AIWiredString *string = [AIWiredString string];
	STAssertNotNil(string, @"+string should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"+string should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"+string should return a wired string");
	STAssertEquals([string length], 0U, @"+string should return an empty string");
}

//+stringWithUTF8String:
- (void) testAutoreleasedStringWithUTF8String {
	AIWiredString *string = [AIWiredString stringWithUTF8String:sampleUTF8String];
	STAssertNotNil(string, @"+stringWithUTF8String: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"+stringWithUTF8String: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"+stringWithUTF8String: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF8StringNumCharacters, @"+stringWithUTF8String: should return a string of length %u", sampleUTF8StringLength);
}
- (void) testAutoreleasedStringWithEmptyUTF8String {
	AIWiredString *string = [AIWiredString stringWithUTF8String:""];
	STAssertNotNil(string, @"+stringWithUTF8String: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"+stringWithUTF8String: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"+stringWithUTF8String: should return a wired string");
	STAssertEquals([string length], 0U, @"+stringWithUTF8String: should return an empty string");
}
- (void) testAutoreleasedStringWithNULLUTF8String {
	STAssertThrows([AIWiredString stringWithUTF8String:NULL], @"+stringWithUTF8String:NULL should throw an exception");
}

//+stringWithString:
- (void) testAutoreleasedStringWithString {
	NSString *inputString = [NSString stringWithUTF8String:sampleUTF8String];
	AIWiredString *string = [AIWiredString stringWithString:inputString];
	STAssertNotNil(string, @"+stringWithString: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"+stringWithString: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"+stringWithString: should return a wired string");
	STAssertEquals([string length], [inputString length], @"+stringWithString: should return a string of length %u", sampleUTF8StringLength);
}
- (void) testAutoreleasedStringWithEmptyString {
	AIWiredString *string = [AIWiredString stringWithString:@""];
	STAssertNotNil(string, @"+stringWithString: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"+stringWithString: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"+stringWithString: should return a wired string");
	STAssertEquals([string length], 0U, @"+stringWithString: should return an empty string");
}
- (void) testAutoreleasedStringWithNoString {
	STAssertThrows([AIWiredString stringWithString:nil], @"+stringWithString:nil should throw an exception");
}

#pragma mark Testing non-autoreleased factories

//-init
- (void) testInitEmptyString {
	AIWiredString *string = [[AIWiredString alloc] init];
	STAssertNotNil(string, @"-init should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-init should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-init should return a wired string");
	STAssertEquals([string length], 0U, @"-init should return an empty string");
	[string release];
}
//initWithCharacters:length:
- (void) testInitWithUTF16Characters {
	AIWiredString *string = [[AIWiredString alloc] initWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	STAssertNotNil(string, @"-initWithCharacters:length: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithCharacters:length: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithCharacters:length: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF16StringLength, @"-initWithCharacters:length: should return a non-empty string");
	[string release];
}
//initWithCharacters:length:0
- (void) testInitWithNoUTF16Characters {
	AIWiredString *string = [[AIWiredString alloc] initWithCharacters:sampleUTF16String length:0U];
	STAssertNotNil(string, @"-initWithCharacters:length: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithCharacters:length: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithCharacters:length: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithCharacters:length:0U should return an empty string");
	[string release];
}
- (void) testInitWithNULLAndNoUTF16Characters {
	AIWiredString *string = [[AIWiredString alloc] initWithCharacters:NULL length:0U];
	STAssertNotNil(string, @"-initWithCharacters:length: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithCharacters:length: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithCharacters:length: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithCharacters:length:0U should return an empty string");
	[string release];
}
- (void) testInitWithNULLUTF16Characters {
	STAssertThrows([[AIWiredString alloc] initWithCharacters:NULL length:sampleUTF16StringLength], @"-initWithCharacters:NULL length:non-zero should throw an exception");
}

//initWithData:encoding:
- (void) testInitWithDataAndASCIIEncoding {
	NSData *data = [NSData dataWithBytes:sampleUTF8String length:sampleASCIIStringLength];
	AIWiredString *string = [[AIWiredString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	STAssertNotNil(string, @"-initWithData:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithData:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithData:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleASCIIStringLength, @"-initWithData:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithDataAndUTF8Encoding {
	NSData *data = [NSData dataWithBytes:sampleUTF8String length:sampleUTF8StringLength];
	AIWiredString *string = [[AIWiredString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	STAssertNotNil(string, @"-initWithData:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithData:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithData:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF8StringNumCharacters, @"-initWithData:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithDataAndUTF16Encoding {
	NSData *data = [NSData dataWithBytes:sampleUTF16String length:sampleUTF16StringLength * sizeof(unichar)];
	AIWiredString *string = [[AIWiredString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
	STAssertNotNil(string, @"-initWithData:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithData:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithData:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF16StringNumCharacters, @"-initWithData:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithNoDataAndASCIIEncoding {
	STAssertThrows([[AIWiredString alloc] initWithData:nil encoding:NSASCIIStringEncoding], @"-initWithData:nil encoding: should throw an exception");
}
- (void) testInitWithNoDataAndUTF8Encoding {
	STAssertThrows([[AIWiredString alloc] initWithData:nil encoding:NSUTF8StringEncoding], @"-initWithData:nil encoding: should throw an exception");
}
- (void) testInitWithNoDataAndUTF16Encoding {
	STAssertThrows([[AIWiredString alloc] initWithData:nil encoding:NSUnicodeStringEncoding], @"-initWithData:nil encoding: should throw an exception");
}
//initWithBytes:length:encoding:
- (void) testInitWithBytesAndLengthAndASCIIEncoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleASCIIStringLength, @"-initWithBytes:length:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithBytesAndLengthAndUTF8Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF8StringNumCharacters, @"-initWithBytes:length:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithBytesAndLengthAndUTF16Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleUTF16String length:sampleUTF16StringLength * sizeof(unichar) encoding:NSUnicodeStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF16StringLength, @"-initWithBytes:length:encoding: should return a non-empty string");
	[string release];
}
- (void) testInitWithBytesAndZeroLengthAndASCIIEncoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleASCIIString length:0U encoding:NSASCIIStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals((unsigned long)[string length], 0UL, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
- (void) testInitWithBytesAndZeroLengthAndUTF8Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleUTF8String length:0U encoding:NSUTF8StringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
- (void) testInitWithBytesAndZeroLengthAndUTF16Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:sampleUTF16String length:0U encoding:NSUnicodeStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
- (void) testInitWithNULLBytesAndZeroLengthAndASCIIEncoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:NULL length:0U encoding:NSASCIIStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
- (void) testInitWithNULLBytesAndZeroLengthAndUTF8Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:NULL length:0U encoding:NSUTF8StringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
- (void) testInitWithNULLBytesAndZeroLengthAndUTF16Encoding {
	AIWiredString *string = [[AIWiredString alloc] initWithBytes:NULL length:0U encoding:NSUnicodeStringEncoding];
	STAssertNotNil(string, @"-initWithBytes:length:encoding: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithBytes:length:encoding: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithBytes:length:encoding: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithBytes:length:encoding: should return an empty string");
	[string release];
}
//These should raise.
- (void) testInitWithNULLBytesAndLengthAndASCIIEncoding {
	STAssertThrows([[AIWiredString alloc] initWithBytes:NULL length:sampleASCIIStringLength encoding:NSASCIIStringEncoding], @"initWithBytes:NULL length:encoding: should throw an exception");
}
- (void) testInitWithNULLBytesAndLengthAndUTF8Encoding {
	STAssertThrows([[AIWiredString alloc] initWithBytes:NULL length:sampleUTF8StringLength encoding:NSUTF8StringEncoding], @"initWithBytes:NULL length:encoding: should throw an exception");
}
- (void) testInitWithNULLBytesAndLengthAndUTF16Encoding {
	STAssertThrows([[AIWiredString alloc] initWithBytes:NULL length:sampleUTF16StringLength * sizeof(unichar) encoding:NSUnicodeStringEncoding], @"initWithBytes:NULL length:encoding: should throw an exception");
}

//-initWithUTF8String:
- (void) testInitWithUTF8String {
	AIWiredString *string = [[AIWiredString alloc] initWithUTF8String:sampleUTF8String];
	STAssertNotNil(string, @"-initWithUTF8String: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithUTF8String: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithUTF8String: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF8StringNumCharacters, @"-initWithUTF8String: should return a string of length %u", sampleUTF8StringLength);
}
- (void) testInitWithEmptyUTF8String {
	AIWiredString *string = [[AIWiredString alloc] initWithUTF8String:""];
	STAssertNotNil(string, @"-initWithUTF8String: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithUTF8String: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithUTF8String: should return a wired string");
	STAssertEquals((unsigned long)[string length], 0UL, @"-initWithUTF8String: should return an empty string");
}
- (void) testInitWithNULLUTF8String {
	STAssertThrows([[AIWiredString alloc] initWithUTF8String:NULL], @"-initWithUTF8String:NULL should throw an exception");
}

//-initWithString:
- (void) testInitWithString {
	AIWiredString *string = [[AIWiredString alloc] initWithString:[NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]];
	STAssertNotNil(string, @"-initWithString: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithString: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithString: should return a wired string");
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF16StringLength, @"-initWithString: should return a non-empty string");
}
- (void) testInitWithEmptyString {
	AIWiredString *string = [[AIWiredString alloc] initWithString:[NSString string]];
	STAssertNotNil(string, @"-initWithString: should return an object");
	STAssertTrue([string isKindOfClass:[NSString class]], @"-initWithString: should return a string");
	STAssertTrue([string isKindOfClass:[AIWiredString class]], @"-initWithString: should return a wired string");
	STAssertEquals([string length], 0U, @"-initWithString: should return an empty string");
}
- (void) testInitWithNoString {
	STAssertThrows([[AIWiredString alloc] initWithString:nil], @"-initWithString:nil should throw an exception");
}

#pragma mark Testing character retrieval

//-length
- (void) testLength {
	AIWiredString *string = [AIWiredString stringWithString:[NSString stringWithUTF8String:sampleUTF8String]];
	STAssertEquals((unsigned long)[string length], (unsigned long)sampleUTF8StringNumCharacters, @"-length returned the wrong length for a non-empty string");
}
- (void) testEmptyLength {
	AIWiredString *string = [AIWiredString string];
	STAssertEquals([string length], 0U, @"-length returned the wrong length for an empty string");
}

//-getCharacters:
- (void) testGetCharacters {
	unichar buffer[sampleUTF16StringLength + 1U];
	buffer[sampleUTF16StringLength] = PERMANENTLY_UNASSIGNED_CHARACTER;

	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];

	[string getCharacters:buffer];
	STAssertEquals(memcmp(sampleUTF16String, buffer, sampleUTF16StringLength), 0, @"getCharacters: did not faithfully return the original characters that we created the string with");
	STAssertEquals(buffer[sampleUTF16StringLength], (unichar)PERMANENTLY_UNASSIGNED_CHARACTER, @"getCharacters: changed the buffer beyond the string's length; the character it put after the string is U+%04X", buffer[sampleUTF16StringLength]);
}
- (void) testGetCharactersToNULL {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];

	STAssertThrows([string getCharacters:NULL], @"-getCharacters:NULL should throw an exception");
}

//-getCharacters:range:
- (void) testGetCharactersInRange {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	NSRange range = { 6U, 1U }; //The snowman

	unichar buffer[2U];
	size_t substringLength = 1U;
	buffer[substringLength] = PERMANENTLY_UNASSIGNED_CHARACTER;

	[string getCharacters:buffer range:range];
	STAssertEquals(memcmp(sampleUTF16String + range.location, buffer, substringLength), 0, @"getCharacters:range: did not faithfully return the original characters that we created the string with");
	STAssertEquals(buffer[substringLength], (unichar)PERMANENTLY_UNASSIGNED_CHARACTER, @"getCharacters:range: changed the buffer beyond the substring's length; the character it put after the substring is U+%04X", buffer[substringLength]);
}
- (void) testGetCharactersInEmptyRange {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	NSRange range = { 6U, 0U }; //The snowman's position, but no characters from it

	unichar buffer[1U];
	size_t substringLength = 0U;
	buffer[substringLength] = PERMANENTLY_UNASSIGNED_CHARACTER;

	[string getCharacters:buffer range:range];
	STAssertEquals(buffer[substringLength], (unichar)PERMANENTLY_UNASSIGNED_CHARACTER, @"getCharacters:range: changed the buffer even though we asked for no characters; the character it put after the empty substring is U+%04X", buffer[substringLength]);
}
- (void) testGetCharactersInRangeToNULL {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	NSRange range = { 6U, 1U }; //The snowman

	STAssertThrows([string getCharacters:NULL range:range], @"-getCharacters:NULL range: should throw an exception");
}
- (void) testGetCharactersInEmptyRangeToNULL {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	NSRange range = { 6U, 0U }; //The snowman's position, but no characters from it

	STAssertThrows([string getCharacters:NULL range:range], @"-getCharacters:NULL range: should throw an exception");
}

#pragma mark Automatically-generated test methods (use Utilities/GenerateWiredStringTests.py to generate them)

//-dataUsingEncoding:allowLossyConversion:nulTerminate:
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleASCIIString, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleASCIIString, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	STAssertEquals((unsigned long)([data length] / sizeof(char)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[sampleASCIIStringLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals((unsigned long)([data length] / sizeof(char)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[sampleASCIIStringLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals((unsigned long)([data length] / sizeof(char)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[sampleASCIIStringLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals((unsigned long)([data length] / sizeof(char)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[sampleASCIIStringLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[sampleASCIIStringLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), (unsigned long)(sampleASCIIStringLength + 1UL), @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[sampleASCIIStringLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-3+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF8StringLength - 3UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF8String, sampleUTF8StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF8String, sampleUTF8StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	//-3+3: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF8StringLength - 3UL) + 3UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-3+3: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF8StringLength - 3UL) + 3UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-3+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF8StringLength - 3UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[correctLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversionWithNulTermination {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-3+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF8StringLength - 3UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[correctLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of UTF-16 to ASCII so that we can verify the contents of the data object.
	char UTF16StringAsASCII[sampleUTF16StringLength];
	for (unsigned i = 0U; i < sampleUTF16StringLength; ++i) {
		if (sampleUTF16String[i] > 127) {
			UTF16StringAsASCII[i] = '?';
		} else {
			UTF16StringAsASCII[i] = sampleUTF16String[i];
		}
	}
	STAssertEquals(memcmp([data bytes], UTF16StringAsASCII, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of UTF-16 to ASCII so that we can verify the contents of the data object.
	char UTF16StringAsASCII[sampleUTF16StringLength];
	for (unsigned i = 0U; i < sampleUTF16StringLength; ++i) {
		if (sampleUTF16String[i] > 127) {
			UTF16StringAsASCII[i] = '?';
		} else {
			UTF16StringAsASCII[i] = sampleUTF16String[i];
		}
	}
	STAssertEquals(memcmp([data bytes], UTF16StringAsASCII, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	//-1+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF16StringLength - 1UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-1+3: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF16StringLength - 1UL) + 3UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-1+3: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF16StringLength - 1UL) + 3UL);
	STAssertEquals((unsigned long)([data length] / sizeof(char)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((char *)[data bytes])[correctLength], (char)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF16String, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF16String, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
	//-1+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF16StringLength - 1UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[correctLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversionWithoutNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversionWithNulTermination {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES nulTerminate:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//-1+1: Subtract the snowman; insert the fallback character (probably '?').
	unsigned long correctLength = ((sampleUTF16StringLength - 1UL) + 1UL);
	STAssertEquals((unsigned long)([data length] / sizeof(unichar)), correctLength + 1UL, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL did not add a terminator character (ostensibly NUL) to its output");
	STAssertEquals(((unichar *)[data bytes])[correctLength], (unichar)0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate:NUL terminated its output with something other than a NUL");
}

//-dataUsingEncoding:allowLossyConversion:
- (void) testDataUsingASCIIEncodingFromASCIIWithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleASCIIString, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingASCIIEncodingFromASCIIWithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromASCIIWithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromASCIIWithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF8WithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF8String, sampleUTF8StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF8EncodingFromUTF8WithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithoutLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF8WithLossyConversion {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithoutLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingASCIIEncodingFromUTF16WithLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of UTF-16 to ASCII so that we can verify the contents of the data object.
	char UTF16StringAsASCII[sampleUTF16StringLength];
	for (unsigned i = 0U; i < sampleUTF16StringLength; ++i) {
		if (sampleUTF16String[i] > 127) {
			UTF16StringAsASCII[i] = '?';
		} else {
			UTF16StringAsASCII[i] = sampleUTF16String[i];
		}
	}
	STAssertEquals(memcmp([data bytes], UTF16StringAsASCII, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithoutLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF8EncodingFromUTF16WithLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithoutLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF16String, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromUTF16WithLossyConversion {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}

//-dataUsingEncoding:
- (void) testDataUsingASCIIEncodingFromASCII {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleASCIIString, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF8EncodingFromASCII {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromASCII {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleASCIIString length:sampleASCIIStringLength encoding:NSASCIIStringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	//Every ASCII character is exactly equal to its UTF-16 counterpart; the only difference is that UTF-16 code units are twice as big.
	//Hence this loop, to perform an impromptu conversion of ASCII to UTF-16 so that we can verify the contents of the data object.
	unichar ASCIIStringAsUTF16[sampleASCIIStringLength];
	for (unsigned i = 0U; i < sampleASCIIStringLength; ++i) {
		ASCIIStringAsUTF16[i] = sampleASCIIString[i];
	}
	STAssertEquals(memcmp([data bytes], ASCIIStringAsUTF16, sampleASCIIStringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingASCIIEncodingFromUTF8 {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingUTF8EncodingFromUTF8 {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF8String, sampleUTF8StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}
- (void) testDataUsingUTF16EncodingFromUTF8 {
	AIWiredString *string = [[[AIWiredString alloc] initWithBytes:sampleUTF8String length:sampleUTF8StringLength encoding:NSUTF8StringEncoding] autorelease];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingASCIIEncodingFromUTF16 {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSASCIIStringEncoding];

	STAssertNil(data, @"-dataUsingEncoding:ASCII allowLossyConversion:NO nulTerminate: should not return an object");
}
- (void) testDataUsingUTF8EncodingFromUTF16 {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
}
- (void) testDataUsingUTF16EncodingFromUTF16 {
	AIWiredString *string = [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength];
	AIWiredData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];

	STAssertNotNil(data, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a string");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-dataUsingEncoding:allowLossyConversion:nulTerminate: should return a wired string");
	STAssertEquals(memcmp([data bytes], sampleUTF16String, sampleUTF16StringLength), 0, @"-dataUsingEncoding:allowLossyConversion:nulTerminate: returned a data object whose bytes were not equal to the original input");
}

#pragma mark End of automatically-generated test methods

//-UTF8String
- (void) testUTF8String {
	AIWiredString *string = [AIWiredString stringWithUTF8String:sampleUTF8String];
	STAssertEquals(strcmp([string UTF8String], sampleUTF8String), 0, @"-UTF8String returned an incorrect string; it returned %s and the original was %s", [string UTF8String], sampleUTF8String);
}
- (void) testEmptyUTF8String {
	AIWiredString *string = [AIWiredString stringWithUTF8String:""];
	STAssertEquals(strcmp([string UTF8String], ""), 0, @"-UTF8String returned an incorrect string; it returned %s and the original was %s", [string UTF8String], "");
}

#pragma mark Testing comparison

//-isEqualToString:
- (void) testIsEqualToString {
	STAssertTrue([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqualToString:[NSString stringWithUTF8String:sampleUTF8String]], @"AIWiredString instance '%@' didn't compare equal to an equal NSString instance '%@'", [AIWiredString stringWithUTF8String:sampleUTF8String], [NSString stringWithUTF8String:sampleUTF8String]);
	STAssertTrue([[NSString stringWithUTF8String:sampleUTF8String] isEqualToString:[AIWiredString stringWithUTF8String:sampleUTF8String]], @"NSString instance '%@' didn't compare equal to an equal AIWiredString instance '%@'", [NSString stringWithUTF8String:sampleUTF8String], [AIWiredString stringWithUTF8String:sampleUTF8String]);

	//Now we try it with different encodings.
	STAssertTrue([[AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength] isEqualToString:[NSString stringWithUTF8String:sampleUTF8String]], @"AIWiredString instance '%@' didn't compare equal to an equal NSString instance '%@'", [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength], [NSString stringWithUTF8String:sampleUTF8String]);
	STAssertTrue([[NSString stringWithUTF8String:sampleUTF8String] isEqualToString:[AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]], @"NSString instance '%@' didn't compare equal to an equal AIWiredString instance '%@'", [NSString stringWithUTF8String:sampleUTF8String], [AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]);

	STAssertTrue([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqualToString:[NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]], @"AIWiredString instance '%@' didn't compare equal to an equal NSString instance '%@'", [AIWiredString stringWithUTF8String:sampleUTF8String], [NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]);
	STAssertTrue([[NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength] isEqualToString:[AIWiredString stringWithUTF8String:sampleUTF8String]], @"NSString instance '%@' didn't compare equal to an equal AIWiredString instance '%@'", [NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength], [AIWiredString stringWithUTF8String:sampleUTF8String]);
}
- (void) testIsNotEqualToString {
	//Passing the ASCII string to stringWithUTF8String: here is intentional. The UTF-8 string is different text from the ASCII string; therefore, using them together is appropriate testing inequality. And it won't cause a problem, because ASCII is a subset of UTF-8: UTF-8 can handle everything ASCII can, and in exactly the same way.
	//It's also intentional that we only do this for one stringWithUTF8String: message (per assertion), because we want to compare the UTF-8 text to the ASCII text. We wouldn't be testing for inequality if we were comparing the ASCII string to itself.
	STAssertFalse([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqualToString:[NSString stringWithUTF8String:sampleASCIIString]], @"AIWiredString instance didn't compare equal to an equal NSString instance");
	STAssertFalse([[NSString stringWithUTF8String:sampleUTF8String] isEqualToString:[AIWiredString stringWithUTF8String:sampleASCIIString]], @"NSString instance didn't compare equal to an equal AIWiredString instance");
}

//-isEqual:
- (void) testIsEqual {
	STAssertTrue([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqual:[NSString stringWithUTF8String:sampleUTF8String]], @"AIWiredString instance didn't compare equal to an equal NSString instance");
	STAssertTrue([[NSString stringWithUTF8String:sampleUTF8String] isEqual:[AIWiredString stringWithUTF8String:sampleUTF8String]], @"NSString instance didn't compare equal to an equal AIWiredString instance");

	//Now we try it with different encodings.
	STAssertTrue([[AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength] isEqual:[NSString stringWithUTF8String:sampleUTF8String]], @"AIWiredString instance didn't compare equal to an equal NSString instance");
	STAssertTrue([[NSString stringWithUTF8String:sampleUTF8String] isEqual:[AIWiredString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]], @"NSString instance didn't compare equal to an equal AIWiredString instance");

	STAssertTrue([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqual:[NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength]], @"AIWiredString instance didn't compare equal to an equal NSString instance");
	STAssertTrue([[NSString stringWithCharacters:sampleUTF16String length:sampleUTF16StringLength] isEqual:[AIWiredString stringWithUTF8String:sampleUTF8String]], @"NSString instance didn't compare equal to an equal AIWiredString instance");
}
- (void) testIsNotEqual {
	//Passing the ASCII string to stringWithUTF8String: here is intentional. The UTF-8 string is different text from the ASCII string; therefore, using them together is appropriate testing inequality. And it won't cause a problem, because ASCII is a subset of UTF-8: UTF-8 can handle everything ASCII can, and in exactly the same way.
	//It's also intentional that we only do this for one stringWithUTF8String: message (per assertion), because we want to compare the UTF-8 text to the ASCII text. We wouldn't be testing for inequality if we were comparing the ASCII string to itself.
	STAssertFalse([[AIWiredString stringWithUTF8String:sampleUTF8String] isEqual:[NSString stringWithUTF8String:sampleASCIIString]], @"AIWiredString instance didn't compare equal to an equal NSString instance");
	STAssertFalse([[NSString stringWithUTF8String:sampleUTF8String] isEqual:[AIWiredString stringWithUTF8String:sampleASCIIString]], @"NSString instance didn't compare equal to an equal AIWiredString instance");
}

//-hash
- (void) testHash {
	STAssertEquals([[AIWiredString stringWithUTF8String:sampleUTF8String] hash], [[NSString stringWithUTF8String:sampleUTF8String] hash], @"AIWiredString's -hash method returned a different hash number than NSString's -hash method did");
}
- (void) testEmptyHash {
	STAssertEquals([[AIWiredString stringWithUTF8String:""] hash], [[NSString stringWithUTF8String:""] hash], @"AIWiredString's -hash method returned a different hash number than NSString's -hash method did");
}

@end
