//
//	NSMutableArrayAdditions.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-09-12.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSMutableArrayAdditions.h"
#include <objc/objc-runtime.h>

static inline NSComparisonResult compareObjectsWithSelector(id a, id b, SEL cmd);

@implementation NSMutableArray (NSMutableArrayAdditions)

- (unsigned) indexForInsortingObject:(id)obj usingSelector:(SEL)compareCmd {
	unsigned count = [self count];
	if (!count) {
		//bail now so we can assume a non-empty array later
		return 0U;
	} else if (count == 1U) {
		//bail now so we can assume an array with more than one object later
		return compareObjectsWithSelector(obj, [self objectAtIndex:0U], compareCmd) == NSOrderedDescending;
	}

	unsigned i = count / 2U;
	NSComparisonResult initialComparison = compareObjectsWithSelector(obj, [self objectAtIndex:i], compareCmd);
	if (initialComparison == NSOrderedSame) {
		/*the object to be inserted is equal to the pivot, so we can just insert it
		 *	right here.
		 */
		return i;
	}
	signed movementDirection = initialComparison;
	i += movementDirection;

	while ((i  > 0U)
	&&     (i <  count)
	&&     compareObjectsWithSelector(obj, [self objectAtIndex:i], compareCmd) == initialComparison
	) {
		i += movementDirection;
	}

	return i;
}

@end

static inline NSComparisonResult compareObjectsWithSelector(id a, id b, SEL cmd) {
	return (NSComparisonResult)objc_msgSend(a, cmd, b);
}
