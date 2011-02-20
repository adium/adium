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

#import "AMPurpleTuneTooltip.h"
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIHTMLDecoder.h>
#import "CBPurpleAccount.h"
#import <libpurple/blist.h>

@interface AMPurpleTuneTooltip()
- (AIListContact *)tuneContactForListObject:(AIListObject *)listObject;
@end

@implementation AMPurpleTuneTooltip

- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([self tuneContactForListObject:inObject]) {
		return AILocalizedString(@"Tune","user tune tooltip title");
	}
	
	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	AIListContact *tuneContact = [self tuneContactForListObject:inObject];
	
	if (tuneContact) {
		PurpleAccount *account = [(CBPurpleAccount *)tuneContact.account purpleAccount];
		PurpleBuddy *buddy = (account ? purple_find_buddy(account, [tuneContact.UID UTF8String]) : nil);
		PurplePresence *presence = (buddy ? purple_buddy_get_presence(buddy) : nil);
		PurpleStatus *status = (presence ? purple_presence_get_status(presence, "tune") : nil);
		
		if (!status) return nil;

		PurpleValue *title = purple_status_get_attr_value(status, "tune_title");

		if (!title) return nil;
		
		PurpleValue *artist = purple_status_get_attr_value(status, "tune_artist");
		PurpleValue *album = purple_status_get_attr_value(status, "tune_album");
		PurpleValue *duration = purple_status_get_attr_value(status, "tune_time");
		
		const char *titlestr = purple_value_get_string(title);
		const char *artiststr = NULL;
		const char *albumstr = NULL;
		NSInteger timeval = -1;
		if (!titlestr)
			return nil;
		if (artist)
			artiststr = purple_value_get_string(artist);
		if (album)
			albumstr = purple_value_get_string(album);
		if (duration)
			timeval = purple_value_get_int(duration);
		
		NSMutableString *text = [NSMutableString string];
		
		[text appendString:[NSString stringWithUTF8String:titlestr]];
		
		if (artiststr && artiststr[0] != '\0')
			[text appendFormat:@" - %@", [NSString stringWithUTF8String:artiststr]];
		
		if (albumstr && albumstr[0] != '\0')
			[text appendFormat:@" (%@)", [NSString stringWithUTF8String:albumstr]];
		
		if (timeval > 0)
			[text appendFormat:@" - [%d:%02d]", timeval / 60, timeval % 60];
		
		return [AIHTMLDecoder decodeHTML:text];
	}

	return nil;
}

- (BOOL)shouldDisplayInContactInspector
{
	return YES;
}

- (AIListContact *)tuneContactForListObject:(AIListObject *)listObject
{
	NSMutableArray *contacts = [NSMutableArray array];
	
	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *contact in (AIMetaContact *)listObject) {
			if ([contact.account isKindOfClass:[CBPurpleAccount class]]) {
				[contacts addObject:contact];
			}
		}
	} else if ([listObject isKindOfClass:[AIListContact class]] &&
			   [((AIListContact *)listObject).account isKindOfClass:[CBPurpleAccount class]]) {
		[contacts addObject:listObject];
	}
	
	for (AIListContact *contact in contacts) {
		PurpleAccount *account = [(CBPurpleAccount *)contact.account purpleAccount];
		PurpleBuddy *buddy = (account ? purple_find_buddy(account, [contact.UID UTF8String]) : nil);
		PurplePresence *presence = (buddy ? purple_buddy_get_presence(buddy) : nil);
		PurpleStatus *status = (presence ? purple_presence_get_status(presence, "tune") : nil);
		PurpleValue *value = (status ? purple_status_get_attr_value(status, "tune_title") : nil);
		
		if (value && purple_value_get_type(value) == PURPLE_TYPE_STRING && purple_value_get_string(value)) {
			return contact;
		}
	}
	
	return nil;
}

@end
