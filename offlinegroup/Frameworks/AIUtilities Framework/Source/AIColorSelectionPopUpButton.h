//
//  AIColorSelectionPopUpButton.h
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <AIUtilities/AIObjectSelectionPopUpButton.h>

/*!
 * @class AIColorSelectionPopUpButton
 * @brief PopUpButton for selecting colors
 *
 * AIColorSelectionPopUpButton is an NSPopUpButton that displays preset color choices
 */
@interface AIColorSelectionPopUpButton : AIObjectSelectionPopUpButton {

}

/*!
 * @brief Set the available pre-set color choices
 *
 * Set the available pre-set color choices.  <b>inColors</b> should be alternating labels and colors (NSString, NSColor, NSString, NSColor, NSString, ...)
 * @param inColors An <tt>NSArray</tt> of color choics as described above
 */
- (void)setAvailableColors:(NSArray *)inColors;

/*!
 * @brief Set the selected color
 *
 * Set the selected color
 * @param inColor An <tt>NSColor</tt> of the new selected color
 */
- (void)setColor:(NSColor *)inColor;

/*!
 * @brief The currently selected color
 *
 * Returns the currently selected color.
 * @return An <tt>NSColor</tt> of the currently selected color
 */
- (NSColor *)color;

@end
