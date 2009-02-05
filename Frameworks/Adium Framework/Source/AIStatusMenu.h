//
//  AIStatusMenu.h
//  Adium
//
//  Created by Evan Schoenberg on 11/23/05.
//

@class AIStatusItem;
@protocol AIStatusMenuDelegate;

@interface AIStatusMenu : NSObject {
	NSMutableArray	*menuItemArray;
	NSMutableSet	*stateMenuItemsAlreadyValidated;

	id<AIStatusMenuDelegate>				delegate;
}

+ (id)statusMenuWithDelegate:(id<AIStatusMenuDelegate>)inDelegate;

@property (readwrite, nonatomic, assign) id<AIStatusMenuDelegate> delegate;

- (void)delegateWillReplaceAllMenuItems;
- (void)delegateCreatedMenuItems:(NSArray *)addedMenuItems;
- (void)rebuildMenu;

+ (NSMenu *)staticStatusStatesMenuNotifyingTarget:(id)target selector:(SEL)selector;
+ (NSString *)titleForMenuDisplayOfState:(AIStatusItem *)statusState;

@end

@protocol AIStatusMenuDelegate <NSObject>
- (void)statusMenu:(AIStatusMenu *)statusMenu didRebuildStatusMenuItems:(NSArray *)inMenuItems;
@optional
- (void)statusMenu:(AIStatusMenu *)statusMenu willRemoveStatusMenuItems:(NSArray *)inMenuItems;
@end
