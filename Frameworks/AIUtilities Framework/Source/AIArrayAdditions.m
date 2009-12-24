//
//  AIArrayAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 2/15/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIArrayAdditions.h"

@implementation NSArray (AIArrayAdditions)

- (BOOL)containsObjectIdenticalTo:(id)obj
{
	return ([self indexOfObjectIdenticalTo:obj] != NSNotFound);
}

// Returns an array from the owners bundle with the specified name
+ (NSArray *)arrayNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle		*ownerBundle;
    NSString		*arrayPath;
    
    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];
    
    //Open the plist file
    arrayPath = [ownerBundle pathForResource:name ofType:@"plist"];    

    return [[[NSArray alloc] initWithContentsOfFile:arrayPath] autorelease];
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

- (void)addObjectsFromArrayIgnoringDuplicates:(NSArray *)inArray
{
	for (id obj in inArray) {
		if (![self containsObject:obj]) [self addObject:obj];
	}
}

- (void)moveObject:(id)object toIndex:(unsigned)newIndex
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

//just a better name for an existing NSMutableArray method.
//this makes it uniform in style with -[NSMutableDictionary setObject:forKey:].
- (void)setObject:(id)object atIndex:(unsigned)idx
{
	[self replaceObjectAtIndex:idx withObject:object];
}

@end
