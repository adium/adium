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

#import <AppKit/NSCell.h>

/*!
 * @class AIImageTextCell
 * @brief A cell which displays an image and one or two lines of text
 *
 * This NSCell subclass displays in image on the left and one or two lines of text centered vertically in the space remaining for the cell
 */
@interface AIImageTextCell : NSCell {
	NSFont			*font;
    NSString		*subString;
	float			maxImageWidth;
	float			imageTextPadding;
	NSLineBreakMode lineBreakMode;
	BOOL	imageAfterMainString;
	BOOL	highlightWhenNotKey;
}

/*
 * @brief Set a string to be drawn underneath the stringValue of the cell
 *
 * If non-nil, this string will be drawn underneath the stringValue of the cell.  The two will, together, be vertically centered (when not present, the stringValue alone is vertically centered). It is drawn in with the system font, at size 10.
 */
- (void)setSubString:(NSString *)inSubString;

/*
 * @brief Set the maximum width of the image drawn on the left
 *
 * Set the maximum width of the image drawn on the left.  The default value is 24.
 */
- (void)setMaxImageWidth:(float)inMaxImageWidth;

/*
 * @brief Set the padding between text and image
 *
 * Half this distance will be the padding between the left cell edge and the image or the text.
 * Half this distance will be the padding from the right edge of the image or text and the right cell edge.
 */
- (void)setImageTextPadding:(float)inImageTextPadding;

/*!	@brief	Ask whether the image goes before both strings, or after the main string.
 *
 *	@par	If \c YES, the image is drawn after with main string, with \c imageTextPadding points between them. If \c NO, the image is drawn before both strings (if there is a \c subString, the image won't be placed on the baseline of the main string).
 *
 *	@return	\c YES if the image will be drawn after the main string; \c NO if the image will be drawn before both strings.
 */
- (BOOL) drawsImageAfterMainString;
/*!	@brief	Set whether the image goes before both strings, or after the main string.
 *
 *	@par	If \c YES, the image is drawn after with main string, with \c imageTextPadding points between them. If \c NO, the image is drawn before both strings (if there is a \c subString, the image won't be placed on the baseline of the main string).
 *
 *	@param	flag	\c YES if you want the image to be drawn after the main string; \c NO if you want the image to be drawn before both strings.
 */
- (void) setDrawsImageAfterMainString:(BOOL)flag;

/*! @brief Set whether the strings are considered highlighted even if the window is not key
 *
 * @par		If \c YES, the text is drawn as highlighted even when not the key wndow. If \c NO, it is drawn normally.
 */
- (void) setHighlightWhenNotKey:(BOOL)flag;

- (void)setLineBreakMode:(NSLineBreakMode)inLineBreakMode;

@end
