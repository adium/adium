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

#import "AIMessageTabSplitView.h"
#import <PSMTabBarControl/NSBezierPath_AMShading.h>

@implementation AIMessageTabSplitView

- (void)dealloc
{
	[leftColor release];
	[rightColor release];
	[super dealloc];
}

- (void)setLeftColor:(NSColor *)inLeftColor rightColor:(NSColor *)inRightColor
{
	if (leftColor != inLeftColor) {
		[leftColor release];
		leftColor = [inLeftColor retain];
	}

	if (rightColor != inRightColor) {
		[rightColor release];
		rightColor = [inRightColor retain];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)setTabPosition:(AIMessageSplitTabPosition)inPosition
{
	position = inPosition;
}

-(void)drawDividerInRect:(NSRect)aRect
{	
	if (rightColor && leftColor) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
		[path linearVerticalGradientFillWithStartColor:leftColor 
											  endColor:rightColor];
		NSBezierPath *line = nil;
		
		if (position == AIMessageSplitTabPositionLeft) {
			line = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMaxX(aRect) - 1, aRect.origin.y, 1, aRect.size.height)];
		}
		[[NSColor windowFrameColor] set];
		[line fill];
	} else {
		[super drawDividerInRect:aRect];
	}
}

@end
