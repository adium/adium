//
//  AIFacebookXMPPAccount.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPAccount.h"
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import "adiumPurpleCore.h"
#import <libpurple/jabber.h>
#import "ESPurpleJabberAccount.h"
#import "auth_fb.h"
#import "auth.h"

@implementation AIFacebookXMPPAccount

#pragma mark Connectivitiy

- (const char*)protocolPlugin
{
	return "prpl-jabber";
}

- (NSString *)serverSuffix
{
	return @"@chat.facebook.com";
}

/* Specify a host for network-reachability-code purposes */
- (NSString *)host
{
	return @"chat.facebook.com";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username(account, self.purpleAccountName);
	purple_account_set_string(account, "connection_security", "");
    purple_account_set_string(account, "fb_api_key", "819fd0b010d15eac1b36648f0126ece3");
    purple_account_set_string(account, "fb_api_secret", [[self preferenceForKey:@"FBSessionSecret" group:GROUP_ACCOUNT_STATUS] UTF8String]);
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self serverSuffix]];
	}
	
	completeUserName = [NSString stringWithFormat:@"-%@/Adium" ,userNameWithHost];
	
	return [completeUserName UTF8String];
}

- (BOOL)encrypted
{
	return NO;
}

#pragma mark Status

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							  arguments:(NSMutableDictionary *)arguments
{
	const char		*statusID = NULL;
	NSString		*statusName = statusState.statusName;
	NSString		*statusMessageString = [statusState statusMessageString];
	NSNumber		*priority = nil;
	
	if (!statusMessageString) statusMessageString = @"";
	
	switch (statusState.statusType) {
		case AIAvailableStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]] == NSOrderedSame) ||
				[statusName isEqualToString:STATUS_NAME_BUSY]) {
				//Note that Jabber doesn't actually support a 'busy' status; if we have it set because some other service supports it, treat it as DND
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND);
				
			} else if (([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY]) ||
					   ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIInvisibleStatusType:
			AILog(@"Warning: Invisibility is not yet supported in libpurple 2.0.0 jabber");
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_AWAY);
			break;
			
		case AIOfflineStatusType:
			break;
	}
	
	//Set our priority, which is actually set along with the status...Default is 0.
	[arguments setObject:(priority ? priority : [NSNumber numberWithInt:0])
				  forKey:@"priority"];
	
	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Account configuration

- (void)setName:(NSString *)name UID:(NSString *)inUID
{
	[self filterAndSetUID:inUID];
	
	[self setFormattedUID:name notify:NotifyNever];
}

#pragma mark Contacts

/*!
 * @brief Set an alias for a contact
 *
 * Normally, we consider the name a 'serverside alias' unless it matches the UID's characters
 * However, the UID in facebook should never be presented to the user if possible; it's for internal use
 * only.  We'll therefore consider any alias a formatted UID such that it will replace the UID when displayed
 * in Adium.
 */
- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![purpleAlias isEqualToString:theContact.formattedUID] && 
		![purpleAlias isEqualToString:theContact.UID]) {
		[theContact setFormattedUID:purpleAlias
							 notify:NotifyLater];
		
		//Apply any changes
		[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
	}
}

- (NSMutableArray *)arrayOfDictionariesFromPurpleNotifyUserInfo:(PurpleNotifyUserInfo *)user_info forContact:(AIListContact *)contact
{
	NSMutableArray *array = [super arrayOfDictionariesFromPurpleNotifyUserInfo:user_info forContact:contact];
	
	NSString *displayUID = contact.UID;
	displayUID = [displayUID stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
	if ([displayUID hasSuffix:@"@chat.facebook.com"])
		displayUID = [displayUID substringToIndex:displayUID.length - @"@chat.facebook.com".length];

	[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					  AILocalizedString(@"Facebook ID", nil), KEY_KEY,
					  displayUID, KEY_VALUE,
					  nil]];

	return array;
}

@end
