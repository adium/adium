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

#import <AppKit/NSCell.h>

/*
 * @class AIGenericViewCell
 * @brief A cell which can display any view
 *
 * This cell allows any view to be used in a table or outlineview.
 * Based on sample code from SubViewTableView by Joar Wingfors, http://www.joar.com/code/
 */
@interface AIGenericViewCell : NSCell
{
	NSView	*embeddedView;
}

/*
 * @brief Set the NSView this cell displays
 *
 * This should be called before the cell is used, such as in a tableView:willDisplayCell: type delegate method.
 *
 * @param inView The view to display
 */
- (void)setEmbeddedView:(NSView *)inView;

/*
 * @brief Used within AIUtilities to generate a drag image from this cell
 *
 * This is a hack, and it's not a particularly great one.  A drawing context must be locked before this is called.
 *
 * @param cellFrame The frame of the cell
 * @param controlView The view into which the cell is drawing
 */
- (void)drawEmbeddedViewWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end
