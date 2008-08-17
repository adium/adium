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
//
//  AIWiredString.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-16.
//

#import <Cocoa/Cocoa.h>

@class AIWiredData;

/*!	@class AIWiredString AIWiredString.h <AIUtilities/AIWiredString.h>

 *	@brief A concrete, immutable subclass of NSString that uses wired memory for its backing.
 *
 *	@par
 *	When storing passwords, you do not want the password to be paged out to disk, where it could be obtained using data-recovery techniques (e.g. DriveSavers).
 *	Memory that has been "wired" cannot be paged out to disk. Therefore wired memory should be used for short-term storage of passwords.
 *	This class stores textual data in a wired backing, so that it will not be paged to disk.
 *	The AIWiredString instance itself may still be paged out, but this is of no value after the machine has been shut down (e.g. to remove the HDD to search it), because the secret information will no longer be in memory.
 *
 *	@par
 *	You should obtain the characters using <code>-dataUsingEncoding:allowLossyConversion:</code>, <code>-dataUsingEncoding:</code>, or <code>-UTF8String</code>, because these methods return an \c AIWiredData. You can also use <code>-getCharacters:</code> or <code>-getCharacters:range:</code>, but you will need to allocate and wire the memory yourself.
 *
 *	@see AIWiredData
 */

@interface AIWiredString : NSString
{
	unichar *backing;
	size_t length;
}

/*!	@brief Returns wired-in-memory data for the characters of the string.
 *
 *	If \a flag is \c YES, characters may be munged to fit into the encoding (for example, by dropping accent marks).
 *
 *	@return An AIWiredData containing the characters in the requested encoding.
 */
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding allowLossyConversion:(BOOL)flag;
/*!	@brief Returns wired-in-memory data for the characters of the string.
 *
 *	Does not allow lossy conversion.
 *
 *	@return An AIWiredData containing the characters in the requested encoding.
 */
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding;

@end
