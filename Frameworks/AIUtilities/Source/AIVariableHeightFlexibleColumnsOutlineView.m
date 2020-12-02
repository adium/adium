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

#import "AIVariableHeightFlexibleColumnsOutlineView.h"

#define FLIPPY_WIDTH		10
#define	FLIPPY_HEIGHT		10
#define FLIPPY_TEXT_PADDING 2

/*
 * @class AIVariableHeightFlexibleColumnsOutlineView
 * @brief AIVariableHeightOutlineView subclass which can allow columns to extend to the edge of the outline view
 *
 * The delegate of AIVariableHeightFlexibleColumnsOutlineView can specify on a per-column, per-row basis if
 * the column for that row should be allowed to extend from its origin to the right edge of the outline view -- that is,
 * be unconstrained by its column boundary.  Any subsequent columns in that row will not be drawn.
 */
@implementation AIVariableHeightFlexibleColumnsOutlineView

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	NSRect frameOfCell = [super frameOfCellAtColumn:column row:row];
	if ([[self delegate] respondsToSelector:@selector(outlineView:extendToEdgeColumn:ofRow:)] &&
	   [(id<AIVariableHeightFlexibleColumnsOutlineViewDelegate>)[self delegate] outlineView:self extendToEdgeColumn:column ofRow:row]) {
		frameOfCell.size.width = [self frame].size.width - frameOfCell.origin.x - AIround(([self intercellSpacing].width)/2);
	}
	
	return frameOfCell;
}

#pragma mark Drawing
- (BOOL)_ai_drawRow:(NSInteger)row clipRect:(NSRect)rect;
{
	if (row >= 0 && row < [self numberOfRows]) { //Somebody keeps calling this method with row = numberOfRows, which is wrong.		
		if (NSIntersectsRect([self rectOfRow:row], rect) == FALSE)
			return NO;

		NSArray		*tableColumns = [self tableColumns];
		id			item = [self itemAtRow:row];
		NSUInteger	tableColumnIndex, count = [tableColumns count];
		
		BOOL		delegateRespondsToExtendToEdgeColumn = [[self delegate] respondsToSelector:@selector(outlineView:extendToEdgeColumn:ofRow:)];

		for (tableColumnIndex = 0 ; tableColumnIndex < count ; tableColumnIndex++) {
			NSTableColumn	*tableColumn;
			NSRect			cellFrame;
			id				cell;
			BOOL			selected;
			
			tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			cell = [self cellForTableColumn:tableColumn item:item];
			cellFrame = [self frameOfCellAtColumn:tableColumnIndex row:row];

			[[self delegate] outlineView:self
						 willDisplayCell:cell 
						  forTableColumn:tableColumn
									item:item];
			
			selected = [self isRowSelected:row];
			[cell setHighlighted:selected];
			
			[cell setObjectValue:[[self dataSource] outlineView:self 
									  objectValueForTableColumn:tableColumn
														 byItem:item]];
			
			
			
			if (tableColumnIndex == 0) {
				//Draw flippy triangle
				if ([self isExpandable:item]) {
					
					cellFrame.origin.x += FLIPPY_TEXT_PADDING/2;
					cellFrame.size.width -= FLIPPY_TEXT_PADDING/2;
					
					NSBezierPath	*arrowPath = [NSBezierPath bezierPath];

					NSPoint			center = NSMakePoint(cellFrame.origin.x + FLIPPY_WIDTH/2,
														 cellFrame.origin.y + (cellFrame.size.height/2.0f));
					/* Remember: The view is flipped */
					if ([self isItemExpanded:item]) {
						//Bottom point
						[arrowPath moveToPoint:NSMakePoint(center.x, 
														   center.y + FLIPPY_HEIGHT/2)];
						//Move to top left
						[arrowPath relativeLineToPoint:NSMakePoint(-(FLIPPY_WIDTH/2), -FLIPPY_HEIGHT)];
						
						//Move to top right
						[arrowPath relativeLineToPoint:NSMakePoint(FLIPPY_WIDTH, 0)];
					} else {
						//Bottom left
						[arrowPath moveToPoint:NSMakePoint(center.x - (FLIPPY_WIDTH/2), 
														   center.y + (FLIPPY_HEIGHT/2))];
						//Move to top left
						[arrowPath relativeLineToPoint:NSMakePoint(0, -FLIPPY_HEIGHT)];
						
						//Move to middle right
						[arrowPath relativeLineToPoint:NSMakePoint(FLIPPY_WIDTH, FLIPPY_HEIGHT/2)];
					}
					
					[arrowPath closePath];
					
					if (selected) {
						[[NSColor whiteColor] set];
					} else {
						[[NSColor darkGrayColor] set];
					}
					[arrowPath fill];
					
					cellFrame.origin.x += FLIPPY_WIDTH + FLIPPY_TEXT_PADDING/2;
					cellFrame.size.width -= FLIPPY_WIDTH + FLIPPY_TEXT_PADDING/2;
				}
			}
			
			//Draw the cell
			[cell drawWithFrame:cellFrame inView:self];
	
			//Stop drawing if this column extends to the edge
			if (delegateRespondsToExtendToEdgeColumn &&
			   [(id<AIVariableHeightFlexibleColumnsOutlineViewDelegate>)[self delegate] outlineView:self extendToEdgeColumn:tableColumnIndex ofRow:row]) {
				break;
			}
		}
	}
	
	return YES;
}

@end
