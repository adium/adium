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

#import "AIMessageViewController.h"
#import "AIMessageTabViewItem.h"
#import "AITwitterAccount.h"

#import "AITwitterURLHandler.h"
#import <AIUtilities/AIURLAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>

@implementation AITwitterURLHandler

/*!
 * @brief Install the plugin
 *
 * This plugin handles links in the format "twitterreply://account@username?status=(sid)" where the account as a provided user is optional.
 */
- (void)installPlugin
{
	[adium.notificationCenter addObserver:self selector:@selector(urlRequest:) name:@"AITwitterReplyLinkClicked" object:nil];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	[adium.notificationCenter removeObserver:self];
}

/*!
 * @brief A reply link was licked
 *
 * Parse the reply link and set up as appropriate.
 */
- (void)urlRequest:(NSNotification *)notification
{
	NSURL *url = [notification object];
	NSString *inUser = [url host];
	NSString *inTweet = [url queryArgumentForKey:@"status"];
	NSString *inAccount = [url user];
	
	AILogWithSignature(@"Twitter Reply requested: %@", url);
	
	AIService	*twitterService = [adium.accountController firstServiceWithServiceID:@"Twitter"];
	NSArray		*accountArray = [adium.accountController accountsCompatibleWithService:twitterService];
	
	AITwitterAccount	*account = nil;
	
	for(AIAccount *tempAccount in accountArray) {
		if (![tempAccount isKindOfClass:[AITwitterAccount class]]) {
			return;
		}
		
		account = (AITwitterAccount *)tempAccount;
		
		if([tempAccount.UID isEqualToString:inAccount]) {
			break;
		}
	}
	
	if(!account) {
		// No twitter accounts exist. Fail.
		return;
	}
	
	AIChat *timelineChat = [adium.chatController existingChatWithName:account.timelineChatName
															onAccount:account];
	
	if (!timelineChat) {
		// Timeline chat isn't already open. Open it.
		timelineChat = [adium.chatController chatWithName:account.timelineChatName
											   identifier:nil
												onAccount:account
										 chatCreationInfo:nil];
	}
	
	if (!timelineChat.isOpen) {
		[adium.interfaceController openChat:timelineChat];
	}
	
	[adium.interfaceController setActiveChat:timelineChat];
	
	AIMessageTabViewItem *tabViewItem = [timelineChat valueForProperty:@"MessageTabViewItem"];
	
	AIMessageViewController *messageViewController = tabViewItem.messageViewController;

	[messageViewController clearTextEntryView];
	[messageViewController addToTextEntryView:[NSAttributedString stringWithString:[NSString stringWithFormat:@"@%@ ", inUser]]];
	
	[timelineChat setValue:inTweet forProperty:@"TweetInReplyToStatusID" notify:NotifyNow];
	[timelineChat setValue:inUser forProperty:@"TweetInReplyToUserID" notify:NotifyNow];
	[timelineChat setValue:@"@" forProperty:@"Character Counter Prefix" notify:NotifyNow];
	
	AILogWithSignature(@"Flagging chat %@ to in_reply_to_status_id = %@", timelineChat, inTweet);
	
	AIMessageEntryTextView *textView = [messageViewController textEntryView];
	
	//NSTextDidChangeNotification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextDidChangeNotification object:textView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textView];
}

- (void)textDidChange:(NSNotification *)notification
{
	AIMessageEntryTextView *textView = [notification object];

	AIChat *chat = textView.chat;
	AIAccount *account = chat.account;
	
	if(![chat valueForProperty:@"TweetInReplyToStatusID"] || ![chat valueForProperty:@"TweetInReplyToUserID"]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextDidChangeNotification object:textView];
		return;
	}
	
	BOOL keepTweetValues = YES;
	NSString *contents = [textView string];
	
	if([contents length] && [contents characterAtIndex:0] == '@') {
		NSString *replyUsername = [contents substringFromIndex:1];
		NSRange usernameRange = [replyUsername rangeOfCharacterFromSet:[account.service.allowedCharacters invertedSet]];
		
		if(usernameRange.location == NSNotFound) {
			usernameRange = NSMakeRange([replyUsername length], 0);
		}
		
		replyUsername = [replyUsername substringToIndex:usernameRange.location];
		
		if (![replyUsername isEqualToString:[chat valueForProperty:@"TweetInReplyToUserID"]]) {
			keepTweetValues = NO;
		}
	} else {
		keepTweetValues = NO;
	}
	
	if (!keepTweetValues) {
		AILogWithSignature(@"Removing in_reply_to_status_id from chat %@", chat);
		
		[chat setValue:nil forProperty:@"TweetInReplyToStatusID" notify:NotifyNow];
		[chat setValue:nil forProperty:@"TweetInReplyToUserID" notify:NotifyNow];
		[chat setValue:nil forProperty:@"Character Counter Prefix" notify:NotifyNow];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextDidChangeNotification object:textView];
	}
}

@end
