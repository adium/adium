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

#import "AIMiniToolbarButton.h"
#import "AIMiniToolbar.h"
#import "AIAnimatedFloater.h"
#import "AIMiniToolbarCenter.h"
#import "AIMiniToolbarItem.h"

#define MINI_TOOLBAR_UNKNOWN_TYPE	@"_Unknown"	//Default type for an unknown toolbar item

@interface AIMiniToolbarButton (PRIVATE)
- (NSMenu *)menuForEvent:(NSEvent *)event;
- (void)mouseDown:(NSEvent *)theEvent;
- (id)initWithImage:(NSImage *)inImage;
- (IBAction)click:(id)sender;
@end

@implementation AIMiniToolbarButton

//Create a new mini toolbar button
+ (AIMiniToolbarButton *)miniToolbarButtonWithImage:(NSImage *)inImage
{
    return [[[self alloc] initWithImage:inImage] autorelease];
}

//Private --------------------------------------------------------------------------------
//Pass contextual menu events on through to the toolbar
- (NSMenu *)menuForEvent:(NSEvent *)event
{
    if(toolbar){
        return [toolbar menuForEvent:event];
    }else{
        return [super menuForEvent:event];
    }
}

//Initiate a drag if command is held while clicking
- (void)mouseDown:(NSEvent *)theEvent
{
    if(toolbar == nil || [[AIMiniToolbarCenter defaultCenter] customizing:toolbar]){
        [toolbar initiateDragWithEvent:theEvent];
    }else{
        [super mouseDown:theEvent];
    }
}

//By getting the superview and it's type before hand, we avoid having to fetch the
//information it every time we draw
- (void)viewDidMoveToSuperview
{
    NSView	*superview = [self superview];

    if([superview isKindOfClass:[AIMiniToolbar class]]){
        toolbar = (AIMiniToolbar *)superview;
    }else{
        toolbar = nil;
    }
}

//init
- (id)initWithImage:(NSImage *)inImage
{
	NSRect myFrame = { NSZeroPoint, [inImage size] };

	if((self = [super initWithFrame:myFrame])) {
		//config
		[super setTarget:self];
		[super setAction:@selector(click:)];
		[self setTitle:@""];
		[self setImage:inImage];
		[self setAlternateTitle:@""];
		[self setImagePosition:NSImageOnly];
		[self setButtonType:NSMomentaryChangeButton];
		[self setBordered:NO];
	}

	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setToolbarItem:(AIMiniToolbarItem *)inToolbarItem{
    toolbarItem = inToolbarItem;
}
- (AIMiniToolbarItem *)toolbarItem{
    return toolbarItem;
}

- (id)copyWithZone:(NSZone *)zone
{
    AIMiniToolbarButton	*newItem = [[AIMiniToolbarButton alloc] initWithImage:[self image]];   
    
    [newItem setToolbarItem:[self toolbarItem]];
    [newItem setTitle:[self title]];
    [newItem setAlternateTitle:[self alternateTitle]];
    [newItem setImagePosition:[self imagePosition]];
    [newItem setBordered:[self isBordered]];

    return newItem;
}

- (IBAction)click:(id)sender
{
    //Invoke our target, passing it the toolbar item that was pressed
    [[toolbarItem target] performSelector:[toolbarItem action] withObject:toolbarItem];
}

@end

