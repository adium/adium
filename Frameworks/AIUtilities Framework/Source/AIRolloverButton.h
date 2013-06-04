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

@class AIRolloverButton;

/*!
 * @protocol AIRolloverButtonDelegate
 * @brief Required protocol for the <tt>AIRolloverButton</tt> delegate
 */
@protocol AIRolloverButtonDelegate

/*!
 * @brief Informs the delegate of the mouse entering/leaving the button's bounds
 * @param button The button whose status changed
 * @param isInside YES if the mouse is now within the button; NO if it is now outside the button
 */ 
- (void)rolloverButton:(AIRolloverButton *)button mouseChangedToInsideButton:(BOOL)isInside;
@end

/*!
 * @class AIRolloverButton
 * @brief An NSButton subclass which informs its delegate when the mouse is within its bounds
 */
@interface AIRolloverButton : NSButton {
	NSObject<AIRolloverButtonDelegate>	*delegate;
	NSTrackingRectTag					trackingTag;	
}

#pragma mark Configuration
/*!
 * @brief Set the delegate
 *
 * Set the delegate.  See <tt>AIRolloverButtonDelegate</tt> protocol discussion for details.
 * @param inDelegate The delegate, which must conform to <tt>AIRolloverButtonDelegate</tt>.
 */ 
- (void)setDelegate:(NSObject<AIRolloverButtonDelegate> *)inDelegate;

/*!
 * @brief Return the delegate
 * @return The delegate
 */ 
- (NSObject<AIRolloverButtonDelegate> *)delegate;
@end
