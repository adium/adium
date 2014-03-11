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

#import "AdiumChatEvents.h"
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListGroup.h>

@implementation AdiumChatEvents

/*!
 * @brief Our parent controller loaded
 *
 * Register the events we generate with the contactAlertsController.
 * Assumption: The contactAlertController already loaded
 */
- (void)controllerDidLoad
{
	//Register the events we generate
	[adium.contactAlertsController registerEventID:CONTENT_CONTACT_JOINED_CHAT
										 withHandler:self 
											 inGroup:AIMessageEventHandlerGroup
										  globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTENT_CONTACT_LEFT_CHAT
										 withHandler:self 
											 inGroup:AIMessageEventHandlerGroup
										  globalOnly:NO];	
	[adium.contactAlertsController registerEventID:CONTENT_GROUP_CHAT_INVITE
										 withHandler:self 
											 inGroup:AIMessageEventHandlerGroup
										  globalOnly:NO];	
}

/*!
 * @brief A group chat added a contact
 */
- (void)chat:(AIChat *)chat addedListContact:(AIListContact *)inContact
{
	[adium.contactAlertsController generateEvent:CONTENT_CONTACT_JOINED_CHAT
									 forListObject:inContact
										  userInfo:[NSDictionary dictionaryWithObject:chat
																			   forKey:@"AIChat"]
					  previouslyPerformedActionIDs:nil];
}

/*!
 * @brief A group chat removed a contact
 */
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact
{
	[adium.contactAlertsController generateEvent:CONTENT_CONTACT_LEFT_CHAT
									 forListObject:inContact
										  userInfo:[NSDictionary dictionaryWithObject:chat
																			   forKey:@"AIChat"]
					  previouslyPerformedActionIDs:nil];
}

#pragma mark Event descriptions
- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
		description = AILocalizedString(@"Joins a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
		description = AILocalizedString(@"Leaves a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
		description = AILocalizedString(@"Invites you to a group chat",nil);
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
		description = AILocalizedString(@"Contact joins a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
		description = AILocalizedString(@"Contact leaves a group chat",nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
		description = AILocalizedString(@"Contact invites you to a group chat",nil);
	} else {
		description = @"";
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
		description = @"Contact Joins";
	} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
		description = @"Contact Leaves";
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
		description = @"Contact Invites You to Chat";
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if (listObject) {
		NSString	*name;
		NSString	*format;
		
		if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
			format = AILocalizedString(@"When %@ joins a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			format = AILocalizedString(@"When %@ leaves a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
			format = AILocalizedString(@"When %@ invites you to a group chat",nil);
		} else {
			format = nil;
		}
		
		if (format) {
			name = ([listObject isKindOfClass:[AIListGroup class]] ?
					[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),listObject.displayName] :
					listObject.displayName);
			
			description = [NSString stringWithFormat:format, name];
		}
		
	} else {
		if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
			description = AILocalizedString(@"When a contact joins a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			description = AILocalizedString(@"When a contact leaves a group chat",nil);
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
			description = AILocalizedString(@"When a contact invites you to a group chat",nil);
		}
	}
	
	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	AIChat			*chat;
	
	NSParameterAssert([userInfo isKindOfClass:[NSDictionary class]]);
	
	chat = [(NSDictionary *)userInfo objectForKey:@"AIChat"];
	
	if (includeSubject) {		
		if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
			description = [NSString stringWithFormat:
				AILocalizedString(@"%@ joined %@","Contact joined Chat Name"),
				listObject.displayName,
				chat.displayName];
			
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			description = [NSString stringWithFormat:
				AILocalizedString(@"%@ left %@","Contact left Chat Name"),
				listObject.displayName,
				chat.displayName];
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			description = [NSString stringWithFormat:
						   AILocalizedString(@"%@ left %@","Contact left Chat Name"),
						   listObject.displayName,
						   chat.displayName];
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			description = [NSString stringWithFormat:
						   AILocalizedString(@"%@ invites you to a group chat","Contact invites you to a group chat"),
						   listObject.displayName];
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
			description = [NSString stringWithFormat:
						   AILocalizedString(@"%@ mentioned you in %@","Someone mentions your name in a group chat"),
						   listObject.displayName,
						   chat.displayName];
		}
		
	} else {
		if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
			description = [NSString stringWithFormat:
				AILocalizedString(@"joined %@","Contact joined Chat Name"),
				chat.displayName];
			
		} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
			description = [NSString stringWithFormat:
				AILocalizedString(@"left %@","Contact left Chat Name"),
				chat.displayName];
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
			description = AILocalizedString(@"invites you to a group chat","Contact invites you to a group chat");
		} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_MENTION]) {
			description = [NSString stringWithFormat:
						   AILocalizedString(@"you were mentioned in %@","Someone mentions your name in a group chat"),
						   chat.displayName];
		}
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [NSImage imageNamed:@"events-message" forClass:[self class]];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	NSString *format = nil;
	
	if ([eventID isEqualToString:CONTENT_CONTACT_JOINED_CHAT]) {
		format = AILocalizedString(@"%u contacts joined", nil);
	} else if ([eventID isEqualToString:CONTENT_CONTACT_LEFT_CHAT]) {
		format = AILocalizedString(@"%u contacts left", nil);
	} else if ([eventID isEqualToString:CONTENT_GROUP_CHAT_INVITE]) {
		format = AILocalizedString(@"%u invites to a group chat", nil);
	}
	
	return format ? [NSString stringWithFormat:format, count] : @"";
}

@end
