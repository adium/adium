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
