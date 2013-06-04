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


#import "AIAccountController.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import "AIStatusController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "AdiumServices.h"
#import "AdiumPasswords.h"
#import "AdiumAccounts.h"
#import "AdiumPreferredAccounts.h"
#import "AIEditAccountWindowController.h"

#define ACCOUNT_DEFAULT_PREFS			@"AccountPrefs"

@implementation AIAccountController

//init
- (id)init
{
	if ((self = [super init])) {
		adiumServices = [[AdiumServices alloc] init];
		adiumPasswords = [[AdiumPasswords alloc] init];
		adiumAccounts = [[AdiumAccounts alloc] init];
		adiumPreferredAccounts = [[AdiumPreferredAccounts alloc] init];
	}
	
	return self;
}

//Finish initialization once other controllers have set themselves up
- (void)controllerDidLoad
{   
	//Default account preferences
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
	
	//Finish prepping the accounts
	[adiumAccounts controllerDidLoad];
	
	[adiumPasswords controllerDidLoad];
}

//close
- (void)controllerWillClose
{
    //Disconnect all accounts
    [self disconnectAllAccounts];
}

- (void)dealloc
{/*
	[adiumServices release];
	[adiumPasswords release];
	[adiumAccounts release];
	[adiumPreferredAccounts release];
*/
	[super dealloc];
}

//Services
#pragma mark Services
- (void)registerService:(AIService *)inService {
	[adiumServices registerService:inService];
}
- (NSArray *)services {
	return [adiumServices services];
}
- (NSSet *)activeServicesIncludingCompatibleServices:(BOOL)includeCompatible {
	return [adiumServices activeServicesIncludingCompatibleServices:includeCompatible];
}
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID {
	return [adiumServices serviceWithUniqueID:uniqueID];
}
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID {
	return [adiumServices firstServiceWithServiceID:serviceID];
}

//Passwords
#pragma mark Passwords
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount {
	[adiumPasswords setPassword:inPassword forAccount:inAccount];
}
- (void)forgetPasswordForAccount:(AIAccount *)inAccount {
	[adiumPasswords forgetPasswordForAccount:inAccount];
}
- (NSString *)passwordForAccount:(AIAccount *)inAccount {
	return [adiumPasswords passwordForAccount:inAccount];
}
- (void)passwordForAccount:(AIAccount *)inAccount promptOption:(AIPromptOption)promptOption notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext {
	[adiumPasswords passwordForAccount:inAccount promptOption:promptOption notifyingTarget:inTarget selector:inSelector context:inContext];
}
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName {
	[adiumPasswords setPassword:inPassword forProxyServer:server userName:userName];
}
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName {
	return [adiumPasswords passwordForProxyServer:server userName:userName];
}
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext {
	[adiumPasswords passwordForProxyServer:server userName:userName notifyingTarget:inTarget selector:inSelector context:inContext];
}
- (void)passwordForType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount promptOption:(AIPromptOption)inOption name:(NSString *)inName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext {
	[adiumPasswords passwordForType:inType forAccount:inAccount promptOption:inOption name:inName notifyingTarget:inTarget selector:inSelector context:inContext];
}
- (NSString *)passwordForType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount name:(NSString *)inName {
	return [adiumPasswords passwordForType:inType forAccount:inAccount name:inName];
}
- (void)setPassword:(NSString *)inPassword forType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount name:(NSString *)inName {
	[adiumPasswords setPassword:inPassword forType:inType forAccount:inAccount name:inName];
}

//Accounts
#pragma mark Accounts
- (NSArray *)accounts {
	return [adiumAccounts accounts];
}
- (NSArray *)accountsCompatibleWithService:(AIService *)service {
	return [adiumAccounts accountsCompatibleWithService:service];
}
/**
 @brief Returns a list of accounts with a given status.
 This method returns a list of account that all share some specific AIStatus object. It
 was created so that AppleScript's statuses might know who was using them, and
 could dynamically change its properties. As it uses NSPredicate, it only works in 10.4
 and above.
 */
- (NSArray *)accountsWithCurrentStatus:(AIStatus *)status {
	return [[self accounts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", status]];
}
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID {
	return [adiumAccounts accountWithInternalObjectID:objectID];
}
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID {
	return [adiumAccounts createAccountWithService:service UID:inUID];
}
- (void)addAccount:(AIAccount *)inAccount {
	[adiumAccounts addAccount:inAccount];
}
- (void)deleteAccount:(AIAccount *)inAccount {
	[adiumAccounts deleteAccount:inAccount];
}
- (NSUInteger)moveAccount:(AIAccount *)account toIndex:(NSUInteger)destIndex {
	return [adiumAccounts moveAccount:account toIndex:destIndex];
}
- (void)accountDidChangeUID:(AIAccount *)inAccount {
	[adiumAccounts accountDidChangeUID:inAccount];
}
- (void)moveAccount:(AIAccount *)account toService:(AIService *)service
{
	[adiumAccounts moveAccount:account  toService:service];
}

//Preferred Accounts
#pragma mark Preferred Accounts
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
	AIAccount *account = [adiumPreferredAccounts preferredAccountForSendingContentType:inType toContact:inContact];
	
	NSAssert([account.service.serviceClass isEqualToString:inContact.service.serviceClass], @"Wrong account for the contact; differing services.");
	
	return account;
}

- (void)disconnectAllAccounts
{
    for (AIAccount *account in self.accounts) {
        if (account.online) 
			[account disconnect];
    }
}

//XXX - Re-evaluate this method and its presence in the core
- (BOOL)oneOrMoreConnectedAccounts
{
    for (AIAccount *account in self.accounts) {
        if (account.online) {
			return YES;
        }
    }
	
	return NO;
}

//XXX - Re-evaluate this method and its presence in the core
- (BOOL)oneOrMoreConnectedOrConnectingAccounts
{
    for (AIAccount *account in self.accounts) {
        if (account.online || [account boolValueForProperty:@"isConnecting"] || [account valueForProperty:@"waitingToReconnect"]) {
			return YES;
        }
    }	

	return NO;	
}

#pragma mark Editing
- (void)editAccount:(AIAccount *)account onWindow:(NSWindow *)window notifyingTarget:(id)target
{
	AIEditAccountWindowController *accountWindowController = [[AIEditAccountWindowController alloc] initWithAccount:account
																									notifyingTarget:target];
	[accountWindowController showOnWindow:window];
}

@end

@implementation AIAccountController (AIAccountControllerObjectSpecifier)
- (NSScriptObjectSpecifier *) objectSpecifier {
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	NSScriptObjectSpecifier *container = [[NSApplication sharedApplication] objectSpecifier];
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"accountController"] autorelease];
}
@end
