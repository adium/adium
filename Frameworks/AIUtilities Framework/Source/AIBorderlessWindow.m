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
//AIBorderlessWindow.m based partially off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import "AIBorderlessWindow.h"
#import "AIEventAdditions.h"

#define BORDERLESS_WINDOW_DOCKING_DISTANCE 	12	//Distance in pixels before the window is snapped to an edge

@interface AIBorderlessWindow ()
- (BOOL)dockWindowFrame:(NSRect *)inFrame toScreenFrame:(NSRect)screenFrame;
@end

@implementation AIBorderlessWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {

    //Call NSWindow's version of this function, but pass in the all-important value of NSBorderlessWindowMask
    //for the styleMask so that the window doesn't have a title bar
   if ((self = [super initWithContentRect:contentRect 
							styleMask:NSBorderlessWindowMask
							  backing:NSBackingStoreBuffered 
									defer:flag])) {
	   
	   //Set the background color to clear so that we can see through the parts
	   //of the window into which we're not drawing 
	   [self setBackgroundColor:[NSColor clearColor]];
	   inLeftMouseEvent = NO;
	   
	   moveable = YES;
   }
	
    return self;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default.  Therefore, controls in such windows
// won't ever be enabled by default.  Thus, we override this method to change that.
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)setMoveable:(BOOL)inMoveable
{
	moveable = inMoveable;
}

- (void)performClose:(id)sender
{ 
    BOOL shouldClose = YES;
    
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(windowShouldClose:)]) {
        shouldClose = [(id)[self delegate] windowShouldClose:nil];
    } else if ([self respondsToSelector:@selector(windowShouldClose:)]) { 
        shouldClose = [(id)self windowShouldClose:nil];
	}
	
    if (shouldClose) {
        [self close];
	}
}

//Once the user starts dragging the mouse with command held, we move the window with it. 
//We do this because the window has no title bar for the user to drag (so we have to implement dragging ourselves)
- (void)mouseDragged:(NSEvent *)theEvent
{
    if (![theEvent cmdKey] && moveable) {
		NSScreen	*currentScreen;
        NSPoint		currentLocation, newOrigin;
        NSRect		newWindowFrame;

		/* If we get here and aren't yet in a left mouse event, which can happen if the user began dragging while
		 * a contextual menu is showing, start off from the right position by getting our originalMouseLocation.
		 */		
		if (!inLeftMouseEvent) {
			//grab the mouse location in global coordinates
			originalMouseLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
			windowFrame = [self frame];
			inLeftMouseEvent = YES;		
		}
		
		currentScreen = [self screen];
		newOrigin = windowFrame.origin;
		newWindowFrame = windowFrame;
		
        //Grab the current mouse location to compare with the location of the mouse when the drag started (stored in mouseDown:)
        currentLocation = [NSEvent mouseLocation];
        newOrigin.x += (currentLocation.x - originalMouseLocation.x);
        newOrigin.y += currentLocation.y - originalMouseLocation.y;
			
		//Keep the window from going under the menu bar (on the main screen)
		NSRect  screenFrame = [currentScreen visibleFrame];
		if (currentScreen == [[NSScreen screens] objectAtIndex:0]) {

			if ((newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) ) {
				
				newOrigin.y = screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
			}
		}
		
		// Keep the topmost part of the window on the screen (if it goes onto another screen in the process,
		// that screen should become [self screen] so this check shouldn't fire).
		if ((newOrigin.y+windowFrame.size.height) < 10 + screenFrame.origin.y ) {
            newOrigin.y = 10 + screenFrame.origin.y - windowFrame.size.height;
        }
  
		newWindowFrame.origin = newOrigin;

		//If the user is not pressing shift, attempt to dock this window the the visible frame first, and then to the screen frame
		if (![theEvent shiftKey]) {
			[self dockWindowFrame:&newWindowFrame toScreenFrame:[currentScreen visibleFrame]];
			[self dockWindowFrame:&newWindowFrame toScreenFrame:[currentScreen frame]];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMoveNotification object:self];
		[self setFrameOrigin:newWindowFrame.origin];
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:self];
		
    } else {
        [super mouseDragged:theEvent];
    }
}

//We start tracking the a drag operation here when the user first clicks the mouse without command presed,
//to establish the initial location.
- (void)mouseDown:(NSEvent *)theEvent
{    
    if (![theEvent cmdKey] && ([theEvent type] == NSLeftMouseDown) && moveable) {
        //grab the mouse location in global coordinates
        originalMouseLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
		windowFrame = [self frame];
		inLeftMouseEvent = YES;
		
    } else {
		inLeftMouseEvent = NO;

        [super mouseDown:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
	inLeftMouseEvent = NO;
	
	[super mouseUp:theEvent];
}

//Dock the passed window frame if it's close enough to the screen edges
- (BOOL)dockWindowFrame:(NSRect *)inWindowFrame toScreenFrame:(NSRect)inScreenFrame
{
	BOOL	changed = NO;
	
	//Left
	if ((labs(NSMinX((*inWindowFrame)) - NSMinX(inScreenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)) {
		(*inWindowFrame).origin.x = inScreenFrame.origin.x;
		changed = YES;
	}
	
	//Bottom
	if ((labs(NSMinY(*inWindowFrame) - NSMinY(inScreenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)) {
		(*inWindowFrame).origin.y = inScreenFrame.origin.y;
		changed = YES;
	}
	
	//Right
	if ((labs(NSMaxX(*inWindowFrame) - NSMaxX(inScreenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)) {
		(*inWindowFrame).origin.x -= NSMaxX(*inWindowFrame) - NSMaxX(inScreenFrame);
		changed = YES;
	}
	
	//Top
	if ((labs(NSMaxY(*inWindowFrame) - NSMaxY(inScreenFrame)) < BORDERLESS_WINDOW_DOCKING_DISTANCE)) {
		(*inWindowFrame).origin.y -= NSMaxY(*inWindowFrame) - NSMaxY(inScreenFrame);
		changed = YES;
	}
	
	return changed;
}



@end
