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

@class AIColoredBoxView, AIMiniToolbarItem;

@interface AIMiniToolbar : NSView {
    IBOutlet	NSMenu	*menu_contextualMenu;

    //Configuration / Arrangement
    NSString		*identifier;		//The string identifier of this toolbar
    NSDictionary	*representedObjects;	//The objects we're configured for
    NSArray		*itemIdentifierArray;	//Array of item identifiers (NSString)
    NSMutableArray	*itemArray;		//Array of items (AIMiniToolbarItem)
    BOOL		itemsRearranging;	//YES if our views are currently animating/rearranging
    NSImage		*toolbarBackground;
    
    //Drag tracking and receiving
    BOOL		focusedForDrag;		//YES if we are being dragged onto
    NSSize		hoverSize;		//The size of that object
    int			hoverIndex;		//The index it's hovering at

    //Dragging source
    NSSize		draggedSize;		//The item's size
    NSSize		draggedOffset;
    int			draggedIndex;		//
    AIMiniToolbarItem	*draggedItem;		//nil if we aren't dragging
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)setIdentifier:(NSString *)inIdentifier;
- (NSString *)identifier;
- (void)configureForObjects:(NSDictionary *)inObjects;
- (NSDictionary *)configurationObjects;
- (void)insertItemWithIdentifier:(NSString *)itemIdentifier atIndex:(int)index;
- (void)insertItemWithIdentifier:(NSString *)itemIdentifier atIndex:(int)index allowDuplicates:(BOOL)allowDuplicates;
- (void)removeItemAtIndex:(int)index;
- (void)initiateDragWithEvent:(NSEvent *)theEvent;
- (IBAction)customize:(id)sender;
- (NSMenu *)menuForEvent:(NSEvent *)event;

@end
