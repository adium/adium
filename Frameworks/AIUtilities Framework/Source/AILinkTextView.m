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

/*
 A text view that supports link tracking and clicking
 */

#import "AILinkTextView.h"
#import "AILinkTrackingController.h"

@interface AILinkTextView ()
- (void)_initLinkTextView;
- (void)frameDidChange:(NSNotification *)notification;
@end

@implementation AILinkTextView

//Init
- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _initLinkTextView];
	}

	return self;
}

//Init from nib
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initLinkTextView];
	}

	return self;
}

//Common init
- (void)_initLinkTextView
{
    linkTrackingController = [[AILinkTrackingController linkTrackingControllerForTextView:self] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(frameDidChange:)
												 name:NSViewFrameDidChangeNotification 
											   object:self];
    [[self window] resetCursorRects];
}

//Dealloc
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [linkTrackingController release];
    
    [super dealloc];
}

//Pass clicks to the link tracking controller
- (void)mouseDown:(NSEvent*)theEvent
{
    if (![linkTrackingController handleMouseDown:theEvent withOffset:NSMakePoint(0,0)]) {
        [super mouseDown:theEvent];
    }    
}

//Reset tracking when our frame is changed
- (void)frameDidChange:(NSNotification *)notification
{
    [[self window] resetCursorRects];
}

//Reset cursor tracking
- (void)resetCursorRects
{
    NSPoint	containerOrigin;
    NSRect	visibleRect;

    containerOrigin = [self textContainerOrigin];
    visibleRect = NSOffsetRect ([self visibleRect], -containerOrigin.x, -containerOrigin.y);

    [linkTrackingController trackLinksInRect:visibleRect withOffset:NSMakePoint(0,0)];
}

//If we're being removed from the window, we need to remove our tracking rects
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (newWindow == nil) { //pass an empty visible rect to end any tracking
        [linkTrackingController trackLinksInRect:NSMakeRect(0,0,0,0) withOffset:NSMakePoint(0,0)];
    }
}

//Toggle display of tooltips
- (void)setShowTooltip:(BOOL)inShowTooltip
{
    [linkTrackingController setShowTooltip:inShowTooltip];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu	*menu;
	NSArray	*linkMenuItems;
	
	menu = [super menuForEvent:theEvent];
	
	linkMenuItems = [linkTrackingController menuItemsForEvent:theEvent withOffset:NSMakePoint(0,0)];
	
	if ([linkMenuItems count]) {
		if (!menu) menu = [[[NSMenu alloc] init] autorelease];
		
		[linkMenuItems enumerateObjectsWithOptions:NSEnumerationReverse
										usingBlock:^(id menuItem, NSUInteger idx, BOOL *stop) {
			[menu insertItem:menuItem atIndex:0];
		}];
	}
	
	return menu;
}

@end
