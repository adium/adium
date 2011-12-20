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

#import "AIBorderlessListOutlineView.h"
#import <AIUtilities/AIEventAdditions.h>

#define FORCED_MINIMUM_HEIGHT 20

@implementation AIBorderlessListOutlineView

//Forward mouse down events to our containing window (when command is pressed) to allow dragging
- (void)mouseDown:(NSEvent *)theEvent
{
	if (![theEvent cmdKey]) {
		//Wait for the next event
		NSEvent *nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
														untilDate:[NSDate distantFuture]
														   inMode:NSEventTrackingRunLoopMode
														  dequeue:NO];
		
		//Pass along the event (either to ourself or our window, depending on what it is)
		switch ([nextEvent type]) {
			case NSLeftMouseUp:
				[super mouseDown:theEvent];   
				[super mouseUp:nextEvent];   
				break;
			case NSLeftMouseDragged:
				[[self window] mouseDown:theEvent];
				[[self window] mouseDragged:nextEvent];
				break;
			default:
				[[self window] mouseDown:theEvent];
				break;
		}
	} else {
        [super mouseDown:theEvent];   
	}
}
- (void)mouseDragged:(NSEvent *)theEvent
{
    if (![theEvent cmdKey]) {
        [[self window] mouseDragged:theEvent];   
	} else {
		[super mouseDragged:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (![theEvent cmdKey]) {
        [[self window] mouseUp:theEvent];   
	} else {
		[super mouseUp:theEvent];
	}	
}

- (NSInteger)desiredHeight
{
	NSInteger height = [super desiredHeight];
	return (height > FORCED_MINIMUM_HEIGHT ? height : FORCED_MINIMUM_HEIGHT);
}

- (NSInteger)totalHeight
{
	return [super totalHeight];
}

@end
