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
 * @class AICompletingTextField
 * @brief A text field that auto-completes known strings
 *
 * A text field that auto-completes known strings. It supports a minimum string length before autocompletion as well as optionally completing any number of comma-separated strings.
 */

#import <AIUtilities/AITextFieldWithDraggingDelegate.h>

@interface AICompletingTextField : AITextFieldWithDraggingDelegate {
    NSMutableSet			*stringSet;
	NSMutableDictionary		*impliedCompletionDictionary;
	
    NSUInteger						minLength;
	BOOL					completeAfterSeparator;
    NSUInteger						oldUserLength;
}

/*!
 * @brief Set the minimum string length before autocompletion
 *
 * Set the minimum string length before autocompletion.  The text field will not begin to autocomplete until the user has typed at least the specified number of characters.  Defaults to 1.
 * @param length The new minimum length before autocompletion
 */
- (void)setMinStringLength:(int)length;

/*!
 * @brief Set if the field should expect a comma-delimited series
 *
 * By default, the entire field will be a single autocompleting area; input text is checked in its entirety against specified possible completions.  If <b>split</b> is YES, however, the completions will be split at each comma, allowing a series of distinct comma-delimited autocompletions.
 * @param split YES if the list should be treated as a comma-delimited series of autocompletions; NO if the entire field is a single autocompleting area
 */
- (void)setCompletesOnlyAfterSeparator:(BOOL)split;

/*!
 * @brief Set all completions for the field.
 *
 * Set all possible completions for the field, overriding all previous completion settings. All completions are treated as literal completions. This does not just call addCompletionString: repeatedly; it is more efficient to use if you already have an array of completions.
 * @param strings An <tt>NSArray</tt> of all completion strings
 */
- (void)setCompletingStrings:(NSArray *)strings;

/*!
 * @brief Add a completion for the field.
 *
 * Add a literal completion for the field.
 * @param string The completion to add.
 */
- (void)addCompletionString:(NSString *)string;

/*!
 * @brief Add a completion for the field which displays and returns differently.
 *
 * Add a completion for the field.  <b>string</b> is the string which will complete for the user (so its beginning is what the user must type, and it is what the user will see in the field). <b>impliedCompletion</b> is what will be returned by <tt>impliedStringValue</tt> when <b>completion</b> is in the text field.
 * @param string The visual completion to add.
 * @param impliedCompletion The actual completion for <b>string</b>, which will be returned by impliedValue and -- if it is an NSString -- by impliedStringValue when string is in the text field.
 */
- (void)addCompletionString:(NSString *)string withImpliedCompletion:(id)impliedCompletion;

/*!
 * @brief Return the completed string value of the field
 *
 * Return the string value of the field, taking into account implied completions (see <tt>addCompletionString:withImpliedCompletion:</tt> for information on implied completions).
 * @result	An <tt>NSString</tt> of the appropriate string value
 */
- (NSString *)impliedStringValue;

/*!
 * @brief Return the implied string value the field has set for a passed string
 *
 * Returns the implied string value which the field has as the implied completion for <b>aString</b>. Useful while parsing multiple strings from the field when making using of multiple, comma-delimited items.
 * @param aString The <tt>NSString</tt> to check for an implied completion
 * @result	An <tt>NSString</tt> of the implied string value, or <b>aString</b> if no implied string value is assigned
 */
- (NSString *)impliedStringValueForString:(NSString *)aString;

/*
 * @brief Return the implied value of the field
 *
 * This may be the impliedStringValue or some non-NSString which was set as an implied completion
 */
- (id)impliedValue;
@end
