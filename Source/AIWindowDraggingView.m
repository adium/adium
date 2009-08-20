//
//  AIWindowDraggingView.m
//  Adium
//
//  Created by Evan Schoenberg on 3/6/06.
//

#import "AIWindowDraggingView.h"

/*!
 * @class AIWindowDraggingView
 * @brief This NSView subclass makes the window move when it is dragged by the view itself (but not by subviews).
 *
 * The code is, for reference, a stripped down version of the code powering AIBorderlessWindow's dragging movements.
 *
 * On mouse down, the window's frame is noted; deltas as the mouse moves are used to determine the window's
 * own movements.
 */
@implementation AIWindowDraggingView
/*!
 * @brief Mouse dragged
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
	NSWindow	*window = [self window];
	NSPoint		currentLocation, newOrigin;
	NSRect		newWindowFrame;
	
	/* If we get here and aren't yet in a left mouse event, which can happen if the user began dragging while
	 * a contextual menu is showing, start off from the right position by getting our originalMouseLocation.
	 */		
	if (!inLeftMouseEvent) {
		//Grab the mouse location in global coordinates
		originalMouseLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
		windowFrame = [window frame];
		inLeftMouseEvent = YES;		
	}
	
	newOrigin = windowFrame.origin;
	newWindowFrame = windowFrame;
	
	//Grab the current mouse location to compare with the location of the mouse when the drag started (stored in mouseDown:)
	currentLocation = [NSEvent mouseLocation];
	newOrigin.x += (currentLocation.x - originalMouseLocation.x);
	newOrigin.y += currentLocation.y - originalMouseLocation.y;
	
	newWindowFrame.origin = newOrigin;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMoveNotification object:window];
	[window setFrameOrigin:newWindowFrame.origin];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:window];		
}

/*!
 * @brief Mouse down
 *
 * We start tracking the a drag operation here when the user first clicks the mouse without command presed
 * to establish the initial location.
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	NSWindow	*window = [self window];
	
	//grab the mouse location in global coordinates
	originalMouseLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
	windowFrame = [window frame];
	inLeftMouseEvent = YES;
}

/*!
 * @brief Mouse up
 */
- (void)mouseUp:(NSEvent *)theEvent
{
	inLeftMouseEvent = NO;
}

@end
