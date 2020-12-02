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

#import <AIUtilities/AIAlternatingRowOutlineView.h>

/*!
 * @class AIVariableHeightOutlineView
 * @brief An outlineView which supports variable heights on a per-row basis.
 *
 * This <tt>AIAlternatingRowOutlineView</tt> subclass allows each row to have a different height as determined by the data source. Note that the delegate <b>must</b> implement the method(s) described in <tt>AIVariableHeightOutlineViewDataSource</tt>. 
 */
@interface AIVariableHeightOutlineView : AIAlternatingRowOutlineView {
	NSInteger		totalHeight;

	BOOL	drawHighlightOnlyWhenMain;
	BOOL	drawsSelectedRowHighlight;
	
	BOOL	suppressExpandCollapseRequests;
}

/*!
 * @brief Returns the total height needed to display all rows of the outline view
 *
 * Returns the total height needed to display all rows of the outline view
 * @return The total required height
 */
- (NSInteger)totalHeight;

/*!
 * @brief Set if the selection highlight should only be drawn when the outlineView is the main (active) view.
 *
 * Set to YES if the selection highlight should only be drawn when the outlineView is the main (active) view. The default value is NO.
 * @param inFlag YES if the highlight should only be drawn when main.
 */
- (void)setDrawHighlightOnlyWhenMain:(BOOL)inFlag;

/*!
 * @brief Return if the highlight is only drawn when the outlineView is the main view.
 *
 * Return if the highlight is only drawn when the outlineView is the main view.
 * @return YES if the highlight is only be drawn when main.
 */
- (BOOL)drawHighlightOnlyWhenMain;

/*!
 * @brief Set if the selection highlight should be drawn at all.
 *
 * Set to YES if the selection highlight should be drawn; no if it should be suppressed.  The default value is YES.
 * @param inFlag YES if the highlight be drawn; NO if it should not.
 */
- (void)setDrawsSelectedRowHighlight:(BOOL)inFlag;

/*!
 * @brief Cell corresponding to table column.
 *
 * Mostly useful for subclassing; by default, this is simply [tableColumn dataCell]
 * @return NSCell object corresponding to the given table column.
 */
- (id)cellForTableColumn:(NSTableColumn *)tableColumn item:(id)item;

/*!
 * @brief Should the given row reset the alternating
 *
 * @param row The row to be considered
 * @return YES if the row should reset alternating
 */
- (BOOL)shouldResetAlternating:(int)row;


@end

@interface AIVariableHeightOutlineView (AIVariableHeightOutlineViewAndSubclasses)
- (void)resetRowHeightCache;
- (void)updateRowHeightCache;
/*!
 * @brief Row drawing routine
 *
 * Subclasses should implement this rather than drawRow:clipRect: to override drawing.
 *
 * AIVariableHeightOutlineView calls this as part of its drawRow:clipRect: implementation, and some drawing operations
 * may *not* call drawRow:clipRect: at all but rather call this method only.
 *
 * @result YES if the row was drawn; NO if the row was not drawn because it is below the clipping rect
 */
- (BOOL)_ai_drawRow:(NSInteger)row clipRect:(NSRect)rect;
@end

@interface NSObject (AIVariableHeightGridSupport)
- (BOOL)drawGridBehindCell;
@end

@interface NSCell (UndocumentedHighlightDrawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

