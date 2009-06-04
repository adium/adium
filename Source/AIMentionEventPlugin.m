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

#import <Adium/AIContentControllerProtocol.h>
#import "AIMentionEventPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIChat.h>
#import <Adium/AIContactAlertsControllerProtocol.h>

#define PREF_KEY_MENTIONS		@"Saved Mentions"

/*!
 * @class AIMentionEventPlugin
 * @brief Simple content filter to generate events when incoming messages mention the user, and tag them with a special display class
 */
@implementation AIMentionEventPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[adium.contentController registerContentFilter:self
											  ofType:AIFilterContent 
										   direction:AIFilterIncoming];

	advancedPreferences = [[AIMentionAdvancedPreferences preferencePaneForPlugin:self] retain];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

#pragma mark -
/*!
 * @brief Filter
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
{
	if(![context isKindOfClass:[AIContentMessage class]])
		return inAttributedString;
	
	AIContentMessage *message = (AIContentMessage *)context;
	AIChat *chat = message.chat;
	
	if(!chat.isGroupChat)
		return inAttributedString;
		
	NSString *messageString = [inAttributedString string];
			
	AIAccount *account = (AIAccount *)message.destination;
	
	// XXX When we fix user lists to contain accounts, fix this too.
	NSArray *myNames = [NSArray arrayWithObjects:
						account.UID, 
						account.displayName, 
						/* can be nil */ [chat aliasForContact:[account contactWithUID:account.UID]],
						nil];
	
	myNames = [myNames arrayByAddingObjectsFromArray:[adium.preferenceController preferenceForKey:PREF_KEY_MENTIONS group:PREF_GROUP_GENERAL]];

	for(NSString *checkString in myNames) {
		NSRange range = [messageString rangeOfString:checkString options:NSCaseInsensitiveSearch];
	
		if(range.location != NSNotFound &&
		   (range.location == 0 || ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[messageString characterAtIndex:range.location-1]]) &&
		   (range.location + range.length >= [messageString length] || ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[messageString characterAtIndex:range.location+range.length]]))
		{
			if(message.trackContent && adium.interfaceController.activeChat != chat) {
				[chat incrementUnviewedMentionCount];
			}
			
			[message addDisplayClass:@"mention"];
			
			break;
		}
	}
	
	return inAttributedString;
}

/*!
 * @brief Filter priority
 */
- (CGFloat)filterPriority
{
	return LOWEST_FILTER_PRIORITY;
}

@end
