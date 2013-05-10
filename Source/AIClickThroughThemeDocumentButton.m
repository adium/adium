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

#import "AIClickThroughThemeDocumentButton.h"

/*!
 * @class AIClickThroughThemeDocumentButton
 * @brief This NSThemeDocumentButton subclass makes the window move when it is dragged.
 *
 * Normally, an NSThemeDocumentButton eats mouseDown: and mouseDragged: events for its own nefarious
 * purposes, namely drag & drop of the window's document to other locations.  We want to utilize the display
 * of a document button, but we don't have an associated document, so dragging appears to just do nothing.
 *
 * With this replacement class, dragging the document button properly moves the window.  The code is, for
 * reference, a stripped down version of the code powering AIBorderlessWindow's dragging movements.
 *
 * On mouse down, the window's frame is noted; deltas as the mouse moves are used to determine the window's
 * own movements.
 */
@implementation AIClickThroughThemeDocumentButton

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

/*!
 * @brief HACK: When deallocing, we crash in setRepresentedFilename presumably because of an NSCoder failure in AIMesageWindow
 */
- (void)setRepresentedFilename:(NSString *)inFilename
{
	//Empty
}

/*!
 * @brief Don't allow the document button to try to show a popup menu
 *
 * If we do, we'll crash, since there shouldn't actually *be* a theem document button with no represented filename and no document.
 */
- (void)showPopup
{
	//Empty
}

@end
