//
//  AIAbstractListObjectMenu.h
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//


@class AIListObject;

@interface AIAbstractListObjectMenu : NSObject {
	NSMutableArray	*menuItems;
	NSMenu			*menu;
}

- (NSArray *)menuItems;
- (NSMenu *)menu;
- (NSMenuItem *)menuItemWithRepresentedObject:(id)object;
- (void)rebuildMenu;

//For Subclassers
- (NSArray *)buildMenuItems;
- (NSImage *)imageForListObject:(AIListObject *)listObject usingUserIcon:(BOOL)useUserIcon;

@end
