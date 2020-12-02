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

#import "AIMenuAdditions.h"

@implementation NSMenu (ItemCreationAdditions)

- (NSMenuItem *)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode
{
    NSMenuItem	*theMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aString action:aSelector keyEquivalent:charCode];
    [theMenuItem setTarget:target];

    [self addItem:theMenuItem];
    
    return [theMenuItem autorelease];
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode tag:(NSInteger)tag
{
    NSMenuItem	*theMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aString action:aSelector keyEquivalent:charCode];
    [theMenuItem setTarget:target];
	[theMenuItem setTag:tag];
	
    [self addItem:theMenuItem];
    
    return [theMenuItem autorelease];
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode representedObject:(id)object
{
    NSMenuItem	*theMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aString action:aSelector keyEquivalent:charCode];
    [theMenuItem setTarget:target];
    [theMenuItem setRepresentedObject:object];

    [self addItem:theMenuItem];
    
    return [theMenuItem autorelease];
}

- (void)removeAllItemsButFirst
{
	NSInteger count = [self numberOfItems];
	if (count > 1) {
		while (--count) {
			[self removeItemAtIndex:1];
		}
	}
}

- (void)removeAllItemsAfterIndex:(NSInteger)idx
{
	NSParameterAssert(idx < self.numberOfItems);
	
	NSInteger count = self.numberOfItems;
	while (--count > idx) {
		[self removeItemAtIndex:count];
	}
}

@end

@implementation NSMenuItem (ItemCreationAdditions)

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode
{
    if (!aString) aString = @"";
    self = [self initWithTitle:aString action:aSelector keyEquivalent:charCode];

    [self setTarget:target];
    
    return self;
}

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode representedObject:(id)object
{
    if (!aString) aString = @"";
    self = [self initWithTitle:aString action:aSelector keyEquivalent:charCode];
	
    [self setTarget:target];
    [self setRepresentedObject:object];
	
    return self;
}

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode keyMask:(unsigned int)keyMask
{
    if (!aString) aString = @"";
    self = [self initWithTitle:aString action:aSelector keyEquivalent:charCode];

    [self setTarget:target];
    [self setKeyEquivalentModifierMask:keyMask];
    
    return self;
}

/*Remove the key equivalent from a menu item
 *
 *Because of a bug with NSMenuItem (yay), we can't just do this:
 *	[menuItem_closeTab setKeyEquivalent:@""];
 *
 *Instead, we'll need to remove the menu item, remove its key
 *	equivalent, and then re-add it to the menu.  *sigh*
 */
- (void)removeKeyEquivalent
{
	NSMenu	*menu = [self menu];
	NSInteger		idx = [menu indexOfItem:self];

	[self retain];
	[menu removeItemAtIndex:idx];
	[self setKeyEquivalent:@""];
	[menu insertItem:self atIndex:idx];
	[self release];
}

- (NSComparisonResult)titleCompare:(NSMenuItem *)inMenuItem
{
	return [[self title] compare:[inMenuItem title] options:NSNumericSearch|NSCaseInsensitiveSearch];
}

@end

@implementation NSMenu (AIMenuAdditions)

- (void)setAllMenuItemsToState:(int)state
{
	NSEnumerator	*enumerator = [[self itemArray] objectEnumerator];
	NSMenuItem		*menuItem;
	while ((menuItem = [enumerator nextObject])) {
		[menuItem setState:state];
	}
}

//Finds and returns the first enabled menu item, or nil if there are none
- (NSMenuItem *)firstEnabledMenuItem
{
	NSEnumerator	*enumerator = [[self itemArray] objectEnumerator];
	NSMenuItem		*menuItem;
	
	while ((menuItem = [enumerator nextObject])) {
		if ([menuItem isEnabled]) return menuItem;
	}
	
	return nil;
}

//Swap two menu items
+ (void)swapMenuItem:(NSMenuItem *)itemA with:(NSMenuItem *)itemB
{
	if (itemA == itemB) return;

	NSMenu	*menuA  = [[itemA retain] menu];
	NSInteger		 indexA = menuA ? [menuA indexOfItem:itemA] : -1;

	NSMenu	*menuB  = [[itemB retain] menu];
	NSInteger		 indexB = menuB ? [menuB indexOfItem:itemB] : -1;

	if ((menuA == menuB) && (indexA < indexB)) {
		if (indexB > -1) {
			[menuB removeItemAtIndex:indexB];
			[menuA insertItem:itemB atIndex:indexA++];
		}
		if (indexA > -1) {
			[menuA removeItemAtIndex:indexA];
			[menuB insertItem:itemA atIndex:indexB];
		}
	} else {
		if (indexA > -1) {
			[menuA removeItemAtIndex:indexA];
			[menuB insertItem:itemA atIndex:indexB];
		}
		if (indexB > -1) {
			[menuB removeItemAtIndex:indexB];
			[menuA insertItem:itemB atIndex:indexA];
		}
	}
}

//Alternate menu items are supposed to 'collapse into' their primary item, showing only one menu item
//However, when the menu updates, they uncollapse; removing and readding both the primary and the alternate items
//makes them recollapse.
+ (void)updateAlternateMenuItem:(NSMenuItem *)alternateItem
{
    NSMenu		*containingMenu = [alternateItem menu];
    NSInteger			menuItemIndex = [containingMenu indexOfItem:alternateItem];
    NSMenuItem  *primaryItem = [containingMenu itemAtIndex:(menuItemIndex-1)];
	
	//Remove the primary item and readd it
	[primaryItem retain];
	[containingMenu removeItemAtIndex:(menuItemIndex-1)];
	[containingMenu insertItem:primaryItem atIndex:(menuItemIndex-1)];
	[primaryItem release];
	
	//Remove the alternate item and readd it
	[alternateItem retain];
    [containingMenu removeItemAtIndex:menuItemIndex];
    [containingMenu insertItem:alternateItem atIndex:menuItemIndex];
	[alternateItem release];
}

@end
