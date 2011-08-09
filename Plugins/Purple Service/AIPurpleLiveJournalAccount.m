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

#import "AIPurpleLiveJournalAccount.h"

@implementation AIPurpleLiveJournalAccount

- (const char *)purpleAccountName
{
	NSString	 *userNameWithLiveJournalDotCom = nil;

	/*
	 * Purple stores the username in the format username@server/resource.  We need to pass it a username in this format
	 *
	 * Append @livejournal.com if no domain is specified.
	 */
	if ([UID rangeOfString:@"@"].location == NSNotFound) {
		userNameWithLiveJournalDotCom = [UID stringByAppendingString:@"@livejournal.com"];
	} else {
		userNameWithLiveJournalDotCom = UID;
	}

	NSString *completeUserName = [NSString stringWithFormat:@"%@/%@", userNameWithLiveJournalDotCom, [self resourceName]];

	return [completeUserName UTF8String];
}

- (NSString *)serverSuffix
{
	return @"@livejournal.com";
}

/*!
 * @brief Allow a file transfer with an object?
 *
 */
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	return NO;
}

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return NO;
}

@end
