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

#import "AIPrettyView.h"
#import <AIUtilities/AIBezierPathAdditions.h>


@implementation AIPrettyView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	
	NSRect insetRect = NSMakeRect(self.frame.origin.x + 5, self.frame.origin.y + 5, self.frame.size.width - 10, self.frame.size.height - 10);
	
	if ([[[[[[[[messageView contentView] subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0] hasVerticalScroller]) {
		insetRect.size.width -= [messageView verticalScroller].frame.size.width;
	}
	
    NSBezierPath *bp = [NSBezierPath bezierPathWithRoundedRect:insetRect radius:5.0];
	
	[[NSColor whiteColor] set];
	
	[bp fill];
	
	NSRect entryRect = NSMakeRect(10, 10, insetRect.size.width - 10, insetRect.size.height - 10);
	
	[entryField enclosingScrollView].frame = entryRect;
}

- (void)mouseDown:(NSEvent *)event
{
	[[entryField window] makeFirstResponder:entryField];
}


@end
