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

#import "AIPurpleMobileMeAccount.h"


@implementation AIPurpleMobileMeAccount

/*!
 * @brief Account name passed to libpurple
 *
 * Allow @mac.com addresses to be input here, as well. @me.com is the default.
 */
- (const char *)purpleAccountName
{
	NSString	 *userNameWithMacDotComOrMeDotCom;
	
	if (([UID rangeOfString:@"@me.com"	options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound) ||
		([UID rangeOfString:@"@mac.com"	options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)].location != NSNotFound)) {
		userNameWithMacDotComOrMeDotCom = UID;
	} else {
		userNameWithMacDotComOrMeDotCom = [UID stringByAppendingString:@"@me.com"];
	}
	
	return [userNameWithMacDotComOrMeDotCom UTF8String];
}

/*!
 * @brief Set the spacing and capitilization of our formatted UID serverside (from CBPurpleOscarAccount)
 *
 * CBPurpleOscarAccount calls this to perform spacing/capitilization setting serverside.  This is not supported
 * for .Mac accounts and will throw a SNAC error if attempted.  Override the method to perform no action for .Mac.
 */
- (void)setFormattedUID {};

/*!
 * @brief A formatted UID which may include additional necessary identifying information.
 *
 * For example, an AIM account (tekjew) and a .Mac account (tekjew@mac.com, entered only as tekjew) may appear identical
 * without service information (tekjew). The explicit formatted UID is therefore tekjew@mac.com
 */
- (NSString *)explicitFormattedUID
{
	return [NSString stringWithUTF8String:self.purpleAccountName];
}
@end
