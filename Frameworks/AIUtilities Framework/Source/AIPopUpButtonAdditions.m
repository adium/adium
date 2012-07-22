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

#import "AIPopUpButtonAdditions.h"
#import "AIApplicationAdditions.h"

@implementation NSPopUpButton (AIPopUpButtonAdditions)

//Note: selectItemAtIndex will throw an exception if the menu has no items, even if index is -1
- (BOOL)selectItemWithRepresentedObject:(id)object
{
	if ([self numberOfItems] > 0) {
		NSInteger	idx = [self indexOfItemWithRepresentedObject:object];
		if (idx != -1) {
			[self selectItemAtIndex:idx];
			return YES;
		}
	}

	return NO;
}

- (BOOL)selectItemWithRepresentedObjectUsingCompare:(id)object
{
	BOOL selectedItem = NO;

	if ([self numberOfItems] > 0) {
		NSEnumerator *enumerator = [[self itemArray] objectEnumerator];
		NSMenuItem	 *menuItem;
		
		while ((menuItem = [enumerator nextObject])) {
			if ([[menuItem representedObject] compare:object] == NSOrderedSame) {
				[self selectItem:menuItem];
				selectedItem = YES;
				break;
			}
		}
	}
	
	return selectedItem;	
}

- (void)autosizeAndCenterHorizontally
{
    NSString *buttonTitle = [self titleOfSelectedItem];
    if (buttonTitle && [buttonTitle length]) {
        [self sizeToFit];
        NSRect menuFrame = [self frame];
        menuFrame.origin.x = ([[self superview] frame].size.width / 2) - (menuFrame.size.width / 2);
        [self setFrame:menuFrame];   
        [[self superview] display];
    }
}

@end

@implementation NSPopUpButtonCell (AIPopUpButtonAdditions)

- (BOOL)selectItemWithRepresentedObject:(id)object
{
    NSInteger	idx = [self indexOfItemWithRepresentedObject:object];
	if (idx != NSNotFound) {
		[self selectItemAtIndex:idx];
		return YES;
	}
	
	return NO;
}

@end
