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

#import "AdiumPreferredAccounts.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIService.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

#define PREF_GROUP_PREFERRED_ACCOUNTS   @"Preferred Accounts"
#define KEY_PREFERRED_SOURCE_ACCOUNT	@"Preferred Account"

@interface AdiumPreferredAccounts ()
- (void)didSendContent:(NSNotification *)notification;
@end

@implementation AdiumPreferredAccounts

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		//Observe content (for accountForSendingContentToContact)
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(didSendContent:)
										   name:CONTENT_MESSAGE_SENT
										 object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didSendContent:)
													 name:CONTENT_MESSAGE_SENT_GROUP
												   object:nil];
	}
	
	return self;
}

/*!
 * @brief Close
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AIAccount *)fallbackAccountForSendingToContact:(AIListContact *)inContact strictChecking:(BOOL)strictChecking
{
	//First available account in our list of the correct service type
	for (AIAccount *account in adium.accountController.accounts ) {
		if (inContact.service == account.service &&
			(account.online || (account.enabled && !strictChecking))) {
			return account;
		}
	}
	
	//First available account in our list of a compatible service type
	for (AIAccount *account in adium.accountController.accounts ) {
		if ([inContact.service.serviceClass isEqualToString:account.service.serviceClass] &&
			(account.online || (account.enabled && !strictChecking))) {
			return account;
		}
	}

	//Can't find anything
	return nil;
}

- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact strictChecking:(BOOL)strictChecking
{	
	AIAccount		*account;

	NSParameterAssert(inContact != nil);

	//If we've messaged this object previously, and the account we used to message it is online, return that account
	NSString *accountID = [inContact preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT group:PREF_GROUP_PREFERRED_ACCOUNTS];
	
	//Check the metacontact as well. 
	if (!accountID)
		accountID = [inContact.parentContact preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT group:PREF_GROUP_PREFERRED_ACCOUNTS];
	
	if (accountID) {
		if (![accountID isKindOfClass:[NSString class]]) {
			//Old code stored this as an NSNumber; upgrade.
			accountID = ([accountID isKindOfClass:[NSNumber class]] ?
						 [NSString stringWithFormat:@"%ld",[(NSNumber *)accountID integerValue]] :
						 nil);
			
			[inContact setPreference:accountID
							  forKey:KEY_PREFERRED_SOURCE_ACCOUNT
							   group:PREF_GROUP_PREFERRED_ACCOUNTS];
		}
		
		
		if ((account = [adium.accountController accountWithInternalObjectID:accountID])) {
			if ([account.service.serviceClass isEqualToString:inContact.service.serviceClass] &&
				([account availableForSendingContentType:inType toContact:inContact] || !strictChecking)) {
				return account;
			}
		}
	}
	
	//Check all compatible accounts, looking for one that has the contact on its list
	for (account in [adium.accountController accountsCompatibleWithService:inContact.service]) {
		AIListContact *possibleContact = [adium.contactController existingContactWithService:account.service
										  account:account
										  UID:inContact.UID];
		if ((possibleContact && !possibleContact.isStranger) &&
			([account availableForSendingContentType:inType toContact:possibleContact] || !strictChecking)) {
			//If a contact with this account already exists and isn't a stranger, we've found a good possible choice.
			return account;
		}
	}	

	/* Now, just look for any account which could send to this contact.
	 * We no longer care if the contact is not a stranger, as we exchausted all those possibilities.
	 */
	for (account in [adium.accountController accountsCompatibleWithService:inContact.service]) {
		if ([account availableForSendingContentType:inType toContact:inContact] || !strictChecking) {
			return account;
		}
	}	
	
	return nil;
}

- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact 
{
	AIAccount *account;
	
	account = [self preferredAccountForSendingContentType:inType toContact:inContact strictChecking:YES];
	if (!account) {
		AILogWithSignature(@"Could not find an online choice to talk to %@; will include offline accounts", inContact);
		account = [self preferredAccountForSendingContentType:inType toContact:inContact strictChecking:NO];
	
		if (!account) {
			AILogWithSignature(@"Could not find a good choice to talk to %@; will return first available account", inContact);
			account = [self fallbackAccountForSendingToContact:inContact strictChecking:YES];
		
			if (!account) {
				account = [self fallbackAccountForSendingToContact:inContact strictChecking:NO];
			}
		}
	}

	return account;
}

- (void)didSendContent:(NSNotification *)notification
{
	NSDictionary	*userInfo = [notification userInfo];
    AIChat			*chat = [userInfo objectForKey:@"AIChat"];
    AIListContact	*destObject = chat.listObject;
    
    if (chat && destObject) {
        AIContentObject *contentObject = [userInfo objectForKey:@"AIContentObject"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
        
		if (![[destObject preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
									 group:PREF_GROUP_PREFERRED_ACCOUNTS] isEqualToString:sourceAccount.internalObjectID]) {
			[destObject setPreference:sourceAccount.internalObjectID
							   forKey:KEY_PREFERRED_SOURCE_ACCOUNT
								group:PREF_GROUP_PREFERRED_ACCOUNTS];
        }
    }
}

@end
