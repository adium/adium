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

#import "AIArrayAdditions.h"

@implementation NSArray (AIArrayAdditions)

- (BOOL)containsObjectIdenticalTo:(id)obj
{
	return ([self indexOfObjectIdenticalTo:obj] != NSNotFound);
}

//Custom collection operator: @first
- (id)_firstForKeyPath:(NSString*)keyPath
{
	NSArray *array = [self valueForKeyPath:keyPath];
	if ([array respondsToSelector:@selector(objectAtIndex:)] &&
		[array respondsToSelector:@selector(count)]) {
		if ([array count])
			return [array objectAtIndex:0];
	}
	
	return nil;
}

// Returns an array from the owners bundle with the specified name
+ (NSArray *)arrayNamed:(NSString *)name forClass:(Class)inClass
{
	return [NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:inClass] URLForResource:name withExtension:@"plist"]];
}

- (NSComparisonResult)compare:(NSArray *)other
{
	NSComparisonResult result = NSOrderedSame;

	NSEnumerator *selfEnum = [self objectEnumerator], *otherEnum = [other objectEnumerator];
	id selfObj, otherObj = nil;
	while (result == NSOrderedSame) {
		selfObj = [selfEnum nextObject];
		otherObj = [otherEnum nextObject];
		if (!selfObj || !otherObj)
			break;

		result = [selfObj compare:otherObj];
	}

	/* If the result is the same throughout, all items which were compared were the same.
	 * If one array has more items than the other, the larger array should be ordered first.
	 * This is rapidly detected by checking if one array was exhasted before the other.
	 */
	if (result == NSOrderedSame) {
		if (selfObj && !otherObj) {
			result = NSOrderedDescending;
		} else if(otherObj && !selfObj) {
			result = NSOrderedAscending;
		}
	}

	return result;
}

- (BOOL)validateAsPropertyList
{
	BOOL validated = YES;

	for (id value in self) {
		Class valueClass = [value class];
		if (![value isKindOfClass:[NSString class]] &&
			![value isKindOfClass:[NSData class]] &&
			![value isKindOfClass:[NSNumber class]] &&
			![value isKindOfClass:[NSArray class]] &&
			![value isKindOfClass:[NSDictionary class]] &&
			![value isKindOfClass:[NSDate class]]) {
			NSLog(@"** Array failed validation: %@: Value %@ is a %@ but must be a string, data, number, array, dictionary, or date",
				  self, value, NSStringFromClass(valueClass));
			validated = NO;
		}

		if ([value isKindOfClass:[NSArray class]] ||[value isKindOfClass:[NSDictionary class]]) {
			BOOL successOfValue = [value validateAsPropertyList];
			if (validated) validated = successOfValue;
		}
	}
	
	return validated;
}

@end

@implementation NSMutableArray (ESArrayAdditions)

- (void)moveObject:(id)object toIndex:(NSUInteger)newIndex
{
	NSUInteger	currentIndex = [self indexOfObject:object];
	
	//if we're already there, do no work
	if (currentIndex == newIndex) 
	    return;
	
	//Move via a add and remove :(
	[self insertObject:object atIndex:newIndex];
    
	//If we shifted the old location by inserting, we need to take that into account when removing
	if(newIndex <= currentIndex)
	    currentIndex++;

	[self removeObjectAtIndex:currentIndex];
}

@end
