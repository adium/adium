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

#import "AIPurpleGTalkJoinChatViewController.h"
#import "CBPurpleAccount.h"
#import <AIUtilities/AIStringAdditions.h>

#define DEFAULT_GTALK_CONFERENCE_SERVER	@"groupchat.google.com"

@implementation AIPurpleGTalkJoinChatViewController

/*!
 * @brief Find the default conference server
 *
 * @result The server specified by KEY_DEFAULT_CONFERENCE_SERVER, or groupchat.google.com, the default GTalk conference server
 */
- (NSString *)defaultConferenceServer
{
	NSString *defaultConferenceServer;
	
	if (!(defaultConferenceServer = [account preferenceForKey:KEY_DEFAULT_CONFERENCE_SERVER group:GROUP_ACCOUNT_STATUS])) {
		defaultConferenceServer = DEFAULT_GTALK_CONFERENCE_SERVER;
	}
	
	return defaultConferenceServer;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	//groupchat.google.com *only* allows conference names of the form private-chat-<UUID>
	if ([[self defaultConferenceServer] isEqualToString:DEFAULT_GTALK_CONFERENCE_SERVER]) {
		NSString *uniqueRandomChatName = [NSString stringWithFormat:@"private-chat-%@", [NSString uuid]];
		
		[textField_roomName setStringValue:uniqueRandomChatName];
		
		[self validateEnteredText];
	}
}

@end
