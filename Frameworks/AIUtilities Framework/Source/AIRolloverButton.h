//
//  AIRolloverButton.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/2/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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
