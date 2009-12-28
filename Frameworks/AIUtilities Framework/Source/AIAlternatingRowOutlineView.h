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
	
	BOOL		drawsBackground;
	BOOL		drawsGradientSelection;
}

/*!
 * @brief The color used for drawing alternating row backgrounds.
 *
 * Ignored if usesAlternatingRowBackgroundColors is NO.
 */
@property (readwrite, nonatomic, retain) NSColor *alternatingRowColor;

/*!
 * @brief Whether the outlineView should draw its background
 *
 * If this is NO, no background will be drawn (this means that the alternating rows will not be drawn, either).  This is useful if cells wish to draw their own backgrounds.
 */
@property (readwrite, nonatomic) BOOL drawsBackground;

/*!
 * @brief Returns the <tt>NSColor</tt> which should be used to draw the background of the specified row
 *
 * @param row An integer row
 * @return An <tt>NSColor</tt> used to draw the background for <b>row</b>
 */
- (NSColor *)backgroundColorForRow:(NSInteger)row;

@property (readwrite, nonatomic) BOOL drawsGradientSelection;
@end

@interface AIAlternatingRowOutlineView (PRIVATE_AIAlternatingRowOutlineViewAndSubclasses)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
@end
