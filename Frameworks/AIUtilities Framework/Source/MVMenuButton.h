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
//Adapted from Colloquy  (www.colloquy.info)

/*!
 * @class MVMenuButton
 * @brief Button with a popup menu for use with an NSToolbarItem
 *
 * Button which has a popup menu, including a menu arrow in the bottom right corner, for use as the custom view of an NSToolbarItem
 */
@interface MVMenuButton : NSButton <NSCopying> {
	NSImage				*bigImage;
	NSToolbarItem 		*__weak toolbarItem;
	NSBezierPath 		*arrowPath;
	
	BOOL				drawsArrow;
	NSControlSize 		controlSize;
}

@property (nonatomic, weak) NSToolbarItem *toolbarItem;
@property (nonatomic, assign) NSControlSize controlSize;
@property (nonatomic, assign) BOOL drawsArrow;

/*!
 * @brief Set the image of the button
 *
 * It will be automatically sized as necessary.
 * @param inImage An <tt>NSImage</tt> to use.
*/ 
- (void)setImage:(NSImage *)inImage;
/*!
 * @brief Returns the image of the button
 * @return An <tt>NSImage</tt>.
*/ 
- (NSImage *)image;

@end
