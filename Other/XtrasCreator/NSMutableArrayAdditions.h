//
//	NSMutableArrayAdditions.h
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-09-12.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

@interface NSMutableArray (NSMutableArrayAdditions)

//assumes a sorted array. does the Right Thing for empty arrays.
- (unsigned) indexForInsortingObject:(id)obj usingSelector:(SEL)compareCmd;

@end
