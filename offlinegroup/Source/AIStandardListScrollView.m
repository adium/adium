//
//  AIStandardListScrollView.m
//  Adium
//
//  Created by Evan Schoenberg on 1/26/08.
//

#import "AIStandardListScrollView.h"

@implementation AIStandardListScrollView

/*!
 * @brief Update after the clip view scrolls
 *
 * This is needed because our scroll view overlaps the bottom-right resize widget in the standard contact list window and has a small scroller.
 * The window draws the resize widget, which leaves behind white artifacts in the area that a large scroller would be but a small one is not.
 *
 * If we added a bar to the bottom of the standard window, this could go away.
 */
- (void)reflectScrolledClipView:(NSClipView *)aClipView
{
	[super reflectScrolledClipView:aClipView];
	
	NSRect myBounds = [self bounds];
	NSRect bottomRect = NSMakeRect(NSMaxX(myBounds) - 20, NSMinY(myBounds), 20, NSMaxY(myBounds));
	[self setNeedsDisplayInRect:bottomRect];
}

@end
