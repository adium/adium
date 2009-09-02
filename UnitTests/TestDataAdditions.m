#import "TestDataAdditions.h"
#import "AIUnitTestUtilities.h"

#import <AIUtilities/AIDataAdditions.h>

enum {
	lengthForSubdataTests = 6U,
	fromIndexForSubdataTests = 3U,
	toIndexForSubdataTests = 3U,
	subdataLengthForSubdataTests = 3U
};
#define lengthForSubdataTests 6U
#define fromIndexForSubdataTests 3U
#define toIndexForSubdataTests 3U
#define subdataLengthForSubdataTests 3U
static char bytesForSubdataTests[lengthForSubdataTests] = { 'f', 'o', 'o', 'b', 'a', 'r' };

@implementation TestDataAdditions

- (void)testSubdataFromIndex {
	NSData *data = [NSData dataWithBytesNoCopy:bytesForSubdataTests length:lengthForSubdataTests freeWhenDone:NO];

	NSData *subdata = [data subdataFromIndex:fromIndexForSubdataTests];
	STAssertEquals([subdata length], (NSUInteger)subdataLengthForSubdataTests, @"Subdata was not of expected length");

	const char *bytes = [subdata bytes];
	//Cast explanation: Character literals are of type int. STAssertEquals also checks that the two sides are of the same type, and const char is not int, so the assertion fails unless we cast the literals to const char.
	STAssertEquals(bytes[0], (const char)'b', @"Unexpected first byte of subdata: 0x%x %c", bytes[0], bytes[0]);
	STAssertEquals(bytes[1], (const char)'a', @"Unexpected second byte of subdata: 0x%x %c", bytes[1], bytes[1]);
	STAssertEquals(bytes[2], (const char)'r', @"Unexpected third byte of subdata: 0x%x %c", bytes[2], bytes[2]);
}
- (void)testSubdataToIndex {
	NSData *data = [NSData dataWithBytesNoCopy:bytesForSubdataTests length:lengthForSubdataTests freeWhenDone:NO];

	NSData *subdata = [data subdataToIndex:toIndexForSubdataTests];
	STAssertEquals([subdata length], (NSUInteger)subdataLengthForSubdataTests, @"Subdata was not of expected length");

	const char *bytes = [subdata bytes];
	//Cast explanation: Character literals are of type int. STAssertEquals also checks that the two sides are of the same type, and const char is not int, so the assertion fails unless we cast the literals to const char.
	STAssertEquals(bytes[0], (const char)'f', @"Unexpected first byte of subdata: 0x%x %c", bytes[0], bytes[0]);
	STAssertEquals(bytes[1], (const char)'o', @"Unexpected second byte of subdata: 0x%x %c", bytes[1], bytes[1]);
	STAssertEquals(bytes[2], (const char)'o', @"Unexpected third byte of subdata: 0x%x %c", bytes[2], bytes[2]);
}

@end
