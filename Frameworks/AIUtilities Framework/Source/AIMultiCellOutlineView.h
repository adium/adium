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

#import <AIUtilities/AIVariableHeightOutlineView.h>

/*!
 * @class AIMultiCellOutlineView
 * @brief An outline view with two different cells, one each for expandable and nonexpandable items
 *
 * This outline view is a subclass of <tt>AIAlternatingRowOutlineView</tt> which simplifies its implementation into the case with two different cells, one for expandable items ("groups") and one for nonexpandable items ("content").
 */
@interface AIMultiCellOutlineView : AIVariableHeightOutlineView {
	NSCell	*contentCell;
	NSCell	*groupCell;
	
	CGFloat   groupRowHeight;
	CGFloat   contentRowHeight;
}

/*!
 * @brief Set the cell used for nonexpandable items
 *
 * Set the cell used for displaying nonexpandable items ("content")
 * @param cell The <tt>NSCell</tt> to use for content.
 */
- (void)setContentCell:(NSCell *)cell;

/*!
 * @brief Returns the cell used for nonexpandable items
 *
 * Returns the cell used for displaying nonexpandable items ("content")
 * @return The <tt>NSCell</tt> used for content.
 */
- (NSCell *)contentCell;

/*!
 * @brief Set the cell used for expandable items
 *
 * Set the cell used for displaying expandable items ("groups")
 * @param cell The <tt>NSCell</tt> to use for groups.
 */
- (void)setGroupCell:(NSCell *)cell;

/*!
 * @brief Returns the cell used for expandable items
 *
 * Returns the cell used for displaying expandable items ("groups")
 * @return The <tt>NSCell</tt> used for groups.
 */
- (NSCell *)groupCell;

@end

@protocol AIMultiCellOutlineViewDelegate
/*
 * @brief Is this item a group?
 *
 * Note that we do NOT use the Mac OS X 10.5+ delegate method outlineView:isGroupItem:.
 * Doing so requests that the cell be drawn in the "group style", which may not be desired.
 * If both behaviors are desired, simply implement this delegate method and call outlineView:isGroupItem: to
 * share code between the two.
 *
 * @result YES if the groupCell should be used for displaying this item.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroup:(id)item;
@end
