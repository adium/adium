//
//  AIMultiCellOutlineView.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

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

- (void)dealloc
{
	[contentCell release];
	[groupCell release];

	[super dealloc];
}

//Cell used for content rows
- (void)setContentCell:(NSCell *)cell{
	if (contentCell != cell) {
		[contentCell release];
		contentCell = [cell retain];
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
		[groupCell release];
		groupCell = [cell retain];
	}
	groupRowHeight = [groupCell cellSize].height;
	
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}
- (NSCell *)groupCell{
	return groupCell;
}
- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return ([[self delegate] outlineView:self isGroup:item] ? groupCell : contentCell);
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
	int		row = [self rowAtPoint:viewPoint]; 
	id		item = [self itemAtRow:row]; 
	BOOL	handled;

	//Expand/Collapse groups on mouse DOWN instead of mouse up (Makes it feel a ton faster) 
	if (item && [self isExpandable:item] && 
		(viewPoint.x < NSHeight([self frameOfCellAtColumn:0 row:row]))) { 
		/* XXX - This is kind of a hack.  We need to check < WidthOfDisclosureTriangle, and are using the fact that 
		 *       the disclosure width is about the same as the height of the row to fudge it. -ai 
		 */
		if ([[self delegate] outlineView:self isGroup:item]) {
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
