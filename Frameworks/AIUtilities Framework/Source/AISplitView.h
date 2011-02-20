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


/*!
 * @class AISplitView
 * @brief <tt>NSSplitView</tt> subclass with additional customization
 *
 * This subclass of NSSplitView allows the user to adjust the thickness of the divider and disable drawing of the
 * divider 'dot' graphic.
 */
@interface AISplitView : NSSplitView {
	CGFloat	dividerThickness;
	BOOL	drawDivider;
}

/*!
 * @brief Set the thickness of the split divider
 *
 * Set the thickness of the split divider
 * @param inThickness Desired divider thickness
 */
- (void)setDividerThickness:(CGFloat)inThickness;

/*!
 * @brief Toggle drawing of the divider graphics
 *
 * Toggle display of the divider graphics (The 'dot' in the center of the divider)
 * @param inDraw NO to disable drawing of the dot, YES to enable it
 */
- (void)setDrawsDivider:(BOOL)inDraw;

@end
