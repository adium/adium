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

//Note: You must setDelegate:nil before deallocing the delegate; NSTimers retain their targets, so
//the AISmoothTooltipTracker instance may remain around even after being released.

#import "AISmoothTooltipTracker.h"
#import "AIDockingWindow.h"

#define TOOL_TIP_CHECK_INTERVAL	45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY			35.0	//Number of check intervals of no movement before a tip is displayed

#define	LOG_TRACKING_INFO		FALSE

@interface AISmoothTooltipTracker ()
- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate;

- (void)installCursorRect;
- (void)removeCursorRect;
- (void)resetCursorTracking;

- (void)_startTrackingMouse;
- (void)_stopTrackingMouse;
- (void)_hideTooltip;
- (void)mouseMovementTimer:(NSTimer *)inTimer;

- (void)contentViewBoundsDidChange;
@end

@implementation AISmoothTooltipTracker

+ (AISmoothTooltipTracker *)smoothTooltipTrackerForView:(NSView *)inView withDelegate:(id <AISmoothTooltipTrackerDelegate>)inDelegate
{
	return [[self alloc] initForView:inView withDelegate:inDelegate];
}

- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate
{
	if ((self = [super init])) {
		view = inView;
		delegate = inDelegate;
		tooltipTrackingTag = -1;
		tooltipLocation = NSZeroPoint;
		mouseIsScrolling = NO;

		//Reset cursor tracking when the view's frame changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCursorTracking)
													 name:NSViewFrameDidChangeNotification
												   object:view];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCursorTracking)
													 name:AIWindowToolbarDidToggleVisibility
												   object:[view window]];

		// Track contentView bounds changes (useful to detect scrolling)
		if ([view isKindOfClass:[NSScrollView class]]) {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(contentViewBoundsDidChange)
														 name:NSViewBoundsDidChangeNotification
													   object:[(NSScrollView *)view contentView]];
		}
		
		[self installCursorRect];
	}
	
	return self;
}

- (void)dealloc
{
#if LOG_TRACKING_INFO
	NSLog(@"[%@ dealloc]",self);
#endif

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self removeCursorRect];
	[self _stopTrackingMouse];

	view = nil;
}

- (void)setDelegate:(id <AISmoothTooltipTrackerDelegate>)inDelegate
{
	if (delegate != inDelegate) {
		[self _stopTrackingMouse];
		
		delegate = inDelegate;
	}
}

- (NSView *)view
{
	return view;
}

/*
 * @brief This should be called when the view for which we are tracking will be removed from its window without the window closing
 *
 * This allows us to remove our cursor rects (there isn't a notification by which we can do it automatically)
 */
- (void)viewWillBeRemovedFromWindow
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:AIWindowToolbarDidToggleVisibility
												  object:[view window]];
	
	[self removeCursorRect];
	[self _stopTrackingMouse];
}

/*
 * @brief After calling viewWillBeRemovedFromWindow, call viewWasAddedToWindow to reinitiate tracking
 */
- (void)viewWasAddedToWindow
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetCursorTracking)
												 name:AIWindowToolbarDidToggleVisibility
											   object:[view window]];
	
	[self installCursorRect];
}

//Cursor Rects ---------------------------------------------------------------------------------------------------------
#pragma mark Cursor Rects
//Install the cursor rect for our enclosing scrollview
- (void)installCursorRect
{
	if (tooltipTrackingTag == -1) {
		NSRect	 		trackingRect;

		//Add a new tracking rect
		trackingRect = [view frame];
		trackingRect.origin = NSMakePoint(0,0);
		
		tooltipTrackingTag = [view addTrackingRect:trackingRect owner:self userData:nil assumeInside:mouseInside];
		
#if LOG_TRACKING_INFO
		NSLog(@"[%@ installCursorRect] addTrackingRect %@ on %@ in %@: tag = %i",self,NSStringFromRect(trackingRect),view,[view window],tooltipTrackingTag);
#endif
		//If the mouse is already inside, begin tracking the mouse immediately
		if (mouseInside) [self _startTrackingMouse];
	}
}

//Remove the cursor rect
- (void)removeCursorRect
{
#if LOG_TRACKING_INFO
	if (tooltipTrackingTag != -1) {
		NSLog(@"[%@ removeCursorRect] Remove rect from %@ in %@ : tag = %i",self,view,[view window],tooltipTrackingTag);
	} else {
		NSLog(@"[%@ removeCursorRect] No rect to remove",self);
	}
#endif

	if (tooltipTrackingTag != -1) {
		[view removeTrackingRect:tooltipTrackingTag];
		tooltipTrackingTag = -1;
		[self _stopTrackingMouse];		
	}
}

//Reset cursor tracking
- (void)resetCursorTracking
{
#if LOG_TRACKING_INFO
	NSLog(@"[%@ resetCursorTracking]",self);
#endif

	[self removeCursorRect];
	[self installCursorRect];
}


//Tooltips (Cursor movement) -------------------------------------------------------------------------------------------
//We use a timer to poll the location of the mouse.  Why do this instead of using mouseMoved: events?
// - Webkit eats mouseMoved: events, even when those events occur elsewhere on the screen
// - mouseMoved: events do not work when Adium is in the background
#pragma mark Tooltips (Cursor movement)
//Mouse entered our list, begin tracking it's movement
- (void)mouseEntered:(NSEvent *)theEvent
{
#if LOG_TRACKING_INFO
	NSLog(@"+++ [%@: mouseEntered]", self);
#endif
	mouseInside = YES;
	
	[self _startTrackingMouse];
}

//Mouse left our list, cease tracking
- (void)mouseExited:(NSEvent *)theEvent
{
#if LOG_TRACKING_INFO
	NSLog(@"--- [%@: mouseExited]", self);
#endif
	mouseInside = NO;
	
	[self _stopTrackingMouse];
}

// Handle Scrolling
- (void)contentViewBoundsDidChange
{
	mouseIsScrolling = YES;
}

//Start tracking mouse movement
- (void)_startTrackingMouse
{
	if (!tooltipMouseLocationTimer) {
		tooltipCount = 0;
		tooltipMouseLocationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/TOOL_TIP_CHECK_INTERVAL)
																	  target:self
																	selector:@selector(mouseMovementTimer:)
																	userInfo:nil
																	 repeats:YES];
	}
}

//Stop tracking mouse movement
- (void)_stopTrackingMouse
{
	//Invalidate tracking
	if (tooltipMouseLocationTimer) {
		//Hide the tooltip before releasing the timer, as the timer may be the last object retaining self
		//and we want to communicate with the delegate before a potential call to dealloc.
		[self _hideTooltip];
		
		NSTimer	*theTimer = tooltipMouseLocationTimer;
		tooltipMouseLocationTimer = nil;
		
		[theTimer invalidate];
		theTimer = nil;
	}
}

- (void)_hideTooltip
{
	tooltipCount = 0;

	//If the tooltip was being shown before, hide it
	if (!NSEqualPoints(tooltipLocation,NSZeroPoint)) {
		lastMouseLocation = NSZeroPoint;
		tooltipLocation = NSZeroPoint;
		
		//Hide tooltip
		[delegate hideTooltip];
	}
}

//Time to poll mouse location
- (void)mouseMovementTimer:(NSTimer *)inTimer
{
	NSPoint		mouseLocation = [NSEvent mouseLocation];
	NSWindow	*theWindow = [view window];
	
#if LOG_TRACKING_INFO
	NSLog(@"%@: Visible: %i ; Point %@ in %@ = %i", self,
		  [[view window] isVisible],
/*		  NSStringFromPoint([[view superview] convertPoint:[[view window] convertScreenToBase:mouseLocation] fromView:[[view window] contentView]]),*/
		  NSStringFromPoint([[view window] convertScreenToBase:mouseLocation]),
/*		  NSStringFromRect([view frame]),*/
		  NSStringFromRect([[[view window] contentView] convertRect:[view frame] fromView:[view superview]]),
/*		  NSPointInRect([[view window] convertScreenToBase:mouseLocation], [view frame])*/
		  /*NSPointInRect([[view superview] convertPoint:[[view window] convertScreenToBase:mouseLocation] fromView:[[view window] contentView]],[view frame])*/
		  NSPointInRect([[view window] convertScreenToBase:mouseLocation],[[[view window] contentView] convertRect:[view frame] fromView:[view superview]]));
#endif
	
	if ([theWindow isVisible] && 
	   NSPointInRect([theWindow convertScreenToBase:mouseLocation],[[theWindow contentView] convertRect:[view frame] fromView:[view superview]]) &&
		[theWindow isOnActiveSpace]) {
		//tooltipCount is used for delaying the appearence of tooltips.  We reset it to 0 when the mouse moves.  When
		//the mouse is left still tooltipCount will eventually grow greater than TOOL_TIP_DELAY, and we will begin
		//displaying the tooltips
		if (tooltipCount > TOOL_TIP_DELAY) {
			if (!NSEqualPoints(tooltipLocation, mouseLocation) || mouseIsScrolling) {
				[delegate showTooltipAtPoint:mouseLocation];
				tooltipLocation = mouseLocation;
				
				// Reset scrolling info
				mouseIsScrolling = NO;
			}
			
		} else {
			if (!NSEqualPoints(mouseLocation,lastMouseLocation)) {
				lastMouseLocation = mouseLocation;
				tooltipCount = 0; //reset tooltipCount to 0 since the mouse has moved
			} else {
				tooltipCount++;
			}
		}
	} else {
		//If the cursor has left our frame or the window is no logner visible, manually hide the tooltip.
		//This protects us in the cases where we do not receive a mouse exited message; we don't stop tracking
		//because we could reenter the tracking area without receiving a mouseEntered: message.
#if LOG_TRACKING_INFO
		NSLog(@"%@: Mouse moved out; hiding the tooltip.", self);
#endif
		[self _hideTooltip];
	}
}

@end
