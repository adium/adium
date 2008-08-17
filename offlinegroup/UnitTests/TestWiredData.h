//
//  TestWiredData.h
//  Adium
//
//  Created by Peter Hosey on 2008-07-05.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface TestWiredData : SenTestCase {

}

#pragma mark Creation

- (void) testAutoreleasedData;
- (void) testAutoreleasedDataWithBytes;
- (void) testAutoreleasedDataWithNoBytes;
- (void) testAutoreleasedDataWithNULLBytes;
- (void) testAutoreleasedDataWithNULLBytesZeroLength;
- (void) testInit;
- (void) testInitWithBytes;
- (void) testInitWithNoBytes;
- (void) testInitWithNULLBytes;

- (void) testInitWithData;
- (void) testInitWithEmptyData;
- (void) testInitWithNilData;

#pragma mark Subdata

- (void) testSubdataWithEntireRange;
- (void) testSubdataWithRange;
- (void) testSubdataWithZeroRange;
//Range begins within the receiver, but extends beyond it.
- (void) testSubdataWithPartiallyInvalidRange;
//Range begins beyond the receiver.
- (void) testSubdataWithInvalidRange;
- (void) testSubdataWithInvalidZeroRange;

#pragma mark Extraction to a new buffer

- (void) testGetBytes;
- (void) testGetBytesToNULL;
- (void) testGetBytesLength;
- (void) testGetBytesToNULLLength;
- (void) testGetBytesZeroLength;
- (void) testGetBytesToNULLZeroLength;
- (void) testGetBytesEntireRange;
- (void) testGetBytesToNULLEntireRange;
- (void) testGetBytesRange;
- (void) testGetBytesToNULLRange;
- (void) testGetBytesZeroRange;
- (void) testGetBytesToNULLZeroRange;
- (void) testGetBytesPartiallyInvalidRange;
- (void) testGetBytesToNULLPartiallyInvalidRange;
- (void) testGetBytesInvalidRange;
- (void) testGetBytesToNULLInvalidRange;
- (void) testGetBytesInvalidZeroRange;
- (void) testGetBytesToNULLInvalidZeroRange;

#pragma mark Comparison

- (void) testHash;

- (void) testIsEqualToEqualData;
- (void) testIsNotEqualToData;
- (void) testIsEqualToNilData;
- (void) testIsEqual;
- (void) testIsNotEqual;
- (void) testIsEqualToNil;

@end
