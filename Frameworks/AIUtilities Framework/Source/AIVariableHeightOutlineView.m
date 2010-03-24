//
//  AIVariableHeightOutlineView.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 11/25/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIVariableHeightOutlineView.h"
#import "AIApplicationAdditions.h"
#import "AIImageDrawingAdditions.h"
#import "AIGradientAdditions.h"

#define	DRAG_IMAGE_FRACTION	0.75f

@interface AIVariableHeightOutlineView ()
- (void)_initVariableHeightOutlineView;
- (NSImage *)dragImageForRows:(NSUInteger *)buf count:(NSUInteger)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset;
- (void)itemDidExpand:(NSNotification *)notification;
- (void)itemDidCollapse:(NSNotification *)notification;
@end

@implementation AIVariableHeightOutlineView

+ (void)initialize
{
	if (self == [AIVariableHeightOutlineView class]) {
		[self exposeBinding:@"totalHeight"];
	}
}

//Adium always toggles expandable items on click.
//This could become a preference via a set method for other implementations.
//static BOOL expandOnClick = NO;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initVariableHeightOutlineView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initVariableHeightOutlineView];
	}
	return self;
}

- (void)_initVariableHeightOutlineView
{
	totalHeight = -1;
	drawHighlightOnlyWhenMain = NO;
	drawsSelectedRowHighlight = YES;
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(itemDidExpand:) 
												 name:AIOutlineViewUserDidExpandItemNotification 
											   object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(itemDidCollapse:) 
												 name:AIOutlineViewUserDidCollapseItemNotification 
											   object:self];

}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

/*!
 * @brief Handle toggling expanded/collapsed state of an item for an event if needed
 *
 * Called from mouseDown; separated out to let subclasses have finer granularity of control
 *
 * @param theEvent The triggerring event
 * @param needsExpandCollapseSuppression Pointer to a BOOL which, on return, will be YES if we need to prevent NSOutlineView from trying to expand/collapse a group.
 *
 * @result YES if the event was handled; NO if it should be processed normally
 */
- (BOOL)handleExpandedStateToggleForEvent:(NSEvent *)theEvent needsExpandCollapseSuppression:(BOOL *)needsExpandCollapseSuppression
{
	NSPoint viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil]; 
	NSInteger		row = [self rowAtPoint:viewPoint]; 
	id		item = [self itemAtRow:row]; 
	BOOL	handled;

	//Expand/Collapse groups on mouse DOWN instead of mouse up (Makes it feel a ton faster) 
	if (item && [self isExpandable:item] && 
		(viewPoint.x < NSHeight([self frameOfCellAtColumn:0 row:row]))) { 
		/* XXX - This is kind of a hack.  We need to check < WidthOfDisclosureTriangle, and are using the fact that 
		 *       the disclosure width is about the same as the height of the row to fudge it. -ai 
		 */
		if ([self isItemExpanded:item]) { 
			[self collapseItem:item]; 
		} else { 
			[self expandItem:item]; 
		}
		
		handled = YES;
	} else {
		handled = NO;
	}
	
	if (needsExpandCollapseSuppression) *needsExpandCollapseSuppression = NO;
	
	return handled;
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren
{
	if (!suppressExpandCollapseRequests)
		[super collapseItem:item collapseChildren:collapseChildren];
}

- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren;
{
	if (!suppressExpandCollapseRequests)
		[super expandItem:item expandChildren:expandChildren];
}

//Handle mouseDown events to toggle expandable items when they are clicked 
- (void)mouseDown:(NSEvent *)theEvent 
{ 
	BOOL needsExpandCollapseSuppression;
	if (![self handleExpandedStateToggleForEvent:theEvent needsExpandCollapseSuppression:&needsExpandCollapseSuppression]) {
		suppressExpandCollapseRequests = needsExpandCollapseSuppression;
		[super mouseDown:theEvent]; 
		suppressExpandCollapseRequests = NO;
	}
} 

//Row height cache -----------------------------------------------------------------------------------------------------
#pragma mark Row height cache
- (void)resetRowHeightCache
{
	totalHeight = -1;
}

-(void)noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)indexSet
{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[super noteHeightOfRowsWithIndexesChanged:indexSet];
	[self didChangeValueForKey:@"totalHeight"];
}

- (void)noteNumberOfRowsChanged
{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[super noteNumberOfRowsChanged];
	[self didChangeValueForKey:@"totalHeight"];
}

- (void)reloadData
{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[super reloadData];
	[self didChangeValueForKey:@"totalHeight"];
}

- (void)reloadItem:(id)item reloadChildren:(BOOL)reloadChildren
{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[super reloadItem:item reloadChildren:reloadChildren];
	[self didChangeValueForKey:@"totalHeight"];	
}

//On expand/collapse
- (void)itemDidExpand:(NSNotification *)notification{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[self didChangeValueForKey:@"totalHeight"];
}
- (void)itemDidCollapse:(NSNotification *)notification{
	[self willChangeValueForKey:@"totalHeight"];
	[self resetRowHeightCache];
	[self didChangeValueForKey:@"totalHeight"];
}


- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return [tableColumn dataCell];
}

#pragma mark Drawing
// Consider all rows by default.
- (BOOL)shouldResetAlternating:(int)row
{
	return NO;
}

- (void)drawAlternatingRowsInRect:(NSRect)rect
{
	/* Draw the alternating rows.  If we draw alternating rows, the cell in the first column
	 * can optionally suppress drawing.
	 */
	if ([self usesAlternatingRowBackgroundColors]) {
		BOOL alternateColor = YES;
		NSInteger numberOfRows = [self numberOfRows], rectNumber = 0;
		NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:0];
		NSRect *gridRects = (NSRect *)alloca(sizeof(NSRect) * numberOfRows);
		
		for (int row = 0; row < numberOfRows; row++) {
			id 	cell = [self cellForTableColumn:tableColumn item:[self itemAtRow:row]];
			
			alternateColor = [self shouldResetAlternating:row] ? YES : !alternateColor;
			
			if (alternateColor &&
				(![cell respondsToSelector:@selector(drawGridBehindCell)] || [cell drawGridBehindCell])) {
				NSRect	thisRect = [self rectOfRow:row];

				if (NSIntersectsRect(thisRect, rect)) { 
					gridRects[rectNumber++] = thisRect;
				}
			}
		}
		
		if (rectNumber > 0) {
			[[self alternatingRowColor] set];
			NSRectFillList(gridRects, rectNumber);
		}		
	}
}

- (void)drawRow:(NSInteger)row clipRect:(NSRect)rect
{
	if (row >= 0 && row < [self numberOfRows]) { //Somebody keeps calling this method with row = numberOfRows, which is wrong.
		NSArray		*tableColumns = [self tableColumns];
		id			item = [self itemAtRow:row];
		NSUInteger	tableColumnIndex, count = [tableColumns count];

		for (tableColumnIndex = 0 ; tableColumnIndex < count ; tableColumnIndex++) {
			NSTableColumn	*tableColumn;
			NSRect			cellFrame;
			id				cell;
			BOOL			selected;

			tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			cell = [self cellForTableColumn:tableColumn item:item];

			[[self delegate] outlineView:self
						 willDisplayCell:cell
						  forTableColumn:tableColumn
									item:item];

			selected = [self isRowSelected:row];
			[cell setHighlighted:selected];

			[cell setObjectValue:[[self dataSource] outlineView:self
									  objectValueForTableColumn:tableColumn
														 byItem:item]];

			cellFrame = [self frameOfCellAtColumn:tableColumnIndex row:row];

			//Draw the cell
			if (selected) [cell _drawHighlightWithFrame:cellFrame inView:self];
			[cell drawWithFrame:cellFrame inView:self];
		}
	}
}

- (NSImage *)dragImageForRows:(NSUInteger *)buf count:(NSUInteger)count tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSRect			rowRect;
	CGFloat			yOffset;
	NSUInteger	i, firstRow, row = 0, tableColumnsCount;

	firstRow = buf[0];

	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
	//spill outside the drag image.
	rowRect = [self rectOfRow:firstRow];
	image = [[[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
													  rowRect.size.height*count + [self intercellSpacing].height*(count-1))] autorelease];

	//Draw (Since the OLV is normally flipped, we have to be flipped when drawing)
	[image setFlipped:YES];
	[image lockFocus];

	tableColumnsCount = [tableColumns count];

	yOffset = 0;
	for (i = 0; i < count; i++) {
		id		item;
		row = buf[i];

		item = [self itemAtRow:row];

		//Draw each table column
		unsigned tableColumnIndex;
		for (tableColumnIndex = 0 ; tableColumnIndex < tableColumnsCount ; tableColumnIndex++) {

			NSTableColumn	*tableColumn = [tableColumns objectAtIndex:tableColumnIndex];
			id		cell = [self cellForTableColumn:tableColumn item:item];

			//Render the cell
			[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:tableColumn item:item];
			[cell setHighlighted:NO];
			[cell setObjectValue:[[self dataSource] outlineView:self
									  objectValueForTableColumn:tableColumn
														 byItem:item]];

			//Draw the cell
			NSRect	cellFrame = [self frameOfCellAtColumn:tableColumnIndex row:row];
			[cell drawWithFrame:NSMakeRect(cellFrame.origin.x - rowRect.origin.x,yOffset,cellFrame.size.width,cellFrame.size.height)
						 inView:self];
		}

		//Offset so the next drawing goes directly below this one
		yOffset += (rowRect.size.height + [self intercellSpacing].height);
	}

	[image unlockFocus];
	[image setFlipped:NO];

	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
	dragImageOffset->x = (rowRect.size.width / 2.0f) - clickLocation.x;


	return [image imageByFadingToFraction:DRAG_IMAGE_FRACTION];

}

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

//Our default drag image will be cropped incorrectly, so we need a custom one here
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSImage			*image;
	NSUInteger	i, bufSize = [dragRows count];
	NSUInteger	*buf = malloc(bufSize * sizeof(NSUInteger));

	for (i = 0; i < bufSize; i++) {
		buf[i] = [[dragRows objectAtIndex:0] unsignedIntValue];
	}

	image = [self dragImageForRows:buf count:bufSize tableColumns:nil event:dragEvent offset:dragImageOffset];

	free(buf);

	return image;
}

- (NSInteger)totalHeight
{
	if (totalHeight == -1) {
		NSInteger	numberOfRows = [self numberOfRows];
		NSSize	intercellSpacing = [self intercellSpacing];
		
		for (NSInteger i = 0; i < numberOfRows; i++) {
			totalHeight += ([self rectOfRow:i].size.height + intercellSpacing.height);
		}
	}
	
	return totalHeight;
}

//Custom highlight management
- (void)setDrawHighlightOnlyWhenMain:(BOOL)inFlag
{
	drawHighlightOnlyWhenMain = inFlag;
}
- (BOOL)drawHighlightOnlyWhenMain
{
	return drawHighlightOnlyWhenMain;
}

- (void)setDrawsSelectedRowHighlight:(BOOL)inFlag
{
	drawsSelectedRowHighlight = inFlag;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	if (drawsSelectedRowHighlight && (!drawHighlightOnlyWhenMain || [[self window] isMainWindow])) {
		if ([self drawsGradientSelection]) {
			//We can trust super to draw the selection properly with a gradient...
			[super highlightSelectionInClipRect:clipRect];

		} else {
			//But NSOutlineView's own handling won't deal with our variable heights properly
			NSIndexSet *indices = [self selectedRowIndexes];
			NSUInteger bufSize = [indices count];
			NSUInteger *buf = malloc(bufSize * sizeof(NSUInteger));
			NSUInteger i = 0, j = 0;
			
			NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
			[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
			
			NSRect *selectionRects = (NSRect *)malloc(sizeof(NSRect) * bufSize);
			
			while (i < bufSize) {
				NSUInteger startIndex = buf[i];
				NSUInteger lastIndex = buf[i];
				while ((i + 1 < bufSize) &&
					   (buf[i + 1] == lastIndex + 1)){
					i++;
					lastIndex++;
				}
				
				NSRect highlightRect = NSUnionRect([self rectOfRow:startIndex],
												   [self rectOfRow:lastIndex]);				
				selectionRects[j++] = highlightRect;			
				
				i++;		
			}

			if ([[self window] firstResponder] != self || ![[self window] isKeyWindow]) {
				[[NSColor secondarySelectedControlColor] set];
			} else {
				[[NSColor alternateSelectedControlColor] set];
			}

			NSRectFillListUsingOperation(selectionRects, j, NSCompositeSourceOver);

			free(buf);
			free(selectionRects);
		}

	}
}

@end
