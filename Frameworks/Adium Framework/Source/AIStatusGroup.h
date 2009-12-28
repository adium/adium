//
//  AIStatusGroup.h
//  Adium
//
//  Created by Evan Schoenberg on 11/23/05.
//

#import <Adium/AIStatusItem.h>

@class AIStatus;

@interface AIStatusGroup : AIStatusItem {
	NSMutableArray		*containedStatusItems;
	NSMutableSet		*_flatStatusSet;
	NSMutableArray		*_sortedContainedStatusItems;
	
	int					delaySavingAndNotification;
}

+ (id)statusGroup;
+ (id)statusGroupWithContainedStatusItems:(NSArray *)inContainedObjects;

- (void)setContainedStatusItems:(NSArray *)inContainedStatusItems;

- (void)addStatusItem:(AIStatusItem *)inStatusItem atIndex:(NSUInteger)index;
- (void)removeStatusItem:(AIStatusItem *)inStatusItem;
- (NSUInteger)moveStatusItem:(AIStatusItem *)statusState toIndex:(NSUInteger)destIndex;
- (void)replaceExistingStatusState:(AIStatus *)oldStatusState withStatusState:(AIStatus *)newStatusState;

- (NSArray *)containedStatusItems;
- (AIStatus *)anyContainedStatus;
- (NSSet *)flatStatusSet;
- (NSMenu *)statusSubmenuNotifyingTarget:(id)target action:(SEL)selector;

- (void)setDelaySavingAndNotification:(BOOL)inShouldDelay;
- (BOOL)enclosesStatusState:(AIStatus *)inStatusState;
- (BOOL)enclosesStatusStateInSet:(NSSet *)inSet;

+ (void)sortArrayOfStatusItems:(NSMutableArray *)inArray context:(void *)context;

@end
