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

#import "AIEmoticonPackPreviewTableView.h"
#import <AIUtilities/AIGenericViewCell.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

#define	DRAG_IMAGE_FRACTION	0.75f

/*!
 * @class AIEmoticonPackPreviewTableView
 * @brief Table view subclass for the emoticon pack preview
 *
 * This NSTableView subclass draws images for AIGenericViewCell-using columns.  It only draws the image
 * for the first column so is not suitable for general use.
 */
@implementation AIEmoticonPackPreviewTableView

- (NSImage *)dragImageForRows:(NSUInteger[])buf count:(NSUInteger)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSTableColumn	*tableColumn;
	NSRect			rowRect;
	CGFloat			yOffset;
	NSUInteger	i, firstRow, row;
	
	firstRow = buf[0];
	
	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
	//spill outside the drag image.
	rowRect = [self rectOfRow:firstRow];
	image = [[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
													  rowRect.size.height*count + [self intercellSpacing].height*(count-1))];
	
	//Draw
	[image lockFocus];
	
	yOffset = 0;
	tableColumn = [[self tableColumns] objectAtIndex:0];
	for (i = 0; i < count; i++) {
		
		row = buf[i];
		id		cell = [tableColumn dataCellForRow:row];
		
		//Render the cell
		if ([self.delegate respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)]) {
			[self.delegate tableView:self willDisplayCell:cell forTableColumn:nil row:row];
		}
		if ([[self dataSource] respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)]) {
			[cell setObjectValue:[[self dataSource] tableView:self objectValueForTableColumn:nil row:row]];
		}
		
		[cell setHighlighted:NO];
		
		//Draw the cell
		NSRect	cellFrame = [self frameOfCellAtColumn:0 row:row];
		NSRect	targetFrame = NSMakeRect(cellFrame.origin.x - rowRect.origin.x,yOffset,cellFrame.size.width,cellFrame.size.height);
		
		//Cute little hack so we can do drag images when using AIGenericViewCell to put views into tables
		if ([cell isKindOfClass:[AIGenericViewCell class]]) {
			[(AIGenericViewCell *)cell drawEmbeddedViewWithFrame:targetFrame
														  inView:self];
		} else {
			[cell drawWithFrame:targetFrame
						 inView:self];
		}
		
		//Offset so the next drawing goes directly below this one
		yOffset += (rowRect.size.height + [self intercellSpacing].height);
	}
	
	[image unlockFocus];
	
	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
	dragImageOffset->x = (rowRect.size.width / 2.0f) - clickLocation.x;
	
	return [image imageByFadingToFraction:DRAG_IMAGE_FRACTION];
}

//Our default drag image will be cropped incorrectly, so we need a custom one here
- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSUInteger	bufSize = [dragRows count];
	NSUInteger	*buf = malloc(bufSize * sizeof(NSUInteger));
	
	NSRange range = NSMakeRange([dragRows firstIndex], ([dragRows lastIndex]-[dragRows firstIndex]) + 1);
	[dragRows getIndexes:buf maxCount:bufSize inIndexRange:&range];
	
	image = [self dragImageForRows:buf count:bufSize tableColumns:tableColumns event:dragEvent offset:dragImageOffset]; 
	
	free(buf);
	
	return image;
}

@end
