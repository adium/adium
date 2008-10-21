//
//  AIAbstractListObjectMenu.m
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIAbstractListObjectMenu.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIUserIcons.h>

@interface AIAbstractListObjectMenu ()
- (void)_destroyMenuItems;
@end

@implementation AIAbstractListObjectMenu

/*!
 * @brief Init
 */
- (id)init
{
	if((self = [super init])){
		//Rebuild our menu when Adium's status or service icon set changes
		[adium.notificationCenter addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIStatusIconSetDidChangeNotification
										 object:nil];
		
		[adium.notificationCenter addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIServiceIconSetDidChangeNotification
										 object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[adium.notificationCenter removeObserver:self name:AIStatusIconSetDidChangeNotification object:nil];
	[adium.notificationCenter removeObserver:self name:AIServiceIconSetDidChangeNotification object:nil];
	[self _destroyMenuItems];

	[super dealloc];
}

/*!
 * @brief Returns an array of menu items
 */
- (NSArray *)menuItems
{
	if(!menuItems){
		menuItems = [[self buildMenuItems] retain];
	}
	
	return menuItems;
}

/*!
 * @brief Returns a menu containing our menu items
 *
 * Remember that menu items can only be in one menu at a time, so if you use this functions you cannot do anything
 * manually the menu items
 */
- (NSMenu *)menu
{
	if(!menu){
		NSEnumerator	*enumerator = [[self menuItems] objectEnumerator];
		NSMenuItem		*menuItem;
		
		menu = [[NSMenu allocWithZone:[NSMenu zone]] init];
		
		[menu setMenuChangedMessagesEnabled:NO];
		while((menuItem = [enumerator nextObject])) [menu addItem:menuItem];
		[menu setMenuChangedMessagesEnabled:YES];
	}
	
	return menu;
}

/*!
 * @brief Returns the existing menu item
 *
 * @param object 
 * @return NSMenuItem 
 */
- (NSMenuItem *)menuItemWithRepresentedObject:(id)object
{
	NSEnumerator	*enumerator = [[self menuItems] objectEnumerator];
	NSMenuItem		*menuItem;

	while ((menuItem = [enumerator nextObject])) {
		if ([menuItem representedObject] == object) {
			return [[menuItem retain] autorelease];
		} else if ([menuItem submenu]) {
			NSEnumerator	*submenuEnumerator = [[[menuItem submenu] itemArray] objectEnumerator];
			NSMenuItem		*submenuItem;
			
			while ((submenuItem = [submenuEnumerator nextObject])) {
				if ([submenuItem representedObject] == object) {
					return [[submenuItem retain] autorelease];
				}
			}
		}
	}

	return nil;
}

/*!
 * @brief Rebuild the menu
 */
- (void)rebuildMenu
{
	[self _destroyMenuItems];
}

/*!
 * @brief Destroy menu items
 */
- (void)_destroyMenuItems
{
	[menu release]; menu = nil;
	[menuItems release]; menuItems = nil;	
}


//For Subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses
/*!
 * @brief Builds and returns an array of menu items which should be in the listObjectMenu
 *
 * Subclass this method to build and return the menu items you want.
 */
- (NSArray *)buildMenuItems
{
	return [NSArray array];
}

/*!
 * @brief Returns a menu image for the object
 *
 * @param listObject The object for which an image will be created
 * @param useUserIcon If YES, the status icon and user icon will be used. If NO, the status icon and service icon will be used.
 */
- (NSImage *)imageForListObject:(AIListObject *)listObject usingUserIcon:(BOOL)useUserIcon
{
	NSImage	*statusIcon, *secondaryIcon;
	NSSize	statusSize, secondarySize, compositeSize;
	NSRect	compositeRect;
	
	//Get the service and status icons
	statusIcon = [AIStatusIcons statusIconForListObject:listObject type:AIStatusIconMenu direction:AIIconNormal];
	statusSize = [statusIcon size];
	if (useUserIcon) {
		//menuUserIconForObject
		secondaryIcon = [AIUserIcons menuUserIconForObject:listObject];
	} else {
		secondaryIcon = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconSmall direction:AIIconNormal];	
	}
	secondarySize = [secondaryIcon size];		
	
	//Composite them side by side (since we're only allowed one image in a menu and we want to see both)
	compositeSize = NSMakeSize(statusSize.width + secondarySize.width + 1,
							   statusSize.height > secondarySize.height ? statusSize.height : secondarySize.height);
	compositeRect = NSMakeRect(0, 0, compositeSize.width, compositeSize.height);
	
	//Render the image
	NSImage	*composite = [[NSImage alloc] initWithSize:compositeSize];
	[composite lockFocus];
	[statusIcon drawInRect:compositeRect atSize:[statusIcon size] position:IMAGE_POSITION_LEFT fraction:1.0];
	[secondaryIcon drawInRect:compositeRect atSize:[secondaryIcon size] position:IMAGE_POSITION_RIGHT fraction:1.0];
	[composite unlockFocus];
	
	return [composite autorelease];
}

@end
