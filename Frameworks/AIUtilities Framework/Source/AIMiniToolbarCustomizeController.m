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

#import "AIMiniToolbarCustomizeController.h"
#import "AIMiniToolbarItem.h"
#import "AIMiniToolbar.h"
#import "AIMiniToolbarTableView.h"
#import "AIVerticallyCenteredTextCell.h"
#import "AIMiniToolbarCenter.h"

#define MINI_TOOLBAR_CUSTOMIZE_NIB	@"MiniToolbarCustomize"		//Filename of the minitoolbar nib
#define TOOLBAR_CONFIG_FRAME		@"MiniToolbarConfig"		//Frame save name

@interface AIMiniToolbarCustomizeController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forToolbar:(AIMiniToolbar *)inToolbar;
@end

@implementation AIMiniToolbarCustomizeController

+ (AIMiniToolbarCustomizeController *)customizationWindowControllerForToolbar:(AIMiniToolbar *)inToolbar
{
	return [[[self alloc] initWithWindowNibName:MINI_TOOLBAR_CUSTOMIZE_NIB forToolbar:inToolbar] autorelease];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forToolbar:(AIMiniToolbar *)inToolbar
{
	NSParameterAssert(windowNibName != nil && [windowNibName length] != 0);

	if((self = [super initWithWindowNibName:windowNibName])) {
		toolbar = [inToolbar retain];
	}

	return self;
}

- (void)dealloc
{
	[toolbar release];
    
	[super dealloc];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

- (void)windowDidLoad
{
    NSEnumerator	*enumerator;
    AIMiniToolbarItem	*toolbarItem;

    //Restore the saved frame
    [[self window] setFrameUsingName:TOOLBAR_CONFIG_FRAME];
    
    //Setup the tableview
    [[tableView_items tableColumnWithIdentifier:@"icon"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
    [[tableView_items tableColumnWithIdentifier:@"label"] setDataCell:[[[AIVerticallyCenteredTextCell alloc] init] autorelease]];

    //Build our array of applicable items    
    itemImageArray = [[NSMutableArray alloc] init];
    itemArray = [[NSMutableArray alloc] init];
    enumerator = [[[AIMiniToolbarCenter defaultCenter] allItems] objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        if([toolbarItem configureForObjects:[toolbar configurationObjects]]){
            //Add the item if it applies to this toolbar's objects
            NSView	*itemView = [toolbarItem view];
            NSRect	itemFrame = [itemView frame];
            NSImage	*itemImage = [[NSImage alloc] initWithSize:itemFrame.size];
            [itemImage setFlipped:YES];

            [itemImage lockFocus];
            [itemView drawRect:NSMakeRect(0, 0, itemFrame.size.width, itemFrame.size.height)];
            [itemImage unlockFocus];

            [itemImageArray addObject:[itemImage autorelease]];
            [itemArray addObject:toolbarItem];
        }
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [itemArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier isEqualToString:@"icon"]){
        return [itemImageArray objectAtIndex:row];
		
    }else if([identifier isEqualToString:@"label"]){
        return [[itemArray objectAtIndex:row] paletteLabel];
		
    }else{
        return [itemArray objectAtIndex:row];
		
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return NO;
}

- (void)dragItemAtRow:(int)dragRow fromPoint:(NSPoint)inLocation withEvent:(NSEvent *)inEvent
{
    NSImage		*image, *opaqueImage;
    NSPasteboard	*pboard;
    AIMiniToolbarItem	*dragItem;
    NSSize		imageSize;

    dragItem = [itemArray objectAtIndex:dragRow];
    image = [itemImageArray objectAtIndex:dragRow];

    //Put information on the pasteboard
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:MINI_TOOLBAR_ITEM_DRAGTYPE, MINI_TOOLBAR_TYPE, nil] owner:self];
    [pboard setString:[dragItem identifier] forType:MINI_TOOLBAR_ITEM_DRAGTYPE];
    [pboard setString:[toolbar identifier] forType:MINI_TOOLBAR_TYPE];

    //Create an image of the item
    imageSize = [image size];
    opaqueImage = [[[NSImage alloc] initWithSize:imageSize] autorelease];
    [opaqueImage setBackgroundColor:[NSColor clearColor]];
    [opaqueImage lockFocus];
    [image dissolveToPoint:NSMakePoint(0,0) fraction:0.7];
    [opaqueImage unlockFocus];

    //Initiate the drag
    [tableView_items dragImage:opaqueImage
                            at:NSMakePoint(inLocation.x - (imageSize.width/2.0), inLocation.y + (imageSize.height/2.0) )
                        offset:NSMakeSize(0,0)
                         event:inEvent pasteboard:pboard source:self slideBack:YES];
}

- (BOOL)shouldCascadeWindows
{
	return NO;
}

- (BOOL)windowShouldClose:(id)sender
{
    //Save the frame
    [[self window] saveFrameUsingName:TOOLBAR_CONFIG_FRAME];

    [[AIMiniToolbarCenter defaultCenter] customizationDidEnd:toolbar];

    return YES;
}

@end
