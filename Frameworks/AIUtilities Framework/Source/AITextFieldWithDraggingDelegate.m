//
//  AITextFieldWithDraggingDelegate.m
//  AIUtilities.framework
//
//  Created by David Clark on 2/4/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

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
