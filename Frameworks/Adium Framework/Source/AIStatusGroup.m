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

#import <Adium/AIStatusGroup.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIStatusMenu.h>
#import <AIUtilities/AIMenuAdditions.h>

@implementation AIStatusGroup

NSComparisonResult statusArraySort(id objectA, id objectB, void *context);

+ (id)statusGroup
{
	return [[self alloc] init];
}

+ (id)statusGroupWithContainedStatusItems:(NSArray *)inContainedObjects
{
	AIStatusGroup *statusGroup = [self statusGroup];
	[statusGroup setContainedStatusItems:inContainedObjects];

	//Let 'em know where they stand
	[inContainedObjects makeObjectsPerformSelector:@selector(setContainingStatusGroup:)
										withObject:statusGroup];

	return statusGroup;
}

- (id)init
{
	if ((self = [super init])) {
		containedStatusItems = [[NSMutableArray alloc] init];
		_flatStatusSet = nil;
		delaySavingAndNotification = 0;
	}
	
	return self;
}

/*!
 * @brief Encode with Coder
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];

	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:containedStatusItems forKey:@"ContainedStatusItems"];

    } else {
        [encoder encodeObject:containedStatusItems];
    }
}

/*!
* @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]))
	{
		if ([decoder allowsKeyedCoding]) {
			//Can decode keys in any order		
			containedStatusItems = [[decoder decodeObjectForKey:@"ContainedStatusItems"] mutableCopy];

			//Let 'em know where they stand
			[containedStatusItems makeObjectsPerformSelector:@selector(setContainingStatusGroup:)
												  withObject:self];

		} else {
			//Must decode keys in same order as encodeWithCoder:		
			containedStatusItems = [[decoder decodeObject] mutableCopy];
		}

		if (!containedStatusItems) containedStatusItems = [[NSMutableArray alloc] init];
	}
	
	return self;
}

#pragma mark Access to contents
- (NSSet *)flatStatusSet
{
	if (!_flatStatusSet) {
		_flatStatusSet = [[NSMutableSet alloc] init];
		
		for (id statusItem in containedStatusItems) {
			if ([statusItem isKindOfClass:[AIStatus class]]) {
				[_flatStatusSet addObject:(AIStatus *)statusItem];
			} else if ([statusItem isKindOfClass:[AIStatusGroup class]]) {
				[_flatStatusSet unionSet:[(AIStatusGroup *)statusItem flatStatusSet]];
			}
		}
	}
	
	return _flatStatusSet;
}

- (NSArray *)containedStatusItems
{
	return containedStatusItems;
}

- (AIStatus *)anyContainedStatus
{
	//Pick a random contained status item
	AIStatusItem *anyStatus = ([containedStatusItems count] ?
							   [containedStatusItems objectAtIndex:(random() % [containedStatusItems count])] :
							   nil);
	
	//If it's a status group, recurse into it
	if ([anyStatus isKindOfClass:[AIStatusGroup class]]) {
		anyStatus = [(AIStatusGroup *)anyStatus anyContainedStatus];
		//XXX if we found an empty status group, we should look elsewhere if possible, iterating through the list or something.
	}
	
	return (AIStatus *)anyStatus;
}

/*!
 * @brief Returns an array of this AIStatusGroup's contents sorted via statusArraySort()
 */
- (NSArray *)sortedContainedStatusItems
{
	if (!_sortedContainedStatusItems) {
		_sortedContainedStatusItems = [containedStatusItems sortedArrayUsingFunction:statusArraySort
																			 context:(__bridge void*)containedStatusItems];
	}

	return _sortedContainedStatusItems;
}

- (BOOL)enclosesStatusState:(AIStatus *)inStatusState
{
	return ([[self flatStatusSet] containsObject:inStatusState]);
}

- (BOOL)enclosesStatusStateInSet:(NSSet *)inSet
{
	return ([[self flatStatusSet] intersectsSet:inSet]);
}

/*!
 * @brief Create a menu of the items in this group
 *
 * This should not be used for the root group, as it doesn't include the temporary and built-in items or the Custom... items.
 */
- (NSMenu *)statusSubmenuNotifyingTarget:(id)target action:(SEL)selector
{
	NSMenu			*menu = [[NSMenu alloc] init];
	NSMenuItem		*menuItem;
	AIStatusType	currentStatusType = AIAvailableStatusType;
	BOOL			addedItemForThisStatusType = NO;

	/* Create a menu item for each state.  States must first be sorted such that states of the same AIStatusType
		* are grouped together.
		*/
	for (AIStatusItem *statusState in [self sortedContainedStatusItems]) {
		AIStatusType thisStatusType = statusState.statusType;

		//We treat Invisible statuses as being the same as Away for purposes of the menu
		if (thisStatusType == AIInvisibleStatusType) thisStatusType = AIAwayStatusType;

		/* Add  a separatorItem before beginning to add items for a new statusType
		 * Sorting the menu items before enumerating means that we know our statuses are sorted first by statusType
		 */
		if ((currentStatusType != thisStatusType)) {			
			if ((currentStatusType != AIOfflineStatusType) && addedItemForThisStatusType) {
				//Add a divider
				[menu addItem:[NSMenuItem separatorItem]];
			}

			currentStatusType = thisStatusType;
		}

		menuItem = [[NSMenuItem alloc] initWithTitle:[AIStatusMenu titleForMenuDisplayOfState:statusState]
											  target:target
											  action:selector
									   keyEquivalent:@""];
		
		if ([statusState isKindOfClass:[AIStatus class]]) {
			[menuItem setToolTip:[(AIStatus *)statusState statusMessageString]];

		} else {
			/* AIStatusGroup */
			[menuItem setSubmenu:[(AIStatusGroup *)statusState statusSubmenuNotifyingTarget:target
																					 action:selector]];
		}
		[menuItem setRepresentedObject:[NSDictionary dictionaryWithObject:statusState
																   forKey:@"AIStatus"]];
		[menuItem setTag:currentStatusType];
		[menuItem setImage:[statusState menuIcon]];
		[menu addItem:menuItem];

		addedItemForThisStatusType = YES;
	}

	return menu;
}

#pragma mark Modifying contents
- (void)setContainedStatusItems:(NSArray *)inContainedStatusItems
{
	if (containedStatusItems != inContainedStatusItems) {
		containedStatusItems = [inContainedStatusItems mutableCopy];
	}
}

- (void)statusesOfContainedGroupChanged
{
	//Clear our cached sorted array so it'll resort as needed
	_sortedContainedStatusItems = nil;
	_flatStatusSet = nil;

	//Let our containing group or the status controller know that there's power in the blood
	if ([self containingStatusGroup]) {
		[[self containingStatusGroup] statusesOfContainedGroupChanged];
	} else {
		[adium.statusController savedStatusesChanged];
	}
}

- (void)containedStatusesChanged
{
	//Clear our cached sorted array so it'll resort as needed
	_sortedContainedStatusItems = nil;
	
	//Let our containing group or the status controller know that there's power in the blood
	if ([self containingStatusGroup]) {
		[[self containingStatusGroup] statusesOfContainedGroupChanged];
	} else {
		[adium.statusController savedStatusesChanged];
	}
}

#pragma mark -

/*!
 * @brief Add a status item to this group
 *
 * @param inStatusItem The item to add
 * @param index The index at which to add it, or -1 to add it at the end
 */
- (void)addStatusItem:(AIStatusItem *)inStatusItem atIndex:(NSUInteger)idx
{
	if (idx != NSNotFound && idx < [containedStatusItems count]) {
		[containedStatusItems insertObject:inStatusItem atIndex:idx];
	} else {
		[containedStatusItems addObject:inStatusItem];		
	}

	[inStatusItem setContainingStatusGroup:self];

	//Add this item or its contents to our flat status array
	if (!_flatStatusSet) _flatStatusSet = [[NSMutableSet alloc] init];

	if ([inStatusItem isKindOfClass:[AIStatus class]]) {
		[_flatStatusSet addObject:(AIStatus *)inStatusItem];
	} else if ([inStatusItem isKindOfClass:[AIStatusGroup class]]) {
		[_flatStatusSet unionSet:[(AIStatusGroup *)inStatusItem flatStatusSet]];
	}

	if (!delaySavingAndNotification) {
		[self containedStatusesChanged];
	}
}

- (void)removeStatusItem:(AIStatusItem *)inStatusItem
{
	[containedStatusItems removeObjectIdenticalTo:inStatusItem];

	//Remove this item from our flat array. If it's a group, clear the array entirely for lazy regeneration
	if ([inStatusItem isKindOfClass:[AIStatus class]]) {
		[_flatStatusSet removeObject:(AIStatus *)inStatusItem];

	} else if ([inStatusItem isKindOfClass:[AIStatusGroup class]]) {
		_flatStatusSet = nil;
	}
	
	if (!delaySavingAndNotification) {
		[self containedStatusesChanged];
	}
}

/*!
 * @brief Move a state
 *
 * Move a state that already exists in Adium's state array to another index
 *
 * @param statusState AIStatus to move
 * @param destIndex Destination index
 */
- (NSUInteger)moveStatusItem:(AIStatusItem *)statusState toIndex:(NSUInteger)destIndex
{
    NSUInteger sourceIndex = [containedStatusItems indexOfObjectIdenticalTo:statusState];

    //Remove the state
    [containedStatusItems removeObject:statusState];
	
    //Re-insert the state
    if (destIndex > sourceIndex) destIndex -= 1;
	if (destIndex > [containedStatusItems count]) destIndex = [containedStatusItems count];

    [containedStatusItems insertObject:statusState atIndex:destIndex];
	
	if (!delaySavingAndNotification) {
		[self containedStatusesChanged];
	}
	
	return destIndex;
}

/*!
* @brief Replace a state
 *
 * Replace a state in Adium's state array with another state.
 *
 * @param oldStatusState AIStatus state that is in Adium's state array
 * @param newStatusState AIStatus state with which to replace oldState
 */
- (void)replaceExistingStatusState:(AIStatus *)oldStatusState withStatusState:(AIStatus *)newStatusState
{
	if (oldStatusState != newStatusState) {
		NSUInteger idx = [containedStatusItems indexOfObject:oldStatusState];
		
		if (idx != NSNotFound && idx < [containedStatusItems count]) {
			[containedStatusItems replaceObjectAtIndex:idx withObject:newStatusState];
		}

		[newStatusState setContainingStatusGroup:self];

		if (!delaySavingAndNotification) {
			[self containedStatusesChanged];
		}
	}
}

#pragma mark Delay
- (void)setDelaySavingAndNotification:(BOOL)inShouldDelay
{
	if (inShouldDelay)
		delaySavingAndNotification++;
	else
		delaySavingAndNotification--;
	
	//Notify if we just ended a delay
	if (!delaySavingAndNotification) {
		[self containedStatusesChanged];
	}
}

#pragma mark Sorting
//Sort the status array
NSComparisonResult statusArraySort(id objectA, id objectB, void *context)
{
	AIStatusType statusTypeA = [objectA statusType];
	AIStatusType statusTypeB = [objectB statusType];
	
	//We treat Invisible statuses as being the same as Away for purposes of the menu
	if (statusTypeA == AIInvisibleStatusType) statusTypeA = AIAwayStatusType;
	if (statusTypeB == AIInvisibleStatusType) statusTypeB = AIAwayStatusType;
	
	if (statusTypeA > statusTypeB) {
		return NSOrderedDescending;
	} else if (statusTypeB > statusTypeA) {
		return NSOrderedAscending;
	} else {
		AIStatusMutabilityType	mutabilityTypeA = [objectA mutabilityType];
		AIStatusMutabilityType	mutabilityTypeB = [objectB mutabilityType];
		BOOL					isLockedMutabilityTypeA = (mutabilityTypeA == AILockedStatusState);
		BOOL					isLockedMutabilityTypeB = (mutabilityTypeB == AILockedStatusState);
		
		//Put locked (built in) statuses at the top
		if (isLockedMutabilityTypeA && !isLockedMutabilityTypeB) {
			return NSOrderedAscending;
			
		} else if (!isLockedMutabilityTypeA && isLockedMutabilityTypeB) {
			return NSOrderedDescending;
			
		} else {
			/* Check to see if either is temporary; temporary items go above saved ones and below
			* built-in ones.
			*/
			BOOL	isTemporaryA = (mutabilityTypeA == AITemporaryEditableStatusState);
			BOOL	isTemporaryB = (mutabilityTypeB == AITemporaryEditableStatusState);
			
			if (isTemporaryA && !isTemporaryB) {
				return NSOrderedAscending;
				
			} else if (isTemporaryB && !isTemporaryA) {
				return NSOrderedDescending;
				
			} else {
				BOOL	isSecondaryMutabilityTypeA = (mutabilityTypeA == AISecondaryLockedStatusState);
				BOOL	isSecondaryMutabilityTypeB = (mutabilityTypeB == AISecondaryLockedStatusState);
				
				//Put secondary locked statuses at the bottom
				if (isSecondaryMutabilityTypeA && !isSecondaryMutabilityTypeB) {
					return NSOrderedDescending;
					
				} else if (!isSecondaryMutabilityTypeA && isSecondaryMutabilityTypeB) {
					return NSOrderedAscending;
					
				} else {
					NSArray	*originalArray = (__bridge NSArray *)context;
					
					//Return them in the same relative order as the original array if they are of the same type
					NSUInteger indexA = [originalArray indexOfObjectIdenticalTo:objectA];
					NSUInteger indexB = [originalArray indexOfObjectIdenticalTo:objectB];
					
					if (indexA > indexB) {
						return NSOrderedDescending;
					} else {
						return NSOrderedAscending;
					}
				}
			}
		}
	}
}

+ (void)sortArrayOfStatusItems:(NSMutableArray *)inArray context:(void *)context
{
	[inArray sortUsingFunction:statusArraySort context:context];	
}

@end
