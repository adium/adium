//
//  AICharacterSetAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/27/06.
//

#import "AICharacterSetAdditions.h"

@implementation NSCharacterSet (AICharacterSetAdditions)
/*
 * @brief Make an immutable copy of an NSCharacterSet or NSMutableCharacterSet
 *
 * NSMutableCharacterSet's documentation states that immutable NSCharacterSets are more efficient than NSMutableCharacterSets.
 * Shark sampling demonstrates this to be true as of OS X 10.4.5.
 *
 * However, -[NSMutableCharacterSet copy] returns a new NSMutableCharacterSet which remains inefficient!
 */
- (NSCharacterSet *)immutableCopy
{
	return [[NSCharacterSet characterSetWithBitmapRepresentation:[self bitmapRepresentation]] retain];
}

@end
