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

#import "AIMultiCellOutlineView.h"

@interface AIMultiCellOutlineView ()
- (void)_initMultiCellOutlineView;
@end

@implementation AIMultiCellOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initMultiCellOutlineView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initMultiCellOutlineView];
	}
	return self;
}

- (void)_initMultiCellOutlineView
{
	contentCell = nil;
	groupCell = nil;
	contentRowHeight = 0;
	groupRowHeight = 0;
}

//Cell used for content rows
- (void)setContentCell:(NSCell *)cell{
	if (contentCell != cell) {
		contentCell = cell;
	}
	contentRowHeight = [contentCell cellSize].height;
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}
- (NSCell *)contentCell{
	return contentCell;
}

//Cell used for group rows
- (void)setGroupCell:(NSCell *)cell{
	if (groupCell != cell) {
		groupCell = cell;
	}
	groupRowHeight = [groupCell cellSize].height;
	
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}
- (NSCell *)groupCell{
	return groupCell;
}
- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return ([(id<AIMultiCellOutlineViewDelegate>)[self delegate] outlineView:self isGroup:item] ? groupCell : contentCell);
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
		if ([(id<AIMultiCellOutlineViewDelegate>)[self delegate] outlineView:self isGroup:item]) {
			/* For a group, perform the expand/collapse */
			if ([self isItemExpanded:item]) { 
				[self collapseItem:item]; 
			} else { 
				[self expandItem:item]; 
			}
			handled = YES;
		} else {
			/* If it's not a group, we'll need to suppress NSOutlineView from trying to do an expand/contract */
			if (needsExpandCollapseSuppression) *needsExpandCollapseSuppression = YES;
			handled = NO;
		}
		
	} else {
		if (needsExpandCollapseSuppression) *needsExpandCollapseSuppression = NO;
		handled = NO;
	}
	
	return handled;
}

@end
