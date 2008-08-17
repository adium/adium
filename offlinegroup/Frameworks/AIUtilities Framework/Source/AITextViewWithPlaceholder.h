//
//  AITextViewWithPlaceholder.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

/*!
 * @class AITextViewWithPlaceholder
 * @brief TextView with placeholder support in 10.2 and above
 *
 * <tt>NSTextView</tt> sublcass which supports placeholders, text which is displayed but greyed out when the text view is empty and unselected, even on 10.2; this is a feature which was added in 10.3.
 */

@interface AITextViewWithPlaceholder : NSTextView {
    NSAttributedString *placeholder;
	BOOL				placeholderHasOwnAttributes;
}

/*
 * @brief Set the placeholder string
 *
 * Set the placeholder string, which is text which is displayed but greyed out when the text view is empty and unselected.
 * @param inPlaceholder An <tt>NSString</tt> to display as the placeholder
 */
-(void)setPlaceholderString:(NSString *)inPlaceholder;

- (void)setPlaceholder:(NSAttributedString *)inPlaceholder;

/*
 * @brief Returns the current placeholder string
 *
 * Returns the current placeholder string
 * @return An <tt>NSAttributedString</tt>
 */
-(NSAttributedString *)placeholder;

@end
