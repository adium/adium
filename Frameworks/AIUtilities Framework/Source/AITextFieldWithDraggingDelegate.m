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

#import "AITextFieldWithDraggingDelegate.h"

@interface AITextFieldWithDraggingDelegate ()
- (id)_init;
@end

@implementation AITextFieldWithDraggingDelegate

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self = [self _init];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		self = [self _init];
	}
	return self;
}

- (id)_init
{
	dragDelegate = nil;
	lastEnteredOp = NSDragOperationNone;
    return self;
}

- (void)setDragDelegate:(id)drag
{
	dragDelegate = drag;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(prepareForDragOperation:)]) {
		return [dragDelegate prepareForDragOperation:sender];
	} else {
		return [super prepareForDragOperation:sender];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(performDragOperation:)]) {
		return [dragDelegate performDragOperation:sender];
	} else {
		return [super performDragOperation:sender];
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(concludeDragOperation:)]) {
		[dragDelegate concludeDragOperation:sender];
	} else {
		[super concludeDragOperation:sender];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingEntered:)]) {
		lastEnteredOp = [dragDelegate draggingEntered:sender];
		return lastEnteredOp;
	} else {
		return [super draggingEntered:sender];
	}
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingEnded:)]) {
		[dragDelegate draggingEnded:sender];
	} else {
		[super draggingEnded:sender];
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingExited:)]) {
		[dragDelegate draggingExited:sender];
	} else {
		[super draggingExited:sender];
	}
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingUpdated:)]) {
		return [dragDelegate draggingUpdated:sender];
	} else if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingEntered:)]) {
		// If the delegate implements draggingEntered but not draggingUpdated, just return its last 'entered' operation
		return lastEnteredOp;
	} else {
		return [super draggingUpdated:sender];
	}
}

@end
