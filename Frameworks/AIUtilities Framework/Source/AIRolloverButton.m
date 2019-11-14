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

#import "AIRolloverButton.h"

@interface AIRolloverButton (PRIVATE)
- (void)rolloverFrameDidChange:(NSNotification *)inNotification;
@end

@implementation AIRolloverButton

- (void)awakeFromNib
{	
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(rolloverFrameDidChange:)
												 name:NSViewFrameDidChangeNotification
											   object:self];
	[self setPostsFrameChangedNotifications:YES];
	[self resetCursorRects];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super dealloc];
}

#pragma mark Configuration
//Set our delegate
- (void)setDelegate:(NSObject<AIRolloverButtonDelegate> *)inDelegate
{
    delegate = inDelegate;
	
	//Make sure this delegate responds to the required method
	NSParameterAssert([delegate respondsToSelector:@selector(rolloverButton:mouseChangedToInsideButton:)]);
}
- (NSObject<AIRolloverButtonDelegate> *)delegate{
    return delegate;
}

//Cursor Tracking  -----------------------------------------------------------------------------------------------------
#pragma mark Cursor Tracking

//Remove old tracking rects when we change superviews
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
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
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];

	[self resetCursorRects];
}

- (void)rolloverFrameDidChange:(NSNotification *)inNotification
{
	[self resetCursorRects];
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	//Stop any existing tracking
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	//Add a tracking rect if our superview and window are ready
	if ([self superview] && [self window]) {
		NSRect	myFrame = [self frame];
		NSRect	trackRect = NSMakeRect(0, 0, myFrame.size.width, myFrame.size.height);
		NSPoint	localPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]]
									   fromView:[self superview]];
		BOOL	mouseInside = NSPointInRect(localPoint, myFrame);
		
		trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseInside];
		if (mouseInside) [self mouseEntered:[[[NSEvent alloc] init] autorelease]];
	}
}

//Cursor entered our view
- (void)mouseEntered:(NSEvent *)theEvent
{
	[delegate rolloverButton:self mouseChangedToInsideButton:YES];
	
	[super mouseEntered:theEvent];
}

//Cursor left our view
- (void)mouseExited:(NSEvent *)theEvent
{
	[delegate rolloverButton:self mouseChangedToInsideButton:NO];

	[super mouseExited:theEvent];
}

@end
