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

#import "ESRankingCell.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>

@implementation ESRankingCell

static NSColor	*drawColor = nil;

- (void)setPercentage:(CGFloat)inPercentage
{
	percentage = inPercentage;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (percentage != 0) {
		//2 pixels left, 4 pixels right
		cellFrame.size.width -= 6;
		cellFrame.origin.x += 2;
		
		//3 pixels top, 3 pixels bottom
		cellFrame.size.height -= 6;
		cellFrame.origin.y += 3;
		
		//Draw in a horizontal area of cellFrame equal to (percentage) of it
		cellFrame.size.width *= percentage;
		
		if (!drawColor) drawColor = [[NSColor alternateSelectedControlColor] darkenAndAdjustSaturationBy:0.2f];

		[drawColor set];
		[[NSBezierPath bezierPathWithRect:cellFrame] fill];
	}
}

@end
