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
 * @class AIStringFormatter
 * @brief Formatter which restricts characters and length.
 *
 * <tt>NSFormatter</tt> subclass which formats to a specified <tt>NSCharacterSet</tt> and length.  An errorMessage may be set which will be displayed after the user makes 3 invalid input attempts.
 */
@interface AIStringFormatter : NSFormatter {
    NSCharacterSet	*characters;
    int				length;
    BOOL			caseSensitive;

    NSString		*errorMessage;
    int				errorCount;
}

/*!
 * @brief Create an <tt>AIStringFormatter</tt>
 *
 * Create an autoreleased <tt>AIStringFormatter</tt>
 * @param inCharacters An <tt>NSCharacterSet</tt> of all allowed characters
 * @param inLength The maximum allowed length of the formatted string
 * @param inCaseSensitive YES if the characters should be tested with respect for case
 * @param errorMessage A message to be displayed to the user after 3 invalid input attempts. If nil, no error message is displayed.
 * @return An <tt>AIStringFormatter</tt> object
 */
+ (id)stringFormatterAllowingCharacters:(NSCharacterSet *)inCharacters length:(int)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)errorMessage;

@end
