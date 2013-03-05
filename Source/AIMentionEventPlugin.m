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
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIGroupChat.h>
#import "AIContentTopic.h"


/*!
 * @class AIMentionEventPlugin
 * @brief Simple content filter to generate events when incoming messages mention the user, and tag them with a special display class
 */
@implementation AIMentionEventPlugin

@synthesize mentionPredicates;

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[adium.contentController registerContentFilter:self
											  ofType:AIFilterContent 
										   direction:AIFilterIncoming];
	
	[adium.preferenceController registerPreferenceObserver:self 
												  forGroup:PREF_GROUP_GENERAL];

	advancedPreferences = (AIMentionAdvancedPreferences *)[AIMentionAdvancedPreferences preferencePaneForPlugin:self];
}

- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

#pragma mark -
/*!
 * @brief Filter
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
{
	if(![context isKindOfClass:[AIContentMessage class]] || [context isKindOfClass:[AIContentTopic class]])
		return inAttributedString;
	
	AIContentMessage *message = (AIContentMessage *)context;
	AIChat *chat = message.chat;
	
	if(!chat.isGroupChat || message.isOutgoing)
		return inAttributedString;
		
	NSString *messageString = [inAttributedString string];
			
	AIAccount *account = (AIAccount *)message.destination;
	NSString *contactAlias = [(AIGroupChat *)chat aliasForContact:[account contactWithUID:account.UID]];
	
	// XXX When we fix user lists to contain accounts, fix this too.
	NSArray *myPredicates = [NSArray arrayWithObjects:
							 [NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", [NSString stringWithFormat:@".*\\b%@\\b.*", [account.UID stringByEscapingForRegexp]]], 
							 [NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", [NSString stringWithFormat:@".*\\b%@\\b.*", [account.displayName stringByEscapingForRegexp]]], 
							 /* can be nil */ contactAlias? [NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", [NSString stringWithFormat:@".*\\b%@\\b.*", [contactAlias stringByEscapingForRegexp]]] : nil,
							 nil];
	
	myPredicates = [myPredicates arrayByAddingObjectsFromArray:self.mentionPredicates];
	
	for(NSPredicate *predicate in myPredicates) {
		if([predicate evaluateWithObject:messageString]) {
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

/*!
 * @brief Rebuild predicates on preference saves.
 */
#pragma mark Preference Observing
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(firstTime || [key isEqualToString:PREF_KEY_MENTIONS]) {
		NSArray *allMentions = [adium.preferenceController preferenceForKey:PREF_KEY_MENTIONS group:PREF_GROUP_GENERAL];
		NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:[allMentions count]];
		NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES '/.*/'"];
		
		for (NSString *mention in allMentions) {
			if([regexPredicate evaluateWithObject:mention]) {
				[predicates addObject:[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", [NSString stringWithFormat:@".*%@.*", [mention substringWithRange:NSMakeRange(1, [mention length]-2)]]]];
			} else {
				[predicates addObject:[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", [NSString stringWithFormat:@".*\\b%@\\b.*", [mention stringByEscapingForRegexp]]]];
			}
		}
		self.mentionPredicates = predicates;
	}
}

@end
