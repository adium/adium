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

#import "AIDividedAlternatingRowOutlineView.h"

@implementation AIDividedAlternatingRowOutlineView

#pragma mark Drawing
/*
 * @brief Draw a divider if wanted for this item
 */ 
- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
	//Getting the object for this row
	AIDividerPosition dividerPosition;

	//Does the dataSource know what we want to know?
	if ([[self dataSource] respondsToSelector:@selector(outlineView:dividerPositionForItem:)]) {
		//Position of the divider
		dividerPosition = [(id<AIDividedAlternatingRowOutlineViewDelegate>)[self dataSource] outlineView:self dividerPositionForItem:[self itemAtRow:rowIndex]];
	} else {
		dividerPosition = AIDividerPositionNone;
	}
	
	if (dividerPosition != AIDividerPositionIsDivider) {
		//Call super's implementation if the row itself is not a divider
		[super drawRow:rowIndex clipRect:clipRect];

		//We're done if there's no divider to draw
		if (dividerPosition == AIDividerPositionNone)
			return;
	}
	
	//Set-up context
	[NSGraphicsContext saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	NSRect rowRect = [self rectOfRow:rowIndex];
	
	//This could be done better. Ask the dataSource for color and width!
	[[NSColor headerColor] set];
	[NSBezierPath setDefaultLineWidth:1.5f];

	//Drawing the divider
	switch (dividerPosition) {
		case AIDividerPositionAbove:
			//Divider above the current item
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, NSMinY(rowRect))
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, NSMinY(rowRect))];
			break;
			
		case AIDividerPositionBelow:
			//Divider below the current item
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, NSMaxY(rowRect))
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, NSMaxY(rowRect))];
			break;
			
		case AIDividerPositionIsDivider:
			//The item itself is the divider
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, (NSMaxY(rowRect)+NSMinY(rowRect)) / 2.0f)
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, (NSMaxY(rowRect)+NSMinY(rowRect)) / 2.0f)];
			break;
			
		case AIDividerPositionNone:
			//We will never reach this point
			break;
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
