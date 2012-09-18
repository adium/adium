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
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIStatusIconSetDidChangeNotification
										 object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIServiceIconSetDidChangeNotification
										 object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AIStatusIconSetDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AIServiceIconSetDidChangeNotification object:nil];
	[self _destroyMenuItems];
}

/*!
 * @brief Returns an array of menu items
 */
- (NSArray *)menuItems
{
	if(!menuItems){
		menuItems = [self buildMenuItems];
	}
	
	return menuItems;
}

/*!
 * @brief Returns a menu containing our menu items
 *
 * Remember that menu items can only be in one menu at a time, so if you use this function you cannot do anything
 * manually with the menu items
 */
- (NSMenu *)menu
{
	if(!menu) {
		menu = [[NSMenu alloc] init];

		[menu setMenuChangedMessagesEnabled:NO];
		for (NSMenuItem *menuItem in self.menuItems)
			[menu addItem:menuItem];
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
	for (NSMenuItem *menuItem in self.menuItems) {
		if ([menuItem representedObject] == object) {
			return menuItem;
		} else if ([menuItem submenu]) {
			for (NSMenuItem *submenuItem in menuItem.submenu.itemArray) {
				if ([submenuItem representedObject] == object)
					return submenuItem;
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
	menu = nil;
	menuItems = nil;	
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
	[statusIcon drawInRect:compositeRect atSize:[statusIcon size] position:IMAGE_POSITION_LEFT fraction:1.0f];
	[secondaryIcon drawInRect:compositeRect atSize:[secondaryIcon size] position:IMAGE_POSITION_RIGHT fraction:1.0f];
	[composite unlockFocus];
	
	return composite;
}

@end
