//
//  AINewMessageTableView.m
//  Adium
//
//  Created by Thijs Alkemade on 23-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AINewMessageTableView.h"

@implementation AINewMessageTableView

- (BOOL)canBecomeKeyView
{
	return NO;
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (void)highlightSelectionInClipRect:(NSRect)theClipRect
{
    NSRange visibleRowIndexes = [self rowsInRect:theClipRect];
    NSInteger selectedRow = self.selectedRow;
	
	if (selectedRow >= visibleRowIndexes.location && selectedRow < visibleRowIndexes.location + visibleRowIndexes.length) {
		NSRect aRowRect = [self rectOfRow:selectedRow];
		NSBezierPath * path = [NSBezierPath bezierPathWithRect:aRowRect];
		
		[[NSColor secondarySelectedControlColor] set];
		
		NSResponder *firstResponder = self.window.firstResponder;
		
		if ([firstResponder isKindOfClass:[NSView class]]) {
			NSView *view = (NSView *)firstResponder;
			
			while (view) {
				if (view == field_search) {
					[[NSColor selectedControlColor] set];
					break;
				}
				view = view.superview;
			}
		}
		
		[path fill];
	}
}

@end
