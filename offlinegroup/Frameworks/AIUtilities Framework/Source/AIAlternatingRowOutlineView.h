/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <AIUtilities/AIOutlineView.h>

/*!
 * @class AIAlternatingRowOutlineView
 * @brief An <tt>AIOutlineView</tt> subclass supporting alternating rows.
 *
 * This functionality was added, with less control to the programmer, in OS X 10.3.  <tt>AIAlternatingRowOutlineView</tt> also supports disabling it from drawing its background (useful if cells wish to draw their own backgrounds and potentially be transparent).
 */
@interface AIAlternatingRowOutlineView : AIOutlineView {
    NSColor		*alternatingRowColor;
	
    BOOL		drawsAlternatingRows;
	BOOL		drawsBackground;
	BOOL		drawsGradientSelection;
}

/*!
 * @brief Set if the outline view draws a grid, alternating by rows.
 *
 * The grid will be drawn alternating between the background color and the color specified by setAlternatingRowColor:, which has a sane, light blue default.
 * @param flag YES if the alternating rows should be drawn
 */
- (void)setDrawsAlternatingRows:(BOOL)flag;
/*!
 * @brief Returns if the outline view draws alternating rows
 *
 * Returns if the outline view draws alternating rows
 * @return YES if the alternating rows will be drawn
 */
- (BOOL)drawsAlternatingRows;

/*!
 * @brief Set the color used for drawing alternating row backgrounds.
 *
 * Ignored if drawsAlternatingRows is NO.
 * @param color The <tt>NSColor</tt> to use for drawing alternating row backgrounds.
 */
- (void)setAlternatingRowColor:(NSColor *)color;

/*!
 * @brief Returns the color used for drawing alternating row backgrounds.
 *
 * This is only applicable if drawsAlternatingRows is YES.
 * @return color The <tt>NSColor</tt> used for drawing alternating row backgrounds.
 */
- (NSColor *)alternatingRowColor;

/*!
 * @brief Set if the outlineView should draw its background
 *
 * If this is NO, no background will be drawn (this means that the alternating rows will not be drawn, either).  This is useful if cells wish to draw their own backgrounds.
 * @param inDraw YES if the background should be drawn; NO if it should not.  The default is YES.
 */
- (void)setDrawsBackground:(BOOL)inDraw;

/*!
 * @brief Returns if the outlineView draws its background
 *
 * @return YES if the background is drawn; NO if it is not.
 */
- (BOOL)drawsBackground;

/*!
 * @brief Returns the <tt>NSColor</tt> which should be used to draw the background of the specified row
 *
 * @param row An integer row
 * @return An <tt>NSColor</tt> used to draw the background for <b>row</b>
 */
- (NSColor *)backgroundColorForRow:(int)row;

- (void)setDrawsGradientSelection:(BOOL)inDrawsGradientSelection;
- (BOOL)drawsGradientSelection;
@end

@interface AIAlternatingRowOutlineView (PRIVATE_AIAlternatingRowOutlineViewAndSubclasses)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
@end
