//
//  AIMultiCellOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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

@interface NSObject (AIMultiCellOutlineViewDelegate)
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
