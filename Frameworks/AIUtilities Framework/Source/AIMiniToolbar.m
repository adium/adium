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

#import "AIMiniToolbar.h"
#import "AIMiniToolbarItem.h"

#define MINI_TOOLBAR_POOF		@"poof"			//Filename of the poof animation
#define MINI_TOOLBAR_MENU_NIB		@"MiniToolbarMenu"	//Filename of the minitoolbar nib
#define MINI_TOOLBAR_ITEM_SPACING	-2 //3			//Space between toolbar items
#define MINI_TOOLBAR_EDGE_SPACING	0 //2
#define MINI_TOOLBAR_FPS		30.0			//Animation speed

@interface AIMiniToolbar (PRIVATE)
- (NSArray *)rebuildItems;
- (void)smoothlyArrangeItems;
- (void)arrangeItemsTimer:(NSTimer *)inTimer;
- (BOOL)arrangeItems:(NSArray *)targetItemArray absolute:(BOOL)absolute;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
- (void)setFocusedForDrag:(BOOL)value;
- (void)registerForNotifications;
@end

@implementation AIMiniToolbar

//Configuration ----------------------------------------------------------------------
//Init the toolbar view
- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		//Init
		identifier = nil;
		representedObjects = nil;
		itemIdentifierArray = nil;
		itemArray = nil;
		itemsRearranging = NO;
		toolbarBackground = [[NSImage imageNamed:@"toolbar_Background" forClass:[self class]] retain];

		//setup the toolbar view
		[self registerForDraggedTypes:[NSArray arrayWithObject:MINI_TOOLBAR_ITEM_DRAGTYPE]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:self];
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [itemIdentifierArray release];
    [itemArray release];
    [toolbarBackground release];
    [identifier release];
    [representedObjects release];

    [super dealloc];
}

//Sets the identifier of this toolbar
- (void)setIdentifier:(NSString *)inIdentifier
{
    if(identifier != inIdentifier){
        //Remove our current observers
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AIMiniToolbar_ItemsChanged object:identifier];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AIMiniToolbar_RefreshItem object:nil];
        

        [identifier release];
        identifier = [inIdentifier retain];
        
        //Since our toolbar type has changed, we have to fetch our new item set and rebuild
        [self rebuildItems];
        [self arrangeItems:nil absolute:YES];
        
        //register for the new notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolbarItemsChanged:) name:AIMiniToolbar_ItemsChanged object:identifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolbarRefreshItem:) name:AIMiniToolbar_RefreshItem object:nil];
    }
}

//Returns the identifier
- (NSString *)identifier
{
    return identifier;
}

//Configure this toolbar for the specified objects
//pass nil to reconfigure for the last used objects
- (void)configureForObjects:(NSDictionary *)inObjects
{
    NSEnumerator	*itemEnumerator;
    AIMiniToolbarItem	*item;

    //Save the objects
    if(inObjects == nil){
        inObjects = representedObjects;
    }else if(representedObjects != inObjects){
        [representedObjects release];
        representedObjects = [inObjects retain];
    }

    //Configure all our items for the objects
    itemEnumerator = [itemArray objectEnumerator];
    while((item = [itemEnumerator nextObject])){
        [item configureForObjects:inObjects];
    }
}
- (NSDictionary *)configurationObjects{
    return representedObjects;
}

//Add an item to this toolbar
- (void)insertItemWithIdentifier:(NSString *)itemIdentifier atIndex:(int)index
{
    [self insertItemWithIdentifier:itemIdentifier atIndex:index allowDuplicates:YES];
}

//Add an item to this toolbar
- (void)insertItemWithIdentifier:(NSString *)itemIdentifier atIndex:(int)index allowDuplicates:(BOOL)allowDuplicates
{
    NSMutableArray 	*newItemArray = [[itemIdentifierArray mutableCopy] autorelease];
    AIMiniToolbarItem	*existingItem;
    int			existingIndex;

    existingIndex = [itemIdentifierArray indexOfObject:itemIdentifier];
    if(existingIndex != NSNotFound) existingItem = [itemArray objectAtIndex:existingIndex];

    //Handle duplicate items
    if(existingIndex == NSNotFound || ([existingItem allowsDuplicatesInToolbar] && allowDuplicates)){
        //Add the new toolbar item to our list
        [newItemArray insertObject:itemIdentifier atIndex:index];
        
    }else{
        //Move the existing item (since it's already in the toolbar)
        [newItemArray removeObjectAtIndex:existingIndex];
        if(existingIndex < index){
            [newItemArray insertObject:itemIdentifier atIndex:index - 1];
        }else{
            [newItemArray insertObject:itemIdentifier atIndex:index];
        }

    }
    
    //Send the new item list to the toolbar center
    [[AIMiniToolbarCenter defaultCenter] setItems:newItemArray forToolbar:identifier];
}

//Remove an item from this toolbar
- (void)removeItemAtIndex:(int)index
{
    NSMutableArray	*newItemArray = [[itemIdentifierArray mutableCopy] autorelease];

    //Remove the item from our list
    [newItemArray removeObjectAtIndex:index];
    
    //Notify the toolbar center of the changes (so it can change other toolbars of our type)
    [[AIMiniToolbarCenter defaultCenter] setItems:newItemArray forToolbar:identifier];
}

//Customize this toolbar
- (IBAction)customize:(id)sender
{
    [[AIMiniToolbarCenter defaultCenter] customizeToolbar:self];
}

//Display our contextual menu
- (NSMenu *)menuForEvent:(NSEvent *)event
{
    [NSBundle loadNibNamed:MINI_TOOLBAR_MENU_NIB owner:self];
    return [menu_contextualMenu autorelease];
}

//Notifications ----------------------------------------------------------------------
//Refresh an item on the toolbar
- (void)toolbarRefreshItem:(NSNotification *)notification
{
    NSString	*itemIdentifier = [notification object];
    
    if(itemIdentifier == nil){ //Refresh the whole toolbar
        //[self setKeyboardFocusRingNeedsDisplayInRect:[self frame]];
        [self setNeedsDisplay:YES];
    
    }else{ //Refresh a single item
        int index = [itemIdentifierArray indexOfObject:itemIdentifier];

        if(index != NSNotFound){
            [[[itemArray objectAtIndex:index] view] setNeedsDisplay:YES];
        }
    }
}


// Drawing ----------------------------------------------------------------------
//Draw
- (void)drawRect:(NSRect)rect
{
    int	imageWidth;

    //Fill the rect with aqua stripes
    if(![[self window] isTextured]){ //Don't do this on brushed metal windows
        imageWidth = [toolbarBackground size].width;
        if(toolbarBackground && imageWidth){
            int xOffset = 0;
            while(xOffset < rect.size.width){
                [toolbarBackground compositeToPoint:NSMakePoint(xOffset,0) operation:NSCompositeSourceOver];
                xOffset += imageWidth;
            }
        }
    }
    
    //Draw the 'acceptance' focus ring
    //if(focusedForDrag || [[AIMiniToolbarCenter defaultCenter] customizing:self]){
    //    NSSetFocusRingStyle(NSFocusRingOnly);
    //    NSRectFill(rect);
    //}

    //Draw our contents
    [super drawRect:rect];
}


//Private ---------------------------------------------------------------------------------
//Toolbar arrangement and updating --------------------------------------------------------
//Invoked when the items of a toolbar have changed
- (void)toolbarItemsChanged:(NSNotification *)notification
{
    NSArray	*newViews;

    //Rebuild our item views
    newViews = [self rebuildItems];

    if(draggedItem){
        if(!itemsRearranging) [self smoothlyArrangeItems];
    }else{
        [self arrangeItems:nil absolute:YES]; //Force all our items into the correct spot
    }

    //Reconfigure our toolbar
    [self configureForObjects:nil];
}

- (void)frameChanged:(NSNotification *)notification
{
    [self arrangeItems:nil absolute:YES];
}

//Rebuild the items and views (call when the item set changes)
//Returns an array of the AIMiniToolbarItems that are new
- (NSArray *)rebuildItems
{
    AIMiniToolbarCenter	*toolbarCenter = [AIMiniToolbarCenter defaultCenter];
    NSMutableArray	*newItemArray;
    NSMutableArray	*createdItemArray;
    NSEnumerator	*enumerator;
    NSString		*itemIdentifier;
    
    //Our goal here is to:
    // - Add the views of any new items
    // - Remove the views of any removed items
    // - Leave all similar items in place
    
    //Set up
    newItemArray = [NSMutableArray array];
    createdItemArray = [NSMutableArray array];
    [self removeAllSubviews];				//Flush out existing views

    //Get the new list of identifiers
    [itemIdentifierArray release]; itemIdentifierArray = [[toolbarCenter itemsForToolbar:identifier] retain];
    if(!itemIdentifierArray) itemIdentifierArray = [[NSArray alloc] init];

    //Go through each identifier
    enumerator = [itemIdentifierArray objectEnumerator];
    while((itemIdentifier = [enumerator nextObject])){
        AIMiniToolbarItem	*existingItem = nil;
        NSEnumerator		*itemEnumerator;
        AIMiniToolbarItem	*item;

        //Go through each toolbarItem in our array
        itemEnumerator = [itemArray objectEnumerator];
        while((item = [itemEnumerator nextObject])){
            
            if([itemIdentifier isEqualToString:[item identifier]]){
                existingItem = item;
                break;
            }
        }

        if(!existingItem){
            //Request a new item
            existingItem = [toolbarCenter itemWithIdentifier:itemIdentifier];

            if(existingItem){ //It is possible for the item to no longer exist
                //Add this to our list of newly created items
                [newItemArray addObject:existingItem];
                [createdItemArray addObject:existingItem];
            }
        }else{
            //remove it so we don't try and move it again
            [newItemArray addObject:existingItem];
            [itemArray removeObject:existingItem];  
        }

        if(existingItem){
            //Add the item to our array and as a subview
            [self addSubview:[existingItem view]];
        }
    }

    //Save the new array and clean up
    [itemArray release]; itemArray = [newItemArray retain];
    
    return createdItemArray;
}

//Starts a smooth animation to put the views in their correct places
- (void)smoothlyArrangeItems
{
    if(!itemsRearranging){
        itemsRearranging = YES;
        [NSTimer scheduledTimerWithTimeInterval:(1.0/MINI_TOOLBAR_FPS) target:self selector:@selector(arrangeItemsTimer:) userInfo:nil repeats:NO];
    }
}

//Arranges the views for 1 frame, continuing if they aren't finished
- (void)arrangeItemsTimer:(NSTimer *)inTimer
{
    BOOL finished = [self arrangeItems:nil absolute:NO];

    //If all the items aren't in place, we set ourself to adjust them again
    if(!finished){
        itemsRearranging = YES;
        [NSTimer scheduledTimerWithTimeInterval:(1.0/MINI_TOOLBAR_FPS) target:self selector:@selector(arrangeItemsTimer:) userInfo:nil repeats:NO];
    }else{
        itemsRearranging = NO;
    }
}


//Re-arrange the passed items (AIMiniToolbarItems) to their correct positions
//Pass nil to re-arrange all views
//returns YES if finished.
//Pass NO in absolute for a partial movement
- (BOOL)arrangeItems:(NSArray *)targetItemArray absolute:(BOOL)absolute
{
    NSEnumerator	*enumerator;
    AIMiniToolbarItem	*toolbarItem;
    NSMutableArray	*flexItems;
    BOOL		finished = YES;
    NSRect		selfFrame = [self frame];
    int			xLocation;
    int			index;
    int			totalWidth;


    //--Handle flexible toolbar items--
    totalWidth = MINI_TOOLBAR_EDGE_SPACING * 2;
    flexItems = [NSMutableArray array];

    //Find the flexible width items, and calculate the width of all other items
    enumerator = [itemArray objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        if([toolbarItem flexibleWidth]){
            [flexItems addObject:toolbarItem];
        }else{
            totalWidth += [[toolbarItem view] frame].size.width + MINI_TOOLBAR_ITEM_SPACING;
        }
    }
    if(hoverIndex != -1) totalWidth += hoverSize.width + MINI_TOOLBAR_ITEM_SPACING;

    totalWidth -= MINI_TOOLBAR_ITEM_SPACING; //remove that last spacing we added

    //Divide the remaining width among the flexible views
    if([flexItems count]){
        int flexWidth = (selfFrame.size.width - totalWidth) / [flexItems count];
        
        enumerator = [flexItems objectEnumerator];
        while((toolbarItem = [enumerator nextObject])){
            NSView	*itemView = [toolbarItem view];
        
            [itemView setFrameSize:NSMakeSize(flexWidth, [itemView frame].size.height)];
        }
    }
    //----

    index = 0;
    xLocation = MINI_TOOLBAR_EDGE_SPACING;
    enumerator = [itemArray objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        NSView	*itemView = [toolbarItem view];
        NSRect	itemFrame = [itemView frame];
        NSPoint	origin;

        //Make a gap if the user is dragging something
        if(index == hoverIndex){
            xLocation += hoverSize.width + MINI_TOOLBAR_ITEM_SPACING;
        }

        //Get the object's frame & center it vertically
        origin = NSMakePoint(xLocation, (selfFrame.size.height - itemFrame.size.height) / 2.0 );

        //Calculate the new position
        if(!absolute){
            if(origin.x > itemFrame.origin.x){
                int distance = (origin.x - itemFrame.origin.x) * 0.5;
                if(distance > 7) distance = 7;
                if(distance < 1) distance = 1;
            
                origin.x = itemFrame.origin.x + distance;
                
                if(finished) finished = NO;
            }else if(origin.x < itemFrame.origin.x){
                int distance = (itemFrame.origin.x - origin.x) * 0.5;
                if(distance > 7) distance = 7;
                if(distance < 1) distance = 1;
    
                origin.x = itemFrame.origin.x - distance;
                if(finished) finished = NO;
            }
        }

        //Move the object
        if(targetItemArray == nil || [targetItemArray indexOfObject:toolbarItem] != NSNotFound){
            [itemView setFrame:NSMakeRect(origin.x, origin.y, itemFrame.size.width, itemFrame.size.height)];
        }
        
        if(itemFrame.size.width != 0){ //Leave no padding space for "hidden" items
            xLocation += itemFrame.size.width + MINI_TOOLBAR_ITEM_SPACING;
        }
        index++;
    }
    
    //Mark the toolbar for redisplay
    [self setNeedsDisplay:YES];
    //if(focusedForDrag || [[AIMiniToolbarCenter defaultCenter] customizing:self]){
    //    [self setKeyboardFocusRingNeedsDisplayInRect:[self frame]];
    //}

    return finished;
}

//Set whether we're focused for a drag or not
- (void)setFocusedForDrag:(BOOL)value
{
    if(focusedForDrag != value){
        focusedForDrag = value;
        //[self setKeyboardFocusRingNeedsDisplayInRect:[self frame]];
        //[self setNeedsDisplay:YES];
    }
}



//Drag tracking methods ------------------------------------------------------------------------
//Called when a drag enters this toolbar, begin parting the items to make space
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pasteboard = [sender draggingPasteboard];
    NSString		*toolbarIdentifier = [pasteboard stringForType:MINI_TOOLBAR_TYPE];
    
    //We only focus/accept a drag from ourself or the customization palette
    if(toolbarIdentifier && [identifier isEqualToString:toolbarIdentifier]){
        //Start tracking the drag
        hoverSize = [[sender draggedImage] size];
        [self setFocusedForDrag:YES];
    }

    return NSDragOperationNone;
}

//Called when the drag moves within this toolbar
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pasteboard = [sender draggingPasteboard];
    NSString		*toolbarIdentifier = [pasteboard stringForType:MINI_TOOLBAR_TYPE];
    NSDragOperation	dragOperation = NSDragOperationNone;
    
    if(toolbarIdentifier && [identifier isEqualToString:toolbarIdentifier]){
        NSEnumerator		*enumerator = [itemArray objectEnumerator];
        AIMiniToolbarItem	*toolbarItem;
        int			dragXLocation = [sender draggingLocation].x - [self frame].origin.x;
        int			lastLocation = 0;
        int			index = -1;
        
        //Figure out where the user is hovering the toolbar item
        while((toolbarItem = [enumerator nextObject])){
            NSRect	 frame = [[toolbarItem view] frame];
        
            if((dragXLocation > lastLocation) && (dragXLocation < frame.origin.x + (frame.size.width / 2.0) ) ){
                index = [itemArray indexOfObject:toolbarItem];
                break;
            }
    
            lastLocation = frame.origin.x;
        }
        //If they're way off right, append the item to the toolbar's end 
        if(index == -1 && dragXLocation > lastLocation) index = [itemArray count];
    
        //Set the new drag index
        if(hoverIndex != index){
            hoverIndex = index;
            if(!itemsRearranging){
                [self smoothlyArrangeItems];
            }
        }

        if(index != -1){
            dragOperation = NSDragOperationPrivate;
        }
    }

    return dragOperation;
}

//Called when the drag exits this toolbar, restore items to their normal positions
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pasteboard = [sender draggingPasteboard];
    NSString		*toolbarIdentifier = [pasteboard stringForType:MINI_TOOLBAR_TYPE];

    //We only focus/accept a drag from ourself or the customization palette
    if(toolbarIdentifier && [identifier isEqualToString:toolbarIdentifier]){
        //Stop tracking the drag
        hoverIndex = -1;
        [self setFocusedForDrag:NO];
    
        //Let all the views settle back into place
        if(!itemsRearranging){
            [self smoothlyArrangeItems];
        }
    }
}

//Dragging Source ---------------------------------------------------------------------------------
//Initiate a drag
- (void)initiateDragWithEvent:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int			viewIndex = 0;
    NSRect		viewFrame;
    NSEnumerator	*enumerator;
    AIMiniToolbarItem	*toolbarItem;

    //Find the subview that was clicked
    draggedItem = nil;
    enumerator = [itemArray objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        viewFrame = [[toolbarItem view] frame];
        if(NSPointInRect(clickLocation, viewFrame)){
            draggedItem = toolbarItem;
            draggedIndex = viewIndex;
            break;
        }
        
        viewIndex++;
    }
    
    if(draggedItem){
        NSImage		*image, *opaqueImage;
        NSRect		imageRect;
        NSPasteboard 	*pboard;

        //Put information on the pasteboard
        pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        [pboard declareTypes:[NSArray arrayWithObjects:MINI_TOOLBAR_ITEM_DRAGTYPE, MINI_TOOLBAR_TYPE, MINI_TOOLBAR_SOURCE, nil] owner:self];
        [pboard setString:[draggedItem identifier] forType:MINI_TOOLBAR_ITEM_DRAGTYPE];
        [pboard setString:identifier forType:MINI_TOOLBAR_TYPE];
        [pboard setString:identifier forType:MINI_TOOLBAR_SOURCE];

        //Create an image of the item
        image = [[[NSImage alloc] initWithSize:viewFrame.size] autorelease];
        imageRect = NSMakeRect(0,0,viewFrame.size.width,viewFrame.size.height);
        [image lockFocus];
            [[draggedItem view] drawRect:imageRect];
        [image unlockFocus];

        opaqueImage = [[[NSImage alloc] initWithSize:viewFrame.size] autorelease];
        [opaqueImage setBackgroundColor:[NSColor clearColor]];
        [opaqueImage lockFocus];
            [image dissolveToPoint:NSMakePoint(0,0) fraction:0.7];
        [opaqueImage unlockFocus];
	[opaqueImage setFlipped:YES];

        //Perform the drag
        draggedOffset = NSMakeSize((clickLocation.x - viewFrame.origin.x), (clickLocation.y - viewFrame.origin.y));
        [self dragImage:opaqueImage
                     at:NSMakePoint(clickLocation.x - draggedOffset.width, clickLocation.y - draggedOffset.height)
                 offset:NSMakeSize(0,0)
                  event:theEvent pasteboard:pboard source:self slideBack:NO];

        draggedItem = nil;
    }
}

//Invoked as the drag begins
- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint
{
    //Hide the toolbar item that is being dragged, so it appears to no longer be on the toolbar.
    //This is simpler than actually removing the item and having to put it back if the drag fails
    draggedSize = [[draggedItem view] frame].size;
    [[draggedItem view] setFrameSize:NSMakeSize(0,0)];
}

//Invoked as the drag ends
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    //restore our origional frame size
    [[draggedItem view] setFrameSize:draggedSize];

    //NSDragOperationDelete - Dragged to trash can (delete)
    //NSDragOperationNone - Dragged off the toolbar, to a non receptor on the screen (POOF, delete)
    //NSDragOperationPrivate - Dragged to another toolbar of the same type (nothing)
    
    //Dragged to no destination, show the animated poof
    if(operation == NSDragOperationNone){
        NSPoint	puffOrigin = screenPoint;
        NSSize	puffSize = NSMakeSize(32,32);
    
        //Center the puff
        puffOrigin.x -= puffSize.width / 2;
        puffOrigin.y -= puffSize.height / 2;
    
        [AIAnimatedFloater animatedFloaterWithImage:[NSImage imageNamed:MINI_TOOLBAR_POOF forClass:[self class]] size:puffSize frames:5 delay:0.08  at:puffOrigin];
    }

    if(operation != NSDragOperationPrivate){
        [self removeItemAtIndex:draggedIndex];
    }
}

//Drag destination methods ------------------------------------------------------------------------
//Return YES for acceptance
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

//Add the dragged item to this toolbar
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pasteboard = [sender draggingPasteboard];

    if(hoverIndex >= 0 && hoverIndex <= [itemIdentifierArray count]){
        int	dropIndex = hoverIndex;
    
        //Stop hovering
        hoverIndex = -1;
        
        //Set the frame of the item that was dragged to where the user dropped it, so it will smoothly slide from that position to where it belongs.  This looks cleaner than just 'snapping' the item from where it used to be.
        if(focusedForDrag && draggedItem){
            NSPoint	localDrop;
            
            localDrop = [sender draggingLocation];
        
            //Set our frame to where we were dropped
            [[draggedItem view] setFrameOrigin:NSMakePoint(localDrop.x - draggedOffset.width, localDrop.y - draggedOffset.height)];
        }
        
        
        //Move/insert the item
        [self insertItemWithIdentifier:[[sender draggingPasteboard] stringForType:MINI_TOOLBAR_ITEM_DRAGTYPE]
                               atIndex:dropIndex
                       allowDuplicates:!([pasteboard stringForType:MINI_TOOLBAR_SOURCE])]; //If there is no source, then this item was dragged from the customization palette - so duplicates are allowed.

        [self setFocusedForDrag:NO];

        return YES;
    }else{
        return NO;
    }
}

//Cancel any drag tracking that was occuring
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    //
}

@end




