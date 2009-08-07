//
//  AIPurpleGTalkJoinChatViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/3/08.
//

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
