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

#import "AIPurpleGTalkAccount.h"

@implementation AIPurpleGTalkAccount

- (const char *)purpleAccountName
{
	NSString	 *userNameWithGmailDotCom = nil;

	/*
	 * Purple stores the username in the format username@server/resource.  We need to pass it a username in this format
	 *
	 * Append @gmail.com if no domain is specified.
	 * Valid domains include gmail.com, googlemail.com, and google-hosted domains like e.co.za.
	 */
	if ([UID rangeOfString:@"@"].location == NSNotFound) {
		userNameWithGmailDotCom = [UID stringByAppendingString:@"@gmail.com"];
	} else {
		userNameWithGmailDotCom = UID;
	}

	NSString *completeUserName = [NSString stringWithFormat:@"%@/%@",userNameWithGmailDotCom, [self resourceName]];

	return [completeUserName UTF8String];
}

- (NSString *)serverSuffix
{
	return @"@gmail.com";
}

/*!
 * @brief Allow a file transfer with an object?
 *
 * As of July 28th, 2006, GTalk allows transfers.
 */
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	return YES;
}

- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType shouldAttemptReconnect = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];
	
	if (disconnectionError && *disconnectionError) {
		if (([*disconnectionError rangeOfString:@"401"].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Authentication Failure"].location != NSNotFound) ||
			([*disconnectionError rangeOfString:@"Not Authorized"].location != NSNotFound)) {
			[self setLastDisconnectionError:AILocalizedString(@"Incorrect username or password","Error message displayed when the server reports username or password as being incorrect.")];
			[self serverReportedInvalidPassword];
			shouldAttemptReconnect = AIReconnectImmediately;
		}
	}

	return shouldAttemptReconnect;
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	// force connect server
	purple_account_set_string(account, "connect_server", "talk.google.com");
}

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return NO;
}

@end
