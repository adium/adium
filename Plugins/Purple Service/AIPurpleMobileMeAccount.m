//
//  AIPurpleMobileMeAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 7/16/08.
//  Copyright 2008 Adium X. All rights reserved.
//

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
