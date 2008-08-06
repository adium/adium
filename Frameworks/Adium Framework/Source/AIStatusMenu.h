//
//  AIStatusMenu.h
//  Adium
//
//  Created by Evan Schoenberg on 11/23/05.
//


@class AIStatusItem;

@interface AIStatusMenu : NSObject {
	NSMutableArray	*menuItemArray;
	NSMutableSet	*stateMenuItemsAlreadyValidated;

	id				delegate;
}

+ (id)statusMenuWithDelegate:(id)inDelegate;
- (void)setDelegate:(id)inDelegate;

- (void)delegateWillReplaceAllMenuItems;
- (void)delegateCreatedMenuItems:(NSArray *)addedMenuItems;
- (void)rebuildMenu;

+ (NSMenu *)staticStatusStatesMenuNotifyingTarget:(id)target selector:(SEL)selector;
+ (NSString *)titleForMenuDisplayOfState:(AIStatusItem *)statusState;

@end

@interface NSObject (AIStatusMenuDelegate)
//Required
- (void)statusMenu:(AIStatusMenu *)statusMenu didRebuildStatusMenuItems:(NSArray *)inMenuItems;

//Optional
- (void)statusMenu:(AIStatusMenu *)statusMenu willRemoveStatusMenuItems:(NSArray *)inMenuItems;
@end
