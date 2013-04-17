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

#import "AIGradientView.h"


/*!
 * @class AIGradientView
 * @brief A view which draws an NSGradient on itself
 *
 */
@implementation AIGradientView

@synthesize startingColor, middleColor, endingColor, backgroundColor, angle;

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		backgroundColor = [NSColor colorWithCalibratedWhite:1.0f alpha:1.0f];
		startingColor = nil;
		middleColor = nil;
		endingColor = nil;
		
		angle = 270;
	}
	return self;
}

- (void)dealloc
{
	[startingColor release]; startingColor = nil;
	[middleColor release]; middleColor = nil;
	[endingColor release]; endingColor = nil;
	[backgroundColor release]; backgroundColor = nil;
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSRect drawingRect = [self bounds];
	NSRect halfRect = drawingRect;
	
	halfRect.size.height = halfRect.size.height / 2;
	halfRect.origin.y = halfRect.size.height;
	
	[backgroundColor set];
	NSRectFill(drawingRect);
	
	NSGradient *gradient;
	NSColor *endColor;
	
	if (startingColor) {
		if (middleColor && ![startingColor isEqual:middleColor]) {
			//Start to Middle
			endColor = middleColor;
			drawingRect = halfRect;
		} else if (endingColor && ![startingColor isEqual:endingColor]) {
			//Start to End
			endColor = endingColor;
		} else {
			//Start only
			endColor = startingColor;
		}
		
		gradient = [[NSGradient alloc] initWithStartingColor:startingColor
												 endingColor:endColor];
		[gradient drawInRect:drawingRect angle:angle];
		[gradient release];
	}

	if (middleColor) {
		halfRect.origin.y = 0.0f;
		if (endingColor && ![middleColor isEqual:endingColor]) {
			//Middle to End
			endColor = endingColor;
		} else {
			//Middle only
			endColor = middleColor;
		}

		gradient = [[NSGradient alloc] initWithStartingColor:middleColor
												 endingColor:endColor];
		[gradient drawInRect:halfRect angle:angle];
		[gradient release];
	}

	[super drawRect:rect];
}

@end
