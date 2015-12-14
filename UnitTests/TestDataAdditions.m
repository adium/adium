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
#import "TestDataAdditions.h"

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
	XCTAssertEqual([subdata length], (NSUInteger)subdataLengthForSubdataTests, @"Subdata was not of expected length");

	const char *bytes = [subdata bytes];
	//Cast explanation: Character literals are of type int. XCTAssertEquals also checks that the two sides are of the same type, and const char is not int, so the assertion fails unless we cast the literals to const char.
	XCTAssertEqual(bytes[0], (const char)'b', @"Unexpected first byte of subdata: 0x%x %c", bytes[0], bytes[0]);
	XCTAssertEqual(bytes[1], (const char)'a', @"Unexpected second byte of subdata: 0x%x %c", bytes[1], bytes[1]);
	XCTAssertEqual(bytes[2], (const char)'r', @"Unexpected third byte of subdata: 0x%x %c", bytes[2], bytes[2]);
}
- (void)testSubdataToIndex {
	NSData *data = [NSData dataWithBytesNoCopy:bytesForSubdataTests length:lengthForSubdataTests freeWhenDone:NO];

	NSData *subdata = [data subdataToIndex:toIndexForSubdataTests];
	XCTAssertEqual([subdata length], (NSUInteger)subdataLengthForSubdataTests, @"Subdata was not of expected length");

	const char *bytes = [subdata bytes];
	//Cast explanation: Character literals are of type int. XCTAssertEquals also checks that the two sides are of the same type, and const char is not int, so the assertion fails unless we cast the literals to const char.
	XCTAssertEqual(bytes[0], (const char)'f', @"Unexpected first byte of subdata: 0x%x %c", bytes[0], bytes[0]);
	XCTAssertEqual(bytes[1], (const char)'o', @"Unexpected second byte of subdata: 0x%x %c", bytes[1], bytes[1]);
	XCTAssertEqual(bytes[2], (const char)'o', @"Unexpected third byte of subdata: 0x%x %c", bytes[2], bytes[2]);
}

@end
