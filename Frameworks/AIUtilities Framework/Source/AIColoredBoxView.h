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

/*!
 * @class AIColoredBoxView
 * @brief View which draws filled with a particular color
 *
 * View which draws, simply filling its bounds with a particular color.
 */
@interface AIColoredBoxView : NSView {
    NSColor 	*color;
}

/*!
 * @brief The color of the view
 *
 * The <tt>NSColor</tt> to draw in the view
 */ 
@property (readwrite, nonatomic, retain) NSColor *color;

@end
