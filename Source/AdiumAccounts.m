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

#import "AdiumAccounts.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

//Preference keys
#define TOP_ACCOUNT_ID					@"TopAccountID"   	//Highest account object ID
#define ACCOUNT_LIST					@"Accounts"   		//Array of accounts
#define ACCOUNT_TYPE					@"Type"				//Account type
#define ACCOUNT_SERVICE					@"Service"			//Account service
#define ACCOUNT_UID						@"UID"				//Account UID
#define ACCOUNT_OBJECT_ID				@"ObjectID"   		//Account object ID

@interface AdiumAccounts ()
- (void)_loadAccounts;
- (void)_saveAccounts;
- (NSString *)_generateUniqueInternalObjectID;
- (NSString *)_upgradeServiceUniqueID:(NSString *)serviceUniqueID forAccountDict:(NSDictionary *)accountDict;
- (void)upgradeAccounts;
@end

@interface AIAccount (SekretsIKnow)
@property (nonatomic, assign) AIService *service;
@end

/*!
 * @class AdiumAccounts
 * @brief Class to handle AIAccount access and creation
 *
 * This is a private class used by AIAccountController, its public interface.
 */
@implementation AdiumAccounts

- (id)init {
	if ((self = [super init])) {
		accounts = [[NSMutableArray alloc] init];
		unloadableAccounts = [[NSMutableArray alloc] init];	
	}
	
	return self;
}

- (void)dealloc {
    [accounts release];
	[unloadableAccounts release];

	[super dealloc];
}

/*!
 * @brief Finish Initing
 *
 * Requires the all AIServices have registered
 */
- (void)controllerDidLoad
{
	[self _loadAccounts];
	
	[self upgradeAccounts];
}


//Accounts -------------------------------------------------------------------------------------------------------
#pragma mark Accounts
/*!
 * @brief Returns an array of all available accounts
 *
 * @return NSArray of AIAccount instances
 */
- (NSArray *)accounts
{
    return accounts;
}

/*!
 * @brief Returns an array of accounts compatible with a service
 *
 * @param service AIService for compatible accounts
 * @result NSArray of AIAccount instances
 */
- (NSArray *)accountsCompatibleWithService:(AIService *)service
{
	NSMutableArray	*matchingAccounts = [NSMutableArray array];
	AIAccount		*account;
	NSString		*serviceClass = [service serviceClass];
	
	for (account in accounts) {
		if (account.enabled &&
			[[account.service serviceClass] isEqualToString:serviceClass]) {
			[matchingAccounts addObject:account];
		}
	}
	
	return matchingAccounts;	
}

- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID
{
	AIAccount *account = nil;
	//Some ancient preferences have NSNumbers instead of NSStrings. Work properly, silently.
	if ([objectID isKindOfClass:[NSNumber class]]) objectID = [(NSNumber *)objectID stringValue];

	for (account in accounts) {
        if ([objectID isEqualToString:account.internalObjectID]) break;
    }
    
    return account;
}


//Editing --------------------------------------------------------------------------------------------------------------
#pragma mark Editing
/*!
 * @brief Create an account
 *
 * The account is not added to Adium's list of accounts, this must be done separately with addAccount:
 * @param service AIService for the account
 * @param inUID NSString userID for the account
 * @return AIAccount instance that was created
 */
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID
{	
	return [service accountWithUID:inUID internalObjectID:[self _generateUniqueInternalObjectID]];
}

/*!
 * @brief Add an account
 *
 * @param inAccount AIAccount to add
 */
- (void)addAccount:(AIAccount *)inAccount
{
	[accounts addObject:inAccount];
	[self _saveAccounts];
}

/*!
 * @brief Delete an account
 *
 * @param inAccount AIAccount to delete
 */
- (void)deleteAccount:(AIAccount *)inAccount
{
	//Shut down the account in preparation for release
	//XXX - Is this sufficient?  Don't some accounts take a while to disconnect and all? -ai
	[inAccount willBeDeleted];
	[adium.accountController forgetPasswordForAccount:inAccount];

	//Remove from our array
	[accounts removeObject:inAccount];
	[self _saveAccounts];
}

/*!
 * @brief Move an account
 *
 * @param account AIAccount to move
 * @param destIndex Index to place the account
 * @return new index of the account
 */
- (NSUInteger)moveAccount:(AIAccount *)account toIndex:(NSUInteger)destIndex
{
    [accounts moveObject:account toIndex:destIndex];
    [self _saveAccounts];
	return [accounts indexOfObject:account];
}

/*!
 * @brief An account's UID changed
 *
 * Save our account array, which stores the account's UID permanently
 */
- (void)accountDidChangeUID:(AIAccount *)account
{
	[self _saveAccounts];
}

- (void)moveAccount:(AIAccount *)account toService:(AIService *)service
{
	account.service = service;
	[self _saveAccounts];
}

/*!
 * @brief Generate a unique account InternalObjectID
 *
 * @return NSString unique InternalObjectID
 */
//XXX - This setup leaves the possibility that mangled preferences files would create multiple accounts with the same ID -ai
- (NSString *)_generateUniqueInternalObjectID
{
	NSInteger			topAccountID = [[adium.preferenceController preferenceForKey:TOP_ACCOUNT_ID group:PREF_GROUP_ACCOUNTS] integerValue];
	NSString 	*internalObjectID = [NSString stringWithFormat:@"%ld",topAccountID];
	
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:topAccountID + 1]
										 forKey:TOP_ACCOUNT_ID
										  group:PREF_GROUP_ACCOUNTS];

	return internalObjectID;
}


//Storage --------------------------------------------------------------------------------------------------------------
#pragma mark Storage
/*!
 * @brief Load accounts from disk
 */
- (void)_loadAccounts
{
    NSArray		 *accountList = [adium.preferenceController preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	NSDictionary *accountDict;

    //Create an instance of every saved account
	for (accountDict in accountList) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString		*serviceUniqueID = [self _upgradeServiceUniqueID:[accountDict objectForKey:ACCOUNT_TYPE] 
													forAccountDict:accountDict];
        AIAccount		*newAccount;

		//Fetch the account service, UID, and ID
		AIService	*service = [adium.accountController serviceWithUniqueID:serviceUniqueID];
		NSString	*accountUID = [accountDict objectForKey:ACCOUNT_UID];
		NSString	*internalObjectID = [accountDict objectForKey:ACCOUNT_OBJECT_ID];

        //Create the account and add it to our array
        if (service && accountUID && [accountUID length]) {
			if ((newAccount = [service accountWithUID:accountUID internalObjectID:internalObjectID])) {
                [accounts addObject:newAccount];
            } else {
				NSLog(@"Could not load account %@",accountDict);
				[unloadableAccounts addObject:accountDict];
			}
        } else {
			if ([accountUID length]) {
				AILog(@"Available services are %@: could not load account %@ on service %@ (service %@)",
					  adium.accountController.services, accountDict, serviceUniqueID, service);
				[unloadableAccounts addObject:accountDict];
			} else {
				AILog(@"Ignored an account with a 0 length accountUID: %@", accountDict);
			}
		}
		[pool release];
    }

	//Broadcast an account list changed notification
    [[NSNotificationCenter defaultCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

/*!
 * @brief ServiceID upgrade code (v0.63 -> v0.70 for libpurple, v0.70 -> v0.80 for bonjour, v1.0 -> v1.1 for libpurple)
 *
 * The changed name will only be saved if some other account change, such as adding an account, occurs,
 * so this code should remain indefinitely to provide an upgrade path to people whose service IDs are in an
 * old style.
 *
 * @param serviceID NSString service unique ID (old or new)
 * @param accountDict Dictionary of the saved account
 * @return NSString service ID (new), or nil if unable to upgrade
 */
- (NSString *)_upgradeServiceUniqueID:(NSString *)serviceID forAccountDict:(NSDictionary *)accountDict
{
	//Libgaim
	if ([serviceID hasPrefix:@"libgaim"]) {
		NSMutableString *newServiceID = [serviceID mutableCopy];
		[newServiceID replaceOccurrencesOfString:@"libgaim"
									  withString:@"libpurple"
										 options:(NSLiteralSearch | NSAnchoredSearch)
										   range:NSMakeRange(0, [newServiceID length])];
		serviceID = [newServiceID autorelease];

	} else if ([serviceID hasSuffix:@"LIBGAIM"]) {
		if ([serviceID isEqualToString:@"AIM-LIBGAIM"]) {
			NSString 	*uid = [accountDict objectForKey:ACCOUNT_UID];
			if (uid && [uid length]) {
				const char	firstCharacter = [uid characterAtIndex:0];
				
				if ([uid hasSuffix:@"@mac.com"]) {
					serviceID = @"libpurple-oscar-Mac";
				} else if (firstCharacter >= '0' && firstCharacter <= '9') {
					serviceID = @"libpurple-oscar-ICQ";
				} else {
					serviceID = @"libpurple-oscar-AIM";
				}
			}
		} else if ([serviceID isEqualToString:@"GaduGadu-LIBGAIM"]) {
			serviceID = @"libpurple-Gadu-Gadu";
		} else if ([serviceID isEqualToString:@"Jabber-LIBGAIM"]) {
			serviceID = @"libpurple-Jabber";
		} else if ([serviceID isEqualToString:@"MSN-LIBGAIM"]) {
			serviceID = @"libpurple-MSN";
		} else if ([serviceID isEqualToString:@"Napster-LIBGAIM"]) {
			serviceID = @"libpurple-Napster";
		} else if ([serviceID isEqualToString:@"Novell-LIBGAIM"]) {
			serviceID = @"libpurple-GroupWise";
		} else if ([serviceID isEqualToString:@"Sametime-LIBGAIM"]) {
			serviceID = @"libpurple-Sametime";
		} else if ([serviceID isEqualToString:@"Yahoo-LIBGAIM"]) {
			serviceID = @"libpurple-Yahoo!";
		} else if ([serviceID isEqualToString:@"Yahoo-Japan-LIBGAIM"]) {
			serviceID = @"libpurple-Yahoo!-Japan";
		}
	} else if ([serviceID isEqualToString:@"rvous-libezv"])
		serviceID = @"bonjour-libezv";
	else if ([serviceID isEqualToString:@"joscar-OSCAR-AIM"])
		serviceID = @"libpurple-oscar-AIM";
	else if ([serviceID isEqualToString:@"joscar-OSCAR-dotMac"])
		serviceID = @"libpurple-oscar-Mac";
	
	return serviceID;
}

/*!
 * @brief Save accounts to disk
 */
- (void)_saveAccounts
{
	NSMutableArray	*flatAccounts = [NSMutableArray array];
	AIAccount		*account;
	
	//Build a flattened array of the accounts
	for (account in accounts) {
		if (![account isTemporary]) {
			NSMutableDictionary		*flatAccount = [NSMutableDictionary dictionary];
			AIService				*service = account.service;
			[flatAccount setObject:service.serviceCodeUniqueID forKey:ACCOUNT_TYPE]; 	//Unique plugin ID
			[flatAccount setObject:service.serviceID forKey:ACCOUNT_SERVICE];	    	//Shared service ID
			[flatAccount setObject:account.UID forKey:ACCOUNT_UID];		    					//Account UID
			[flatAccount setObject:account.internalObjectID forKey:ACCOUNT_OBJECT_ID];  			//Account Object ID
			
			[flatAccounts addObject:flatAccount];
		}
	}
	
	//Add any unloadable accounts so they're not lost
	[flatAccounts addObjectsFromArray:unloadableAccounts];

	//Save and broadcast an account list changed notification
	[adium.preferenceController setPreference:flatAccounts forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	[[NSNotificationCenter defaultCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

/*!
 * @brief Perform upgrades for a new version
 *
 * 1.0: KEY_ACCOUNT_DISPLAY_NAME and @"textProfile" cleared if @"" and moved to global if identical on all accounts
 */
- (void)upgradeAccounts
{
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber		*upgradedAccounts = [userDefaults objectForKey:@"Adium:Account Prefs Upgraded for 1.0"];
	
	if (!upgradedAccounts || ![upgradedAccounts boolValue]) {
		[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"Adium:Account Prefs Upgraded for 1.0"];

		//Adium 0.8x would store @"" in preferences which we now want to be able to inherit global values if they don't have a value.
		NSSet	*keysWeNowUseGlobally = [NSSet setWithObjects:KEY_ACCOUNT_DISPLAY_NAME, @"textProfile", nil];

		NSCharacterSet	*whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

		for (NSString *key in keysWeNowUseGlobally) {
			NSAttributedString	*firstAttributedString = nil;
			BOOL				allOnThisKeyAreTheSame = YES;

			for (AIAccount *account in self.accounts) {
				NSAttributedString *attributedString = [[account preferenceForKey:key
																			group:GROUP_ACCOUNT_STATUS] attributedString];
				if (attributedString && ![attributedString length]) {
					[account setPreference:nil
									forKey:key
									 group:GROUP_ACCOUNT_STATUS];
					attributedString = nil;
				}
				
				if (attributedString) {
					if (firstAttributedString) {
						/* If this string is not the same as the first one we found, all are not the same.
						 * Only need to check if thus far they all have been the same
						 */
						if (allOnThisKeyAreTheSame &&
							![[[attributedString string] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] isEqualToString:
								[[firstAttributedString string] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet]]) {
							allOnThisKeyAreTheSame = NO;
						}
					} else {
						//Note the first one we find, which will be our reference
						firstAttributedString = attributedString;
					}
				}
			}
			
			if (allOnThisKeyAreTheSame && firstAttributedString) {
				//All strings on this key are the same. Set the preference globally...
				[adium.preferenceController setPreference:[firstAttributedString dataRepresentation]
													 forKey:key
													  group:GROUP_ACCOUNT_STATUS];
				
				//And remove it from all accounts
				for (AIAccount *account in self.accounts) {
					[account setPreference:nil
									forKey:key
									 group:GROUP_ACCOUNT_STATUS];
				}
			}
		}

		[userDefaults synchronize];
	}
}

@end
