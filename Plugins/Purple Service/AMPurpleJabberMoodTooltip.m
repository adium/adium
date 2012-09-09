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
				
				return [[NSAttributedString alloc] initWithString:str attributes:nil];
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
