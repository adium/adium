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

#import "GBFireImporter.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>

#import <AIUtilities/AIFileManagerAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import "AIHTMLDecoder.h"
#import "AIStatusController.h"

#import <Adium/AIListGroup.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import "GBFireLogImporter.h"

#define FIRECONFIGURATION2		@"FireConfiguration2.plist"
#define FIRECONFIGURATION		@"FireConfiguration.plist"
#define ACCOUNTS2				@"Accounts2.plist"
#define ACCOUNTS				@"Accounts.plist"

@interface GBFireImportedBuddy : NSObject{
	AIListContact *contact;

	AIAccount *account;
	NSString *groupName;
	NSString *screenname;
	NSString *displayName;
	BOOL blocked;
}

- (id)initScreenname:(NSString *)screen forAccount:(AIAccount *)acct;
- (AIAccount *)account;
- (void)setGroup:(NSString *)group;
- (void)setBlocked:(BOOL)block;
- (void)setDisplayName:(NSString *)alias;
- (AIListContact *)createContact;
- (AIListContact *)contact;
@end

@implementation GBFireImportedBuddy
- (id)initScreenname:(NSString *)screen forAccount:(AIAccount *)acct
{
	self = [super init];
	if(!self)
		return nil;
	
	screenname = [screen retain];
	account = [acct retain];
	groupName = nil;
	displayName = nil;
	blocked = NO;
	
	return self;
}

- (void)dealloc
{
	[screenname release];
	[account release];
	[groupName release];
	[displayName release];
	[super dealloc];
}

- (AIAccount *)account
{
	return account;
}

- (void)setGroup:(NSString *)group
{
	[groupName release];
	groupName = [group retain];
}

- (void)setBlocked:(BOOL)block
{
	blocked = block;
}

- (void)setDisplayName:(NSString *)alias
{
	[displayName release];
	displayName = [alias retain];
}

- (AIListContact *)createContact
{
	if(contact != nil)
		return contact;
	
	id <AIContactController> contactController = adium.contactController;

	contact = [contactController contactWithService:account.service account:account UID:screenname];
	if(displayName != nil)
		[contact setDisplayName:displayName];
	if(blocked)
		[contact setIsBlocked:YES updateList:YES];
	if(groupName)
		[contact addRemoteGroupName:groupName];
	
	return contact;
}

- (AIListContact *)contact
{
	return contact;
}
@end

@interface GBFireImporter ()
- (BOOL)importFireConfiguration;
- (BOOL)import2:(NSString *)fireDir;
- (BOOL)import1:(NSString *)fireDir;
@end

/*!
 * @class GBFireImporter
 * @brief Importer for Fire's configuration
 *
 * This class attempts to import Fire's configuration.  This includes status messages, accounts,
 * groups, buddies, and meta-contacts.
 */

@implementation GBFireImporter

- (id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	accountUIDtoAccount = [[NSMutableDictionary alloc] init];
	aliasToContacts = [[NSMutableDictionary alloc] init];
	buddiesToContact = [[NSMutableDictionary alloc] init];
	personLists = [[NSMutableArray alloc] init];

	serviceDict = [[NSMutableDictionary alloc] init];
	for (AIService *service in adium.accountController.services)
	{
		[serviceDict setObject:service forKey:service.serviceID];
	}
	[serviceDict setObject:[serviceDict objectForKey:@"Bonjour"] forKey:@"Rendezvous"];
	[serviceDict setObject:[serviceDict objectForKey:@"GTalk"] forKey:@"GoogleTalk"];
	[serviceDict setObject:[serviceDict objectForKey:@"Yahoo!"] forKey:@"Yahoo"];
	
	return self;
}

- (void)dealloc
{
	[accountUIDtoAccount release];
	[aliasToContacts release];
	[buddiesToContact release];
	[personLists release];
	[serviceDict release];
	[super dealloc];
}

- (void)accountConnected:(NSNotification *)notification
{
	id <AIContactController> contactController = adium.contactController;
	AIAccount *acct = [notification object];
	
	for (NSArray *personContacts in [NSArray arrayWithArray:personLists]) {
		BOOL aBuddyNotCreated = NO;
		BOOL aBuddyCreated = NO;
		NSMutableArray *thisMetaContact = [[NSMutableArray alloc] init];
		for (GBFireImportedBuddy *buddy in personContacts) {
			AIListContact *contact = [buddy contact];
			if(contact != nil)
			{
				[thisMetaContact addObject:contact];
				continue;
			}
			if(buddy.account == acct)
			{
				contact = [buddy createContact];
				[thisMetaContact addObject:contact];
				aBuddyCreated = YES;
			}
			else
			{
				aBuddyNotCreated = YES;
			}
		}
		if(aBuddyCreated && [thisMetaContact count] > 1)
			[contactController groupContacts:thisMetaContact];
		if(!aBuddyNotCreated)
			[personLists removeObject:personContacts];
		[thisMetaContact release];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ACCOUNT_CONNECTED object:acct];
	[self autorelease];
}

/*!
 * @brief Attempt to import Fire's config.  Returns YES if successful
 */

+ (BOOL)importFireConfiguration
{
	GBFireImporter *importer = [[GBFireImporter alloc] init];
	BOOL ret = [importer importFireConfiguration];
	
	[importer release];
	return ret;
}

- (BOOL)importFireConfiguration
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *fireDir = [[[NSFileManager defaultManager] userApplicationSupportFolder] stringByAppendingPathComponent:@"Fire"];
	BOOL version2Succeeded = NO;
	BOOL version1Succeeded = NO;
	BOOL ret = YES;
	
	version2Succeeded = [self import2:fireDir];
	
	if(!version2Succeeded)
		//try version 1
		version1Succeeded = [self import1:fireDir];
	
	if(!version2Succeeded && !version1Succeeded)
		//throw some error
		ret = NO;
	
	[pool release];
	[GBFireLogImporter importLogs];
	return ret;
}

- (AIService *)translateServiceName:(NSString *)serviceName screenName:(NSString *)screenName;
{
	if([serviceName isEqualTo:@"Jabber"] && [screenName hasSuffix:@"@gmail.com"])
		serviceName = @"GoogleTalk";
	
	return [serviceDict objectForKey:serviceName];
}

- (NSInteger)checkPort:(NSInteger)port forService:(AIService *)service
{
	if(port == 0)
		return 0;
	if([service.serviceID isEqualTo:@"AIM"] && port == 9898)
		return 0;
	if([service.serviceID isEqualTo:@"GTalk"] && port == 5223)
		return 0;
	return port;
}

- (NSString *)checkHost:(NSString *)host forService:(AIService *)service
{
	if(host == nil)
		return nil;
	if([service.serviceID isEqualTo:@"AIM"] && [host hasPrefix:@"toc"])
		return nil;
	return host;
}

- (void)importAccounts2:(NSArray *)accountsDict
{
	NSDictionary *account = nil;
	for(account in accountsDict)
	{
		NSString *serviceName = [account objectForKey:@"ServiceName"];
		NSString *accountName = [account objectForKey:@"Username"];
		if(![serviceName length] || ![accountName length])
			continue;
		AIService *service = [self translateServiceName:serviceName screenName:accountName];
		if(service == nil)
			//Like irc service
			continue;
		AIAccount *newAcct = [adium.accountController createAccountWithService:service
																			 UID:accountName];
		if(newAcct == nil)
			continue;
		
		[newAcct setPreference:[account objectForKey:@"AutoLogin"]
						forKey:@"Online"
						 group:GROUP_ACCOUNT_STATUS];
		
		NSDictionary *properties = [account objectForKey:@"Properties"];
		NSString *connectHost = [properties objectForKey:@"server"];
		if([self checkHost:connectHost forService:service])
			[newAcct setPreference:connectHost
							forKey:KEY_CONNECT_HOST
							 group:GROUP_ACCOUNT_STATUS];	
		
		NSInteger port = [[properties objectForKey:@"port"] integerValue];
		if([self checkPort:port forService:service])
			[newAcct setPreference:[NSNumber numberWithInteger:port]
							forKey:KEY_CONNECT_PORT
							 group:GROUP_ACCOUNT_STATUS];
		
		[accountUIDtoAccount setObject:newAcct forKey:[account objectForKey:@"UniqueID"]];
		[adium.accountController addAccount:newAcct];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(accountConnected:)
										   name:ACCOUNT_CONNECTED
										 object:newAcct];
		//Retain for each account
		[self retain];
		[newAcct setShouldBeOnline:YES];
	}
}

- (void)importAways2:(NSArray *)awayList
{
	NSDictionary *away = nil;
	for(away in awayList)
	{
		NSString *title = [away objectForKey:@"Title"];
		BOOL isDefault = [[away objectForKey:@"isIdleMessage"] boolValue];
		BOOL goIdle = [[away objectForKey:@"idleMessage"] boolValue];
		NSString *attrMessage = [away objectForKey:@"message"];
		NSInteger fireType = [[away objectForKey:@"messageType"] integerValue];
		AIStatusType adiumType = 0;
		
		switch(fireType)
		{
			case 0:
			case 1:
				adiumType = AIAvailableStatusType;
				break;
			case 4:
				adiumType = AIInvisibleStatusType;
				break;
			case 3:
			case 2:
			default:
				adiumType = AIAwayStatusType;
		}
		
		AIStatus *newStatus = [AIStatus statusOfType:adiumType];
		[newStatus setTitle:title];
		[newStatus setStatusMessage:[AIHTMLDecoder decodeHTML:attrMessage]];
		[newStatus setAutoReplyIsStatusMessage:YES];
		[newStatus setShouldForceInitialIdleTime:goIdle];
		if(isDefault)
			[adium.preferenceController setPreference:[newStatus uniqueStatusID]
												 forKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID
												  group:PREF_GROUP_STATUS_PREFERENCES];
		[adium.statusController addStatusState:newStatus];
	}	
}

NSComparisonResult groupSort(id left, id right, void *context)
{
	NSNumber *leftNum = [left objectForKey:@"position"];
	NSNumber *rightNum = [right objectForKey:@"position"];
	NSComparisonResult ret = NSOrderedSame;
	
	if(leftNum == nil)
	{
		if(rightNum != nil)
			ret = NSOrderedAscending;
	}
	else if (rightNum == nil)
		ret = NSOrderedDescending;
	else
		ret = [leftNum compare:rightNum];
	
	return ret;
}

- (void)importGroups2:(NSDictionary *)groupList
{
	id <AIContactController> contactController = adium.contactController;

	//First iterate through the groups and create an array we can sort
	NSMutableArray *groupArray = [NSMutableArray array];
	for (NSString *groupName in groupList) {
		NSMutableDictionary *groupDict = [[groupList objectForKey:groupName] mutableCopy];
		[groupDict setObject:groupName forKey:@"Name"];
		[groupArray addObject:groupDict];
		[groupDict release];
	}
	[groupArray sortUsingFunction:groupSort context:NULL];

	for(NSDictionary *group in groupArray)
	{
		AIListGroup *newGroup = [contactController groupWithUID:[group objectForKey:@"Name"]];
		NSNumber *expanded = [group objectForKey:@"groupexpanded"];
		if(expanded != nil)
			[newGroup setExpanded:[expanded boolValue]];
	}	
}

- (void)importBuddies2:(NSArray *)buddyArray
{
	NSDictionary *buddy = nil;
	for(buddy in buddyArray)
	{
		NSNumber *inList = [buddy objectForKey:@"BuddyInList"];
		if(inList == nil || [inList boolValue] == NO)
			continue;
		
		NSNumber *accountNumber = [buddy objectForKey:@"account"];
		AIAccount *account = [accountUIDtoAccount objectForKey:accountNumber];
		if(account == nil)
			continue;
		
		NSString *buddyName = [buddy objectForKey:@"buddyname"];
		if([buddyName length] == 0)
			continue;
		
		GBFireImportedBuddy *newContact = [[GBFireImportedBuddy alloc] initScreenname:buddyName forAccount:account];
		
		NSMutableDictionary *accountBuddyList = [buddiesToContact objectForKey:accountNumber];
		if(accountBuddyList == nil)
		{
			accountBuddyList = [NSMutableDictionary dictionary];
			[buddiesToContact setObject:accountBuddyList forKey:accountNumber];
		}
		[accountBuddyList setObject:newContact forKey:buddyName];
		
		NSString *alias = [buddy objectForKey:@"displayname"];
		if([alias length] != 0)
		{
			[newContact setDisplayName:alias];
			NSMutableArray *contactArray = [aliasToContacts objectForKey:alias];
			if(contactArray == nil)
			{
				contactArray = [NSMutableArray array];
				[aliasToContacts setObject:contactArray forKey:alias];
			}
			[contactArray addObject:newContact];
		}
		
		BOOL blocked = [[buddy objectForKey:@"BuddyBlocked"] boolValue];
		if(blocked)
			[newContact setBlocked:YES];
		
		//Adium can only support a single group per buddy (boo!!!) so use the first
		NSString *groupName = ([[buddy objectForKey:@"Groups"] count] ? [[buddy objectForKey:@"Groups"] objectAtIndex:0] : nil);
		if([groupName length] != 0)
			[newContact setGroup:groupName];
		[newContact release];
	}	
}

- (void)importPersons2:(NSArray *)personArray
{
	NSDictionary *person = nil;
	for(person in personArray)
	{
		NSString *personName = [person objectForKey:@"Name"];
		if([personName length] == 0)
			continue;
		
		if([personName hasPrefix:@"Screenname:"])
			continue;
		
		NSArray *buddyArray = [person objectForKey:@"Buddies"];
		if([buddyArray count] == 0)
			//Empty meta-contact; don't bother
			continue;

		NSMutableArray *buddies = [NSMutableArray array];
		for (NSDictionary *buddyInfo in buddyArray) {
			NSNumber *buddyAccount = [buddyInfo objectForKey:@"BuddyAccount"];
			NSString *buddySN = [buddyInfo objectForKey:@"BuddyName"];
			
			if(buddyAccount == nil || buddySN == nil)
				continue;
			
			GBFireImportedBuddy *contact = [[buddiesToContact objectForKey:buddyAccount] objectForKey:buddySN];
			if(contact == nil)
				//Contact lookup failed
				continue;
			
			[buddies addObject:contact];
		}
		[personLists addObject:buddies];
	}
}

- (void)createMetaContacts
{
	for (NSArray *contacts in [aliasToContacts objectEnumerator])
		[personLists addObject:contacts];
}

- (BOOL)import2:(NSString *)fireDir
{
	NSString *configPath = [fireDir stringByAppendingPathComponent:FIRECONFIGURATION2];
	NSString *accountPath = [fireDir stringByAppendingPathComponent:ACCOUNTS2];
	NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configPath];
	NSDictionary *accountDict = [NSDictionary dictionaryWithContentsOfFile:accountPath];
	
	if(configDict == nil || accountDict == nil)
		//no dictionary or no account, can't import
		return NO;
	
	//Start with accounts
	[self importAccounts2:[accountDict objectForKey:@"Accounts"]];
	
	//Away Messages
	[self importAways2:[configDict objectForKey:@"awayMessages"]];

	//Now for the groups
	[self importGroups2:[configDict objectForKey:@"groups"]];
	
	//Buddies
	[self importBuddies2:[configDict objectForKey:@"buddies"]];

	//Persons
	NSArray *personArray = [configDict objectForKey:@"persons"];
	if([personArray count] > 0)
		[self importPersons2:personArray];
	else
		[self createMetaContacts];
	
	return YES;
}

- (void)importAccounts1:(NSDictionary *)accountsDict
{
	for (NSString *serviceName in accountsDict) {
		if(![serviceName length])
			continue;
		
		for (NSDictionary *account in [accountsDict objectForKey:serviceName])
		{
			NSString *accountName = [account objectForKey:@"userName"];
			if(![accountName length])
				continue;
			AIService *service = [self translateServiceName:serviceName screenName:accountName];
			AIAccount *newAcct = [adium.accountController createAccountWithService:service
																				 UID:accountName];
			if(newAcct == nil)
				continue;
			
			[newAcct setPreference:[account objectForKey:@"autoLogin"]
							forKey:@"Online"
							 group:GROUP_ACCOUNT_STATUS];
			
			NSString *connectHost = [account objectForKey:@"server"];
			if([self checkHost:connectHost forService:service])
				[newAcct setPreference:connectHost
								forKey:KEY_CONNECT_HOST
								 group:GROUP_ACCOUNT_STATUS];	
			
			NSInteger port = [[account objectForKey:@"port"] integerValue];
			if([self checkPort:port forService:service])
				[newAcct setPreference:[NSNumber numberWithInteger:port]
								forKey:KEY_CONNECT_PORT
								 group:GROUP_ACCOUNT_STATUS];
			
			[accountUIDtoAccount setObject:newAcct forKey:[NSString stringWithFormat:@"%@-%@@%@", serviceName, accountName, connectHost]];
			[adium.accountController addAccount:newAcct];
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(accountConnected:)
											   name:ACCOUNT_CONNECTED
											 object:newAcct];
			//Retain for each account
			[self retain];
			[newAcct setShouldBeOnline:YES];
		}
	}
}

- (void)importAways1:(NSArray *)awayList
{
	NSDictionary *away = nil;
	for(away in awayList)
	{
		NSString *title = [away objectForKey:@"Title"];
		BOOL isDefault = [[away objectForKey:@"isIdleMessage"] boolValue];
		BOOL goIdle = [[away objectForKey:@"idleMessage"] boolValue];
		NSString *message = [away objectForKey:@"message"];
		NSInteger fireType = [[away objectForKey:@"messageType"] integerValue];
		AIStatusType adiumType = 0;
		
		switch(fireType)
		{
			case 0:
			case 1:
				adiumType = AIAvailableStatusType;
				break;
			case 4:
				adiumType = AIInvisibleStatusType;
				break;
			case 3:
			case 2:
			default:
				adiumType = AIAwayStatusType;
		}
		
		AIStatus *newStatus = [AIStatus statusOfType:adiumType];
		[newStatus setTitle:title];
		[newStatus setStatusMessage:[[[NSAttributedString alloc] initWithString:message] autorelease]];
		[newStatus setAutoReplyIsStatusMessage:YES];
		[newStatus setShouldForceInitialIdleTime:goIdle];
		if(isDefault)
			[adium.preferenceController setPreference:[newStatus uniqueStatusID]
												 forKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID
												  group:PREF_GROUP_STATUS_PREFERENCES];
		[adium.statusController addStatusState:newStatus];
	}	
}

- (void)importBuddies1:(NSArray *)buddyArray
			   toGroup:(NSString *)groupName
{
	NSDictionary *buddy = nil;
	for(buddy in buddyArray)
	{
		NSString *buddyName = [buddy objectForKey:@"buddyname"];
		if([buddyName length] == 0)
			continue;
		
		NSDictionary *permissionsDict = [buddy objectForKey:@"BuddyPermissions"];
		NSMutableArray *accounts = [NSMutableArray array];
		if(permissionsDict != nil)
		{
			for (NSString *accountKey in permissionsDict) {
				AIAccount *acct = [accountUIDtoAccount objectForKey:accountKey];
				if(acct != nil && [[[permissionsDict objectForKey:accountKey] objectForKey:@"BuddyinList"] boolValue])
					[accounts addObject:acct];
			}
		}
		else
		{
			for (AIAccount *acct in accountUIDtoAccount)
			{
				if([acct.service.serviceClass isEqualToString:[buddy objectForKey:@"service"]])
					[accounts addObject:acct];
			}
		}
		
		for (AIAccount *account in accounts) {
			GBFireImportedBuddy *newContact = [[GBFireImportedBuddy alloc] initScreenname:buddyName forAccount:account];
			if(newContact == nil)
				continue;
			
			NSString *alias = [buddy objectForKey:@"displayname"];
			if([alias length] != 0)
			{
				[newContact setDisplayName:alias];
				NSMutableArray *contactArray = [aliasToContacts objectForKey:alias];
				if(contactArray == nil)
				{
					contactArray = [NSMutableArray array];
					[aliasToContacts setObject:contactArray forKey:alias];
				}
				[contactArray addObject:newContact];
			}
			
			if([groupName length] != 0)
				[newContact setGroup:groupName];
			[newContact release];
		}
	}	
}

- (void)importGroups1:(NSDictionary *)groupList
{
	id <AIContactController> contactController = adium.contactController;
	
	//First iterate through the groups and create an array we can sort
	NSMutableArray *groupArray = [NSMutableArray array];
	for (NSString *groupName in groupList)	{
		NSMutableDictionary *groupDict = [[groupList objectForKey:groupName] mutableCopy];
		[groupDict setObject:groupName forKey:@"Name"];
		[groupArray addObject:groupDict];
		[groupDict release];
	}
	[groupArray sortUsingFunction:groupSort context:NULL];
	NSDictionary *group = nil;
	for(group in groupArray)
	{
		NSString *groupName = [group objectForKey:@"Name"];
		AIListGroup *newGroup = [contactController groupWithUID:groupName];
		NSNumber *expanded = [group objectForKey:@"groupexpanded"];
		if(expanded != nil)
			[newGroup setExpanded:[expanded boolValue]];
		[self importBuddies1:[group objectForKey:@"buddies"]
					 toGroup:groupName];
	}
}

- (BOOL)import1:(NSString *)fireDir
{
	NSString *configPath = [fireDir stringByAppendingPathComponent:FIRECONFIGURATION];
	NSString *accountPath = [fireDir stringByAppendingPathComponent:ACCOUNTS];
	NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configPath];
	NSDictionary *accountDict = [NSDictionary dictionaryWithContentsOfFile:accountPath];
	
	if(configDict == nil || accountDict == nil)
		//no dictionary or no account, can't import
		return NO;
	
	//Start with accounts
	[self importAccounts1:accountDict];
	
	//Away Messages
	[self importAways1:[configDict objectForKey:@"awayMessages"]];
	
	//Now for the groups
	[self importGroups1:[configDict objectForKey:@"groups"]];
	
	//Persons
	[self createMetaContacts];
	
	return YES;
}

@end
