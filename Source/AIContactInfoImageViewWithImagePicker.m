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

#import "AIContactInfoImageViewWithImagePicker.h"
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

@interface AIContactInfoImageViewWithImagePicker ()
- (void)resetCursorRects;
- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame;
@end

@implementation AIContactInfoImageViewWithImagePicker

- (void)configureTracking
{
	resetImageTrackingTag = -1;
	[self resetCursorRects];			
}

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		[self configureTracking];
	}
	
	return self;
}

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
	}
	
	[self configureTracking];
}

- (void)dealloc
{
	if (resetImageTrackingTag != -1) {
		[self removeTrackingRect:resetImageTrackingTag];
		resetImageTrackingTag = -1;
	}
	
	[super dealloc];
}


- (void)drawRect:(NSRect)inRect
{
	[NSGraphicsContext saveGraphicsState];
	
	inRect = NSInsetRect(inRect, 1, 1);
	
	NSBezierPath	*clipPath = [NSBezierPath bezierPathWithRoundedRect:inRect radius:3];
	
	[[NSColor windowFrameColor] set];
	[clipPath setLineWidth:1];
	[clipPath stroke];
	
	//Ensure we have an even/odd winding rule in effect
	[clipPath setWindingRule:NSEvenOddWindingRule];
	[clipPath addClip];
	
	[NSGraphicsContext saveGraphicsState];
	[super drawRect:inRect];
	[NSGraphicsContext restoreGraphicsState];

	// Draw snapback image
	if (showResetImageButton) {
		NSImage *snapbackImage = [NSImage imageNamed:@"SRSnapback" forClass:[self class]];
		NSRect snapBackRect = [self _snapbackRectForFrame:[self bounds]];
		if (resetImageHovered) {
			[[[NSColor blackColor] colorWithAlphaComponent:0.8f] set];		
		} else {
			[[[NSColor blackColor] colorWithAlphaComponent:0.5f] set];
		}
		
		[[NSBezierPath bezierPathWithOvalInRect:snapBackRect] fill];
		[snapbackImage drawAtPoint:snapBackRect.origin fromRect:[self bounds] operation:NSCompositeSourceOver fraction:1.0f];
	}

	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark Snapback
- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame
{	
	if (!showResetImageButton) return NSZeroRect;
	
	NSRect snapbackRect;
	NSImage *snapbackImage = [NSImage imageNamed:@"SRSnapback" forClass:[self class]];

	snapbackRect.origin = NSMakePoint(NSMaxX(cellFrame) - [snapbackImage size].width - 1, 2);
	snapbackRect.size = [snapbackImage size];

	return snapbackRect;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	if ([[self window] isKeyWindow] || [self acceptsFirstMouse: theEvent]) {
		resetImageHovered = YES;
		[self display];
	}
	
	[super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent*)theEvent
{	
	if ([[self window] isKeyWindow] || [self acceptsFirstMouse: theEvent]) {
		resetImageHovered = NO;
		[self display];
	}

	[super mouseEntered:theEvent];
}

- (void)mouseDown:(NSEvent *)inEvent
{
	NSPoint mouseLocation = [self convertPoint:[inEvent locationInWindow] fromView:nil];
	if ([self mouse:mouseLocation inRect:[self _snapbackRectForFrame:[self bounds]]]) {
		if ([self.delegate respondsToSelector:@selector(deleteInImageViewWithImagePicker:)]) {
			[self.delegate deleteInImageViewWithImagePicker:self];
		}

	} else {
		[super mouseDown:inEvent];
	}
}

- (void)setShowResetImageButton:(BOOL)inShowResetImageButton
{
	showResetImageButton = inShowResetImageButton;

	[self resetCursorRects];
}


#pragma mark Tracking rects
//Remove old tracking rects when we change superviews
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (resetImageTrackingTag != -1) {
		[self removeTrackingRect:resetImageTrackingTag];
		resetImageTrackingTag = -1;
	}
	
	[super viewWillMoveToSuperview:newSuperview];
}

- (void)viewDidMoveToSuperview
{
	[super viewDidMoveToSuperview];
	
	[self resetCursorRects];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (resetImageTrackingTag != -1) {
		[self removeTrackingRect:resetImageTrackingTag];
		resetImageTrackingTag = -1;
	}
	
	[super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	[self resetCursorRects];
}

- (void)frameDidChange:(NSNotification *)inNotification
{
	[self resetCursorRects];
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	//Stop any existing tracking
	if (resetImageTrackingTag != -1) {
		[self removeTrackingRect:resetImageTrackingTag];
		resetImageTrackingTag = -1;
	}
	
	//Add a tracking rect if our superview and window are ready
	if (showResetImageButton && [self superview] && [self window]) {
		NSRect	snapbackRect = [self _snapbackRectForFrame:[self bounds]];
		NSPoint	mouseLocation = [self convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
		BOOL	mouseInside = [self mouse:mouseLocation inRect:snapbackRect];

		resetImageTrackingTag = [self addTrackingRect:snapbackRect owner:self userData:nil assumeInside:mouseInside];
		if (mouseInside) [self mouseEntered:nil];
	}
}

@end
