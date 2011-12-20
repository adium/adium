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

#import "AIStandardListScrollView.h"
#import <AIUtilities/AIApplicationAdditions.h>

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
	
	// we don't need this on Lion.
	if ([NSApp isOnLionOrNewer]) {
		NSRect myBounds = [self bounds];
		NSRect bottomRect = NSMakeRect(NSMaxX(myBounds) - 20, NSMinY(myBounds), 20, NSMaxY(myBounds));
		[self setNeedsDisplayInRect:bottomRect];
	}
}

@end
