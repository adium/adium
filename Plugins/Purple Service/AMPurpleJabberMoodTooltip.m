//
//  AMPurpleJabberMoodTooltip.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-12.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AMPurpleJabberMoodTooltip.h"
#import "ESPurpleJabberAccount.h"
#import <Adium/AIListContact.h>
#import <libpurple/blist.h>

@implementation AMPurpleJabberMoodTooltip

- (NSString *)labelForObject:(AIListObject *)inObject {
	if ([inObject isKindOfClass:[AIListContact class]] &&
		[[(AIListContact *)inObject account] isKindOfClass:[ESPurpleJabberAccount class]]) {
		PurpleAccount *account = [(ESPurpleJabberAccount *)[(AIListContact *)inObject account] purpleAccount];
		PurpleBuddy *buddy = (account ? purple_find_buddy(account, [inObject.UID UTF8String]) : nil);
		PurplePresence *presence = (buddy ? purple_buddy_get_presence(buddy) : nil);
		PurpleStatus *status = (presence ? purple_presence_get_active_status(presence) : nil);
		PurpleValue *value = (status ? purple_status_get_attr_value(status, "mood") : nil);
		
		if(value && (purple_value_get_type(value) == PURPLE_TYPE_STRING) && purple_value_get_string(value))
			return AILocalizedString(@"Mood","user mood tooltip title");
	}

	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject {
	if ([inObject isKindOfClass:[AIListContact class]] &&
		[[(AIListContact *)inObject account] isKindOfClass:[ESPurpleJabberAccount class]]) {
		PurpleAccount *account = [(ESPurpleJabberAccount *)[(AIListContact *)inObject account] purpleAccount];
		PurpleBuddy *buddy = (account ? purple_find_buddy(account, [inObject.UID UTF8String]) : nil);
		PurplePresence *presence = (buddy ? purple_buddy_get_presence(buddy) : nil);
		PurpleStatus *status = (presence ? purple_presence_get_active_status(presence) : nil);
		PurpleValue *value = (status ? purple_status_get_attr_value(status, "mood") : nil);
		
		if(value && (purple_value_get_type(value) == PURPLE_TYPE_STRING)) {
			const char *mood = purple_value_get_string(value);
			if(mood) {
				NSString *str;
							
				value = purple_status_get_attr_value(status, "moodtext");
				if(value && purple_value_get_type(value) == PURPLE_TYPE_STRING && purple_value_get_string(value) && purple_value_get_string(value)[0] != '\0')
					str = [NSString stringWithFormat:@"%s (%s)", mood, purple_value_get_string(value)];
				else
					str = [NSString stringWithUTF8String:mood];
				
				return [[[NSAttributedString alloc] initWithString:str attributes:nil] autorelease];
			}
		}
	}

	return nil;
}

- (BOOL)shouldDisplayInContactInspector
{
	return YES;
}

@end
