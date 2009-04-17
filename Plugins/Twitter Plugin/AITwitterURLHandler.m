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
#import "AIURLHandlerPlugin.h"
#import <AIUtilities/AIURLAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlRequest:) name:AIURLHandleNotification object:nil];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief A reply link was licked
 *
 * Parse the reply link and set up as appropriate.
 */
- (void)urlRequest:(NSNotification *)notification
{
	NSString *urlString = notification.object;
	NSURL *url = [NSURL URLWithString:urlString];
	
	if (![url.scheme isEqualToString:@"twitterreply"]) {
		return;
	}
	
	NSString *inUser = [url host];
	NSString *inAction = [url queryArgumentForKey:@"action" withDelimiter:@"&"] ?: @"reply";
	NSString *inTweet = [url queryArgumentForKey:@"status" withDelimiter:@"&"];
	NSString *inDM = [url queryArgumentForKey:@"dm" withDelimiter:@"&"];
	NSString *inMessage = [url queryArgumentForKey:@"message" withDelimiter:@"&"];
	NSString *inAccount = [url user];
	
	AILogWithSignature(@"Twitter Reply requested: %@", url);
	
	NSArray		*accountArray = adium.accountController.accounts;
	
	AITwitterAccount	*account = nil;
	BOOL		exactMatchForInternalID = NO;
	
	// Look for an account with the given internalObjectID
	for(AIAccount *tempAccount in accountArray) {
		if (![tempAccount isKindOfClass:[AITwitterAccount class]]) {
			continue;
		}
		
		account = (AITwitterAccount *)tempAccount;
		
		if([tempAccount.internalObjectID isEqualToString:inAccount]) {
			exactMatchForInternalID = YES;
			break;
		}
	}

	if(!account) {
		// No exact match. Fail.
		return;
	}

	if ([inAction isEqualToString:@"reply"] || [inAction isEqualToString:@"retweet"]) {
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
		
		AIMessageEntryTextView *textView = ((AIMessageTabViewItem *)[timelineChat valueForProperty:@"MessageTabViewItem"]).messageViewController.textEntryView;

		// Insert the @reply text
		NSString *prefix = nil;
		
		if (inMessage) {
			prefix = [NSString stringWithFormat:@"RT @%@ %@", inUser, [inMessage stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		} else {
			prefix = [NSString stringWithFormat:@"@%@ ", inUser];
		}
		
		if (![textView.string hasPrefix:prefix]) {
			NSMutableAttributedString *newString = [[[NSAttributedString stringWithString:prefix] mutableCopy] autorelease];
			[newString appendAttributedString:textView.attributedString];
			[textView setAttributedString:newString];
			
			// Shift the selected range over by the length of our prefix string
			NSRange selectedRange = textView.selectedRange;
			[textView setSelectedRange:NSMakeRange(selectedRange.location + prefix.length, selectedRange.length)];
		}
			
		// Make the text view have focus
		[[adium.interfaceController windowForChat:timelineChat] makeFirstResponder:textView];
		
		if([inAction isEqualToString:@"reply"]) {
			[timelineChat setValue:inTweet forProperty:@"TweetInReplyToStatusID" notify:NotifyNow];
			[timelineChat setValue:inUser forProperty:@"TweetInReplyToUserID" notify:NotifyNow];
			[timelineChat setValue:@"@" forProperty:@"Character Counter Prefix" notify:NotifyNow];
			
			AILogWithSignature(@"Flagging chat %@ to in_reply_to_status_id = %@", timelineChat, inTweet);
			
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextDidChangeNotification object:textView];
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textView];
		}
	} else if ([inAction isEqualToString:@"favorite"]) {
		[account toggleFavoriteTweet:inTweet];
	} else if ([inAction isEqualToString:@"destroy"] && exactMatchForInternalID) {
		if (inTweet && inMessage) {
			// Confirm if the user wants to delete this tweet.
			if (NSRunAlertPanel(AILocalizedString(@"Delete Tweet?", nil),
								AILocalizedString(@"Are you sure you want to delete the tweet:\n\n\"%@\"\n\nThis action cannot be undone.", nil),
								AILocalizedString(@"Delete", nil), AILocalizedString(@"Cancel", nil), nil,
								[inMessage stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) == NSAlertDefaultReturn) {
				[account destroyTweet:inTweet];
			}
		} else if (inDM && inMessage) {
			// Confirm if the user wants to delete this DM.
			if (NSRunAlertPanel(AILocalizedString(@"Delete Direct Message?", nil),
								AILocalizedString(@"Are you sure you want to delete the direct message:\n\n\"%@\"\n\nThis action cannot be undone.", nil),
								AILocalizedString(@"Delete", nil), AILocalizedString(@"Cancel", nil), nil,
								[inMessage stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) == NSAlertDefaultReturn) {
				[account destroyDirectMessage:inDM forUser:inUser];
			}			
		}
	}
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
	
	NSString *contents = [textView string];
	BOOL keepTweetValues = YES;
	
	if([contents hasPrefix:@"@"]) {
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
