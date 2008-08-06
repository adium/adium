/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*
	Delegate method:
		- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
*/

#import "AIMutableOwnerArray.h"
#import "AITigerCompatibility.h"

@interface AIMutableOwnerArray (PRIVATE)
- (id)_objectWithHighestPriority;
- (void)_moveObjectToFront:(int)objectIndex;
- (void)_createArrays;
- (void)_destroyArrays;
- (void)mutableOwnerArray:(AIMutableOwnerArray *)mutableOwnerArray didSetObject:(id)anObject withOwner:(id)inOwner;
@end

@implementation AIMutableOwnerArray

//Init
- (id)init
{
	if ((self = [super init])) {
		contentArray = nil;
		ownerArray = nil;
		priorityArray = nil;
		valueIsSortedToFront = NO;
		delegate = nil;
	}

	return self;
}

//Dealloc
- (void)dealloc
{
	delegate = nil;
	
    [self _destroyArrays];
    [super dealloc];
}


- (NSString *)description
{
	NSMutableString	*desc = [[NSMutableString alloc] initWithFormat:@"<%@: %x: ", NSStringFromClass([self class]), self];
	NSEnumerator	*enumerator = [contentArray objectEnumerator];
	id				object;
	int				i = 0;
	
	while ((object = [enumerator nextObject])) {
		[desc appendFormat:@"(%@:%@:%@)%@", [ownerArray objectAtIndex:i], object, [priorityArray objectAtIndex:i], (object == [contentArray lastObject] ? @"" : @", ")];
		i++;
	}
	[desc appendString:@">"];
	
	return [desc autorelease];
}


//Value Storage --------------------------------------------------------------------------------------------------------
#pragma mark Value Storage

- (void)setObject:(id)anObject withOwner:(id)inOwner
{
	[self setObject:anObject withOwner:inOwner priorityLevel:Medium_Priority];
}

- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
    NSUInteger	ownerIndex;
	//Keep priority in bounds
	if ((priority < Highest_Priority) || (priority > Lowest_Priority)) priority = Medium_Priority;

	//Remove any existing objects from this owner
	ownerIndex = [ownerArray indexOfObject:inOwner];
	if (ownerArray && (ownerIndex != NSNotFound)) {
		[ownerArray removeObjectAtIndex:ownerIndex];
		[contentArray removeObjectAtIndex:ownerIndex];
		[priorityArray removeObjectAtIndex:ownerIndex];
	}
	
	//Add the new object
	if (anObject) {
		//If we haven't created arrays yet, do so now
		if (!ownerArray) [self _createArrays];
		
		//Add the object
        [ownerArray addObject:inOwner];
        [contentArray addObject:anObject];
        [priorityArray addObject:[NSNumber numberWithFloat:priority]];
	}

	//Our array may no longer have the return value sorted to the front, clear this flag so it can be sorted again
	valueIsSortedToFront = NO;
	
	if (delegate && delegateRespondsToDidSetObjectWithOwnerPriorityLevel) {
		[delegate mutableOwnerArray:self didSetObject:anObject withOwner:inOwner priorityLevel:priority];
	}	
}

//The method the delegate would implement, here to make the compiler happy.
- (void)mutableOwnerArray:(AIMutableOwnerArray *)mutableOwnerArray didSetObject:(id)anObject withOwner:(id)inOwner {};

//Value Retrieval ------------------------------------------------------------------------------------------------------
#pragma mark Value Retrieval

- (id)objectValue
{
    return ((ownerArray && [ownerArray count]) ? [self _objectWithHighestPriority] : nil);
}

- (NSNumber *)numberValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest int value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			NSNumber 	*currentMax = [NSNumber numberWithInt:0];
			int			indexOfMax = 0;
			int			index = 0;
			
			//Find the object with the largest int value
			for (index = 0;index < count;index++) {
				NSNumber	*value = [contentArray objectAtIndex:index];

				if ([value compare:currentMax] == NSOrderedDescending) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [contentArray objectAtIndex:0];
		}
	}
	return 0;
}

- (int)intValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest int value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			int 	currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest int value
			for (index = 0;index < count;index++) {
				int	value = [[contentArray objectAtIndex:index] intValue];
				
				if (value > currentMax) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [[contentArray objectAtIndex:0] intValue];
		}
	}
	return 0;
}

- (double)doubleValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			double  currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest double value
			for (index = 0;index < count;index++) {
				double	value = [[contentArray objectAtIndex:index] doubleValue];
				
				if (value > currentMax) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [[contentArray objectAtIndex:0] doubleValue];
		}
	}
	
	return 0;
}

- (NSDate *)date
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			NSDate  *currentMax = nil;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the earliest date
			for (index = 0;index < count;index++) {
				NSDate	*value = [contentArray objectAtIndex:index];
				
				if ([currentMax timeIntervalSinceDate:value] > 0) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [contentArray objectAtIndex:0];
		}
	}
	return nil;
}

- (id)_objectWithHighestPriority
{
	//If we have more than one object and the object we want is not already in the front of our arrays, 
	//we need to find the object with highest priority and move it to the front
	if ([priorityArray count] != 1 && !valueIsSortedToFront) {
		NSEnumerator	*enumerator = [priorityArray objectEnumerator];
		NSNumber		*priority;
		float			currentMax = Lowest_Priority;
		int				indexOfMax = 0;
		int				index = 0;
		
		//Find the object with highest priority
		while ((priority = [enumerator nextObject])) {
			float	value = [priority floatValue];
			if (value < currentMax) {
				currentMax = value;
				indexOfMax = index;
			}
			index++;
		}

		//Move the object to the front, so we don't have to find it next time
		[self _moveObjectToFront:indexOfMax];
	}

	return [contentArray objectAtIndex:0]; 
}

//Move an object to the front of our arrays
- (void)_moveObjectToFront:(int)objectIndex
{
	if (objectIndex != 0) {
		[contentArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[ownerArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[priorityArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
	}
	valueIsSortedToFront = YES;
}


//Returns an object with the specified owner
- (id)objectWithOwner:(id)inOwner
{
    if (ownerArray && contentArray) {
        NSUInteger	index = [ownerArray indexOfObject:inOwner];
        if (index != NSNotFound) return [contentArray objectAtIndex:index];
    }
    
    return nil;
}

- (float)priorityOfObjectWithOwner:(id)inOwner
{
	if (ownerArray && priorityArray) {
        NSUInteger	index = [ownerArray indexOfObject:inOwner];
		if (index != NSNotFound) return [[priorityArray objectAtIndex:index] floatValue];
	}
	return 0.0;
}

- (id)ownerWithObject:(id)inObject
{
    if (ownerArray && contentArray) {
        NSUInteger	index = [contentArray indexOfObject:inObject];
        if (index != NSNotFound) return [ownerArray objectAtIndex:index];
    }
    
    return nil;
}

- (float)priorityOfObject:(id)inObject
{
	if (contentArray && priorityArray) {
        NSUInteger	index = [contentArray indexOfObject:inObject];
		if (index != NSNotFound) return [[priorityArray objectAtIndex:index] floatValue];
	}
	return 0.0;
}

- (NSEnumerator *)objectEnumerator
{
	return [contentArray objectEnumerator];
}

- (NSArray *)allValues
{
	return contentArray;
}

- (unsigned)count
{
    return [contentArray count];
}

//Array creation / Destruction -----------------------------------------------------------------------------------------
#pragma mark Array creation / Destruction
//We don't actually create our arrays until needed.  There are many places where a mutable owner array
//is created and not actually used to store anything, so this saves us a bit of ram.
//Create our storage arrays
- (void)_createArrays
{
    contentArray = [[NSMutableArray alloc] init];
    priorityArray = [[NSMutableArray alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
}

//Destroy our storage arrays
- (void)_destroyArrays
{
    [contentArray release]; contentArray = nil;
    [priorityArray release]; priorityArray = nil;
	[ownerArray release]; ownerArray = nil;
}

//Delegation -----------------------------------------------------------------------------------------
#pragma mark Delegation
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
	
	delegateRespondsToDidSetObjectWithOwnerPriorityLevel = [delegate respondsToSelector:@selector(mutableOwnerArray:didSetObject:withOwner:priorityLevel:)];
}

- (id)delegate
{
	return delegate;
}

@end
