//
//  AISmoothTooltipTracker.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//


//Delegate handles displaying the tooltips, we handle all the tracking
/*!
 * @protocol AISmoothTooltipTrackerDelegate
 * @brief Protocol implemented by the <tt>AISmoothTooltipTracker</tt> delegate
 *
 * An AISmoothTooltipTracker delegate is required to implement <tt>AISmoothTooltipTrackerDelegate</tt>.
 */
@protocol AISmoothTooltipTrackerDelegate
/*!
 * @brief Informs the delegate the point at which the mouse is hovering.
 *
 * Sent continuously as the mouse moves within the visible view monitored by the <tt>AISmoothTooltipTracker</tt>.  It is initially sent after the mouse hovers for at least a second in a single location within the view. Sent regardless of whether the application is active or not.
 * @param screenPoint The point, in screen coordinates, at which the mouse is hovering.
 */ 
- (void)showTooltipAtPoint:(NSPoint)screenPoint;

/*!
 * @brief Informs the delegate that the mouse has left the view so the tooltip should be hidden.
 *
 * Informs the delegate that the mouse has left the view so the tooltip should be hidden. Sent when the mouse leaves the view or it becomes obscured or hidden.
 */ 
- (void)hideTooltip;
@end

/*!
 * @class AISmoothTooltipTracker
 * @brief Controller to track the mouse when it hovers over a view, informing a delegate of the hover point
 * 
 * <p>An <tt>AISmoothTooltipTracker</tt> is created for a specific view.  It informs its delegate when the mouse hovers over the view for about a second.</p>
 * <p>The delegate will be informed of the mouse hover even if the application is not currently active (so long as the view is visible to the user).</p>
 * The delegate is updated as the mouse moves (via showTooltipAtPoint:), and is informed when the mouse leaves or the view is obscured or hidden (via hideTooltip)</p>
 * <p>Note: The delegate is not retained.  For maximum stability, the delegate should call setDelegate:nil some time before it deallocs. Not all implementations will -need- this, but it is recommended.</p>
 */
@interface AISmoothTooltipTracker : NSObject {
	NSView										*view;		//View we are tracking tooltips for
	id<AISmoothTooltipTrackerDelegate>			delegate;	//Our delegate
	
	BOOL				mouseInside;

	NSPoint				lastMouseLocation;				//Last known location of the mouse, used for movement tracking
	NSTimer				*tooltipMouseLocationTimer;		//Checks for mouse movement
	NSPoint				tooltipLocation;				//Last tooltip location we told our delegate about
    NSTrackingRectTag	tooltipTrackingTag;				//Tag for our tracking rect
    int 				tooltipCount;					//Used to determine how long before a tooltip appears
}

/*!
 * @brief Create an <tt>AISmoothTooltipTracker</tt>
 *
 * Create and return an autoreleased <tt>AISmoothTooltipTracker</tt> for <tt>inView</tt> and <tt>inDelegate</tt>.
 * @param inView The view in which to track mouse movements
 * @param inDelegate The 
 * @result	An <tt>AISmoothTooltipTracker</tt> instance
 */ 
+ (AISmoothTooltipTracker *)smoothTooltipTrackerForView:(NSView *)inView withDelegate:(id <AISmoothTooltipTrackerDelegate>)inDelegate;

/*!
 * @brief Set the delegate
 *
 * Set the delegate.  See <tt>AISmoothTooltipTrackerDelegate</tt> protocol discussion for details.
 */ 
- (void)setDelegate:(id<AISmoothTooltipTrackerDelegate>)inDelegate;

/*!	@brief	Retrieve the view that this object tracks
 *
 *	@return	The view that was originally passed to <code>+smoothTooltipTrackerForView:withDelegate:</code>.
 */
- (NSView *)view;

/*
 * @brief This should be called when the view for which we are tracking will be removed from its window without the window closing
 *
 * This allows us to remove our cursor rects (there isn't a notification by which we can do it automatically)
 */
- (void)viewWillBeRemovedFromWindow;

/*
 * @brief After calling viewWillBeRemovedFromWindow, call viewWasAddedToWindow to reinitiate tracking
 */
- (void)viewWasAddedToWindow;

@end
