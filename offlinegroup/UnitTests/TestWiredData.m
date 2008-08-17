//
//  TestWiredData.m
//  Adium
//
//  Created by Peter Hosey on 2008-07-05.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import "TestWiredData.h"

#import <AIUtilities/AIWiredData.h>

enum { sampleLength = 29U };
static const char sampleBytes[sampleLength + 1U] = "One time it got me a cookie...";

@implementation TestWiredData

#pragma mark Creation

- (void) testAutoreleasedData {
	AIWiredData *data = [AIWiredData data];
	STAssertNotNil(data, @"+data should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"+data should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"+data should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"+data should return an empty AIWiredData object");
}
- (void) testAutoreleasedDataWithBytes {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertNotNil(data, @"+dataWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"+dataWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"+dataWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], (unsigned long)sampleLength, @"+dataWithBytes:length: should return a non-empty AIWiredData object");
}
- (void) testAutoreleasedDataWithNoBytes {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:0U];
	STAssertNotNil(data, @"+dataWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"+dataWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"+dataWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"+dataWithBytes:length: should return an empty AIWiredData object");
}
- (void) testAutoreleasedDataWithNULLBytes {
	STAssertThrows([AIWiredData dataWithBytes:NULL length:sampleLength], @"+dataWithBytes:NULL length:non-zero should throw an exception");
}
- (void) testAutoreleasedDataWithNULLBytesZeroLength {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:0U];
	STAssertNotNil(data, @"+dataWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"+dataWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"+dataWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"+dataWithBytes:NULL length:0 should return an empty AIWiredData object");
}

- (void) testInit {
	AIWiredData *data = [[AIWiredData alloc] init];
	STAssertNotNil(data, @"-init should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-init should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-init should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"-init should return an empty AIWiredData object");
	[data release];
}
- (void) testInitWithBytes {
	AIWiredData *data = [[AIWiredData alloc] initWithBytes:sampleBytes length:sampleLength];
	STAssertNotNil(data, @"-initWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-initWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-initWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], (unsigned long)sampleLength, @"-initWithBytes:length: should return a non-empty AIWiredData object");
	[data release];
}
- (void) testInitWithNoBytes {
	AIWiredData *data = [[AIWiredData alloc] initWithBytes:sampleBytes length:0U];
	STAssertNotNil(data, @"-initWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-initWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-initWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"-initWithBytes:length: should return an empty AIWiredData object");
	[data release];
}
- (void) testInitWithNULLBytes {
	STAssertThrows([[AIWiredData alloc] initWithBytes:NULL length:sampleLength], @"-initWithBytes:NULL length:non-zero should throw an exception");
}
- (void) testInitWithNULLBytesZeroLength {
	AIWiredData *data = [[AIWiredData alloc] initWithBytes:sampleBytes length:0U];
	STAssertNotNil(data, @"-initWithBytes:length: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-initWithBytes:length: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-initWithBytes:length: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"-initWithBytes:NULL length:0 should return an empty AIWiredData object");
	[data release];
}

- (void) testInitWithData {
	NSData *inputData = [NSData dataWithBytes:sampleBytes length:sampleLength];
	AIWiredData *data = [[AIWiredData alloc] initWithData:inputData];
	STAssertNotNil(data, @"-initWithData: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-initWithData: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-initWithData: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], (unsigned long)sampleLength, @"-initWithData: should return a non-empty AIWiredData object");
	[data release];
}
- (void) testInitWithEmptyData {
	NSData *inputData = [NSMutableData data];
	AIWiredData *data = [[AIWiredData alloc] initWithData:inputData];
	STAssertNotNil(data, @"-initWithData: should return an object");
	STAssertTrue([data isKindOfClass:[NSData class]], @"-initWithData: should return an NSData object");
	STAssertTrue([data isKindOfClass:[AIWiredData class]], @"-initWithData: should return an AIWiredData object");
	STAssertEquals((unsigned long)[data length], 0UL, @"-initWithData:<> should return an empty AIWiredData object");
	[data release];
}
- (void) testInitWithNilData {
	STAssertThrows([[AIWiredData alloc] initWithData:nil], @"-initWithData:nil should throw an exception");
}

#pragma mark Subdata

- (void) testSubdataWithEntireRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 0U, [data length] };
	//Cast explanation: -[NSData subdataWithRange:] is typed as returning an NSData, and GCC warns about this. However, AIWiredData should always return an AIWiredData, and we assert this later on.
	AIWiredData *subdata = (AIWiredData *)[data subdataWithRange:range];

	STAssertNotNil(subdata, @"-subdataWithRange: should return an object");
	STAssertTrue([subdata isKindOfClass:[NSData class]], @"-subdataWithRange: should return an NSData object");
	STAssertTrue([subdata isKindOfClass:[AIWiredData class]], @"-subdataWithRange: should return an AIWiredData object");
	STAssertEquals((unsigned long)[subdata length], (unsigned long)range.length, @"-subdataWithRange: should return an AIWiredData object equal in length to the input range");
	STAssertEquals(memcmp([subdata bytes] + range.location, sampleBytes + range.location, range.length), 0, @"-subdataWithRange: should return an AIWiredData object whose bytes are equal to the input bytes");
}
- (void) testSubdataWithRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 21U, 6U }; //"cookie"
	//Cast explanation: -[NSData subdataWithRange:] is typed as returning an NSData, and GCC warns about this. However, AIWiredData should always return an AIWiredData, and we assert this later on.
	AIWiredData *subdata = (AIWiredData *)[data subdataWithRange:range];

	STAssertNotNil(subdata, @"-subdataWithRange: should return an object");
	STAssertTrue([subdata isKindOfClass:[NSData class]], @"-subdataWithRange: should return an NSData object");
	STAssertTrue([subdata isKindOfClass:[AIWiredData class]], @"-subdataWithRange: should return an AIWiredData object");
	STAssertEquals((unsigned long)[subdata length], (unsigned long)range.length, @"-subdataWithRange: should return an AIWiredData object equal in length to the input range");
	STAssertEquals(memcmp([subdata bytes], sampleBytes + range.location, range.length), 0, @"-subdataWithRange: should return an AIWiredData object whose bytes are equal to the input bytes");
}
- (void) testSubdataWithZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 21U, 0U }; //Location is that of "cookie"
	//Cast explanation: -[NSData subdataWithRange:] is typed as returning an NSData, and GCC warns about this. However, AIWiredData should always return an AIWiredData, and we assert this later on.
	AIWiredData *subdata = (AIWiredData *)[data subdataWithRange:range];

	STAssertNotNil(subdata, @"-subdataWithRange: should return an object");
	STAssertTrue([subdata isKindOfClass:[NSData class]], @"-subdataWithRange: should return an NSData object");
	STAssertTrue([subdata isKindOfClass:[AIWiredData class]], @"-subdataWithRange: should return an AIWiredData object");
	STAssertEquals((unsigned long)[subdata length], (unsigned long)range.length, @"-subdataWithRange: should return an AIWiredData object equal in length to the input range");
}
- (void) testSubdataWithPartiallyInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength / 2U, sampleLength }; //Covers the latter half of the string and the half after that

	STAssertThrows([data subdataWithRange:range], @"-subdataWithRange: with a partially-invalid range should throw an exception");
}
- (void) testSubdataWithInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, sampleLength };

	STAssertThrows([data subdataWithRange:range], @"-subdataWithRange: with an invalid range should throw an exception");
}
- (void) testSubdataWithInvalidZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, 0U };

	STAssertThrows([data subdataWithRange:range], @"-subdataWithRange: with an invalid location should throw an exception");
}

#pragma mark Extraction to a new buffer

- (void) testGetBytes {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[sampleLength + 1U];
	buffer[sampleLength] = 0xFF;

	[data getBytes:buffer];

	STAssertEquals(memcmp(sampleBytes, buffer, sampleLength), 0, @"-getBytes: should faithfully copy the backing store");
	STAssertFalse(buffer[sampleLength] != 0xFF, @"-getBytes: changed more bytes than the input length");
}
- (void) testGetBytesToNULL {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];

	STAssertThrows([data getBytes:NULL], @"-getBytes:NULL should throw an exception");
}

- (void) testGetBytesLength {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[sampleLength + 1U];
	buffer[sampleLength] = 0xFF;

	[data getBytes:buffer length:sampleLength];

	STAssertEquals(memcmp(sampleBytes, buffer, sampleLength), 0, @"-getBytes:length: should faithfully copy the backing store");
	STAssertFalse(buffer[sampleLength] != 0xFF, @"-getBytes:length: changed more bytes than the input length");
}
- (void) testGetBytesToNULLLength {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[sampleLength + 1U];
	buffer[sampleLength] = 0xFF;

	STAssertThrows([data getBytes:NULL length:sampleLength], @"-getBytes:NULL length: should throw an exception");
}
- (void) testGetBytesZeroLength {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[1U];
	buffer[0U] = 0xFF;

	[data getBytes:buffer length:0U];

	STAssertFalse(buffer[0U] != 0xFF, @"-getBytes:length: changed more bytes than the input length");
}
- (void) testGetBytesToNULLZeroLength {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];

	STAssertThrows([data getBytes:NULL length:0U], @"-getBytes:NULL length: should throw an exception");
}

- (void) testGetBytesEntireRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[sampleLength + 1U];
	buffer[sampleLength] = 0xFF;
	NSRange range = { 0U, sampleLength };

	[data getBytes:buffer range:range];

	STAssertEquals(memcmp(sampleBytes, buffer + range.location, range.length), 0, @"-getBytes:range: should faithfully copy the backing store");
	STAssertFalse(buffer[range.length] != 0xFF, @"-getBytes:range: changed more bytes than the input length");
}
- (void) testGetBytesToNULLEntireRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 0U, sampleLength };

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: should throw an exception");
}
- (void) testGetBytesRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[sampleLength + 1U];
	NSRange range = { 0U, sampleLength / 2U };
	buffer[range.length] = 0xFF;

	[data getBytes:buffer range:range];

	STAssertEquals(memcmp(sampleBytes, buffer + range.location, range.length), 0, @"-getBytes:range: should faithfully copy the backing store");
	STAssertFalse(buffer[range.length] != 0xFF, @"-getBytes:range: changed more bytes than the input length");
}
- (void) testGetBytesToNULLRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 0U, sampleLength / 2U };

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: should throw an exception");
}
- (void) testGetBytesZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	unsigned char buffer[1U];
	buffer[0U] = 0xFF;
	NSRange range = { 0U, 0U };

	[data getBytes:buffer range:range];

	STAssertFalse(buffer[range.length] != 0xFF, @"-getBytes:range: changed more bytes than the input length");
}
- (void) testGetBytesToNULLZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { 0U, 0U };

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: should throw an exception");
}
- (void) testGetBytesPartiallyInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength / 2U, sampleLength }; //Covers the latter half of the string and the half after that
	unsigned char buffer[sampleLength];

	STAssertThrows([data getBytes:buffer range:range], @"-getBytes:range: with a partially-invalid range should throw an exception");
}
- (void) testGetBytesToNULLPartiallyInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength / 2U, sampleLength }; //Covers the latter half of the string and the half after that

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: with a partially-invalid range should throw an exception");
}
- (void) testGetBytesInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, sampleLength };
	unsigned char buffer[sampleLength];

	STAssertThrows([data getBytes:buffer range:range], @"-getBytes:range: with an invalid range should throw an exception");
}
- (void) testGetBytesToNULLInvalidRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, sampleLength };

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: with an invalid range should throw an exception");
}
- (void) testGetBytesInvalidZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, 0U };
	unsigned char buffer[1];

	STAssertThrows([data getBytes:buffer range:range], @"-getBytes:range: with an invalid range should throw an exception");
}
- (void) testGetBytesToNULLInvalidZeroRange {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	NSRange range = { sampleLength, 0U };

	STAssertThrows([data getBytes:NULL range:range], @"-getBytes:NULL range: with an invalid range should throw an exception");
}

#pragma mark Comparison

- (void) testHash {
	NSData *data = [NSData dataWithBytes:sampleBytes length:sampleLength];
	AIWiredData *wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];

	STAssertEquals([wiredData hash], [data hash], @"-[AIWiredData hash] didn't return the same hash that -[NSData hash] did");
}

- (void) testIsEqualToEqualData {
	NSData      *data      = [NSData      dataWithBytes:sampleBytes length:sampleLength];
	AIWiredData *wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertTrue([wiredData isEqualToData:data], @"-[AIWiredData isEqualToData:] should return YES when passed an equal NSData");
	STAssertTrue([data isEqualToData:wiredData], @"-[NSData isEqualToData:] should return YES when passed an equal AIWiredData");
}
- (void) testIsNotEqualToData {
	NSData *data;
	AIWiredData *wiredData;

	//Different length
	data      = [NSData      dataWithBytes:sampleBytes length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength / 2U];
	STAssertFalse([wiredData isEqualToData:data], @"-[AIWiredData isEqualToData:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqualToData:wiredData], @"-[NSData isEqualToData:] should return NO when passed an inequal AIWiredData");

	data      = [NSData      dataWithBytes:sampleBytes length:sampleLength / 2U];
	wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertFalse([wiredData isEqualToData:data], @"-[AIWiredData isEqualToData:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqualToData:wiredData], @"-[NSData isEqualToData:] should return NO when passed an inequal AIWiredData");

	//Same length; different bytes
	unsigned char differentBytes[sampleLength];
	for (unsigned i = 0U; i < sampleLength; ++i)
		differentBytes[i] = ~(sampleBytes[i]);

	data      = [NSData      dataWithBytes:sampleBytes    length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:differentBytes length:sampleLength];
	STAssertFalse([wiredData isEqualToData:data], @"-[AIWiredData isEqualToData:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqualToData:wiredData], @"-[NSData isEqualToData:] should return NO when passed an inequal AIWiredData");

	data      = [NSData      dataWithBytes:differentBytes length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:sampleBytes    length:sampleLength];
	STAssertFalse([wiredData isEqualToData:data], @"-[AIWiredData isEqualToData:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqualToData:wiredData], @"-[NSData isEqualToData:] should return NO when passed an inequal AIWiredData");
}
- (void) testIsEqualToNilData {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertFalse([data isEqualToData:nil], @"-isEqualToData:nil should return NO");

	data = [AIWiredData data];
	STAssertFalse([data isEqualToData:nil], @"-isEqualToData:nil should return NO");
}
- (void) testIsEqual {
	NSData      *data      = [NSData      dataWithBytes:sampleBytes length:sampleLength];
	AIWiredData *wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertTrue([wiredData isEqual:data], @"-[AIWiredData isEqual:] should return YES when passed an equal NSData");
	STAssertTrue([data isEqual:wiredData], @"-[NSData isEqual:] should return YES when passed an equal AIWiredData");
}
- (void) testIsNotEqual {
	NSData *data;
	AIWiredData *wiredData;

	//Different length
	data      = [NSData      dataWithBytes:sampleBytes length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength / 2U];
	STAssertFalse([wiredData isEqual:data], @"-[AIWiredData isEqual:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqual:wiredData], @"-[NSData isEqual:] should return NO when passed an inequal AIWiredData");

	data      = [NSData      dataWithBytes:sampleBytes length:sampleLength / 2U];
	wiredData = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertFalse([wiredData isEqual:data], @"-[AIWiredData isEqual:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqual:wiredData], @"-[NSData isEqual:] should return NO when passed an inequal AIWiredData");

	//Same length; different bytes
	unsigned char differentBytes[sampleLength];
	for (unsigned i = 0U; i < sampleLength; ++i)
		differentBytes[i] = ~(sampleBytes[i]);

	data      = [NSData      dataWithBytes:sampleBytes    length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:differentBytes length:sampleLength];
	STAssertFalse([wiredData isEqual:data], @"-[AIWiredData isEqual:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqual:wiredData], @"-[NSData isEqual:] should return NO when passed an inequal AIWiredData");

	data      = [NSData      dataWithBytes:differentBytes length:sampleLength];
	wiredData = [AIWiredData dataWithBytes:sampleBytes    length:sampleLength];
	STAssertFalse([wiredData isEqual:data], @"-[AIWiredData isEqual:] should return NO when passed an inequal NSData");
	STAssertFalse([data isEqual:wiredData], @"-[NSData isEqual:] should return NO when passed an inequal AIWiredData");
}
- (void) testIsEqualToNil {
	AIWiredData *data = [AIWiredData dataWithBytes:sampleBytes length:sampleLength];
	STAssertFalse([data isEqual:nil], @"-isEqual:nil should return NO");

	data = [AIWiredData data];
	STAssertFalse([data isEqual:nil], @"-isEqual:nil should return NO");
}

@end
