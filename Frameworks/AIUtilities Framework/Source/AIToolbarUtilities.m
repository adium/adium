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

#import "AIToolbarUtilities.h"

@implementation AIToolbarUtilities

+ (void)addToolbarItemToDictionary:(NSMutableDictionary *)theDict withIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu
{
    NSToolbarItem   *item = [self toolbarItemWithIdentifier:identifier label:label paletteLabel:paletteLabel toolTip:toolTip target:target settingSelector:settingSelector itemContent:itemContent action:action menu:menu];

    [theDict setObject:item forKey:identifier];
}

+ (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu
{
    NSToolbarItem 	*item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    NSMenuItem 		*mItem;

    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
	[item setToolTip:toolTip];

	if (target) {
		[item setTarget:target];
	}

    /* The settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
     * one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
     * (in the itemContent parameter).  Then this next line will do the right thing automatically.
	 */
    if (settingSelector && itemContent) {
        [item performSelector:settingSelector withObject:itemContent];
    }
	if (action) {
		[item setAction:action];
	}
	
    /* If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
     * we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
     * so we create a dummy NSMenuItem that has our real menu as a submenu.
	 */
    if (menu != NULL) {
        //We actually need an NSMenuItem here, so we construct one
        mItem = [[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu: menu];
        [mItem setTitle: [menu title]];
        [item setMenuFormRepresentation:mItem];
    }
    
    return item;
}

+ (NSToolbarItem *)toolbarItemFromDictionary:(NSDictionary *)theDict withIdentifier:(NSString *)itemIdentifier
{
    NSToolbarItem *item;
	NSToolbarItem *newItem;
	
	item = [theDict objectForKey:itemIdentifier];
	newItem = [[item copy] autorelease];

    if ([item view] != NULL) {
		if ([[item view] respondsToSelector:@selector(copyWithZone:)]) {
			[newItem setView:[[[item view] copy] autorelease]];

		} else {
			/* For a toolbar only used in one window at a time, it's alright for a view to not allow copying.
			 * If the view doesn't conform to NSCopying, use the _same_ view. NSToolbar's copy method will have created a new NSView
			 * and attempted to make it match to the original one.
			 */
			[newItem setView:[item view]];
		}
    }

    //If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    //view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view] != NULL) {
        [newItem setMinSize:[item minSize]];
        [newItem setMaxSize:[item maxSize]];
		
		if ([[newItem view] respondsToSelector:@selector(setToolbarItem:)]) {
			[[newItem view] setToolbarItem:newItem];
		}
    }

    return newItem;
}

@end
