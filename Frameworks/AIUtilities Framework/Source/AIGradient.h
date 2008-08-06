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

//This documentation comment doesn't show up. I don't know why. --boredzo
/*!	@enum AIDirection
 *	@brief A gradient direction.
 *	Can be left-to-right or bottom-to-top.
 */
enum AIDirection {
	/*!	@brief Left-to-right.
	 *	The far left point in the gradient will be the first color; the far right point will be the second color.
	 */
	AIHorizontal,
	/*!	@brief Bottom-to-top.
	 *	The bottom point in the gradient will be the first color; the top point will be the second color.
	 */
	AIVertical
};

/*!	@class AIGradient
 *	@brief Cocoa wrapper around lower level (CoreGraphics) gradient drawing functions, implementing two-color linear gradients.
 */
@interface AIGradient : NSObject {
	enum AIDirection	 direction;
	NSColor				*color1;
	NSColor				*color2;
}

/*!
 * @brief Create a horizontal or vertical gradient between two colors
 *
 * @param inColor1 The starting NSColor
 * @param inColor2 The ending NSColor
 * @param inDirection The \c AIDirection for the gradient
 * @return An autoreleased \c AIGradient
 */
+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(enum AIDirection)inDirection;

/*!
 * @brief Create a gradient for a selected control
 *
 * Use the system selectedControl color to create a gradient in the specified direction. This gradient is appropriate
 * for a Tiger-style selected highlight.
 *
 * @param inDirection The \c AIDirection for the gradient
 * @return An autoreleased \c AIGradient for a selected control
 */
+ (AIGradient*)selectedControlGradientWithDirection:(enum AIDirection)inDirection;

/*!
 * @brief Set the first (left or bottom) color.
 *
 * @param inColor The first \c NSColor.
 */
- (void)setFirstColor:(NSColor*)inColor;

/*!
 * @brief Return the first (left or bottom) color.
 *
 * @result The first color.
 */
- (NSColor*)firstColor;

/*!
 * @brief Set the second (right or top) color.
 *
 * @param inColor The second \c NSColor.
 */
- (void)setSecondColor:(NSColor*)inColor;

/*!
 * @brief Return the second (right or top) color.
 *
 * @result The second color.
 */
- (NSColor*)secondColor;

/*!
 * @brief Set the direction for the gradient.
 *
 * @param inDirection The \c AIDirection for the gradient.
 */
- (void)setDirection:(enum AIDirection)inDirection;

/*!
 * @brief Return the direction for the gradient.
 *
 * @result The \c AIDirection for the gradient.
 */
- (enum AIDirection)direction;

/*!
 * @brief Draw the gradient in an \c NSRect.
 *
 * @param rect The \c NSRect in which to render the gradient.
 */
- (void)drawInRect:(NSRect)rect;

/*!	@brief Draw the gradient in an \c NSBezierPath.
 *
 *	The gradient will fill the specified path according to the path's winding rule, transformation matrix, and so on.
 *
 *	@param inPath The \c NSBezierPath in which to render to gradient.
 */
- (void)drawInBezierPath:(NSBezierPath *)inPath;

@end
