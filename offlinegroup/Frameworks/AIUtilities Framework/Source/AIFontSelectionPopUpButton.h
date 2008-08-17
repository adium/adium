//
//  AIFontSelectionPopUpButton.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 6/17/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import <AIUtilities/AIObjectSelectionPopUpButton.h>

/*!
 * @class AIFontSelectionPopUpButton
 * @brief PopUpButton for selecting fonts
 *
 * AIFontSelectionPopUpButton is an NSPopUpButton that displays preset font choices
 */
@interface AIFontSelectionPopUpButton : AIObjectSelectionPopUpButton {

}

/*!
 * @brief Set the available pre-set font choices
 *
 * Set the available pre-set font choices.  <b>inFonts</b> should be alternating labels and fonts (NSString, NSFont, NSString, NSFont, NSString, ...)
 * @param inFonts An <tt>NSArray</tt> of font choics as described above
 */
- (void)setAvailableFonts:(NSArray *)inFonts;

/*!
 * @brief Set the currently displayed font
 * 
 * If a preset exists for the font, it will be selected.  Otherwise, the custom option will be changed to this font
 * and selected
 * @param inFont NSFont to make active
 */
- (void)setFont:(NSFont *)inFont;

/*!
 * @brief The currently selected font
 *
 * Returns the currently selected font.
 * @return An <tt>NSFont</tt> of the currently selected font
 */
- (NSFont *)font;

@end
