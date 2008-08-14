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

#import "AdiumPasswords.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIKeychain.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <objc/objc-runtime.h>

#import "ESAccountPasswordPromptController.h"
#import "ESProxyPasswordPromptController.h"

#define KEY_PERFORMED_ACCOUNT_PASSWORD_UPGRADE @"Adium 1.3: Account Passwords Upgraded"

@interface AdiumPasswords ()
- (NSString *)_oldStyleAccountNameForAccount:(AIAccount *)inAccount;
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount;
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount;
- (NSString *)_serverNameForAccount:(AIAccount *)inAccount;
- (NSString *)_accountNameForProxyServer:(NSString *)proxyServer userName:(NSString *)userName;
- (NSString *)_passKeyForProxyServer:(NSString *)proxyServer;
- (void)_upgradeAccountPasswordKeychainEntries;
@end

@implementation AdiumPasswords

/*!
 * @brief Finish Initing
 *
 * Requires that all accounts have been loaded
 */
- (void)controllerDidLoad 
 {
	[self _upgradeAccountPasswordKeychainEntries];
}

//Accounts -------------------------------------------------------------------------------------------------------------
#pragma mark Accounts

/*!
 * @brief Set the password of an account
 *
 * @param inPassword password to store
 * @param inAccount account the password belongs to
 */
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount
{
	NSError *error = nil;
	[[AIKeychain defaultKeychain_error:&error] setInternetPassword:inPassword
														 forServer:[self _serverNameForAccount:inAccount]
														   account:[self _accountNameForAccount:inAccount]
														  protocol:FOUR_CHAR_CODE('AdIM')
															 error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't ignore it if we're trying to set the password, though (because that would be strange).
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (inPassword || (err != errSecItemNotFound)) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not %@ password for account %@: %@ returned %i (%@)", inPassword ? @"set" : @"remove", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Forget the password of an account
 *
 * @param inAccount account whose password should be forgotten
 */
- (void)forgetPasswordForAccount:(AIAccount *)inAccount
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	[keychain deleteInternetPasswordForServer:[self _serverNameForAccount:inAccount]
									  account:[self _accountNameForAccount:inAccount]
									 protocol:FOUR_CHAR_CODE('AdIM')
										error:&error];

	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not delete password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Retrieve the password of an account
 * 
 * @param inAccount account whose password is desired
 * @return account password, or nil if the password is not available
 */
- (NSString *)passwordForAccount:(AIAccount *)inAccount
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _serverNameForAccount:inAccount]
														account:[self _accountNameForAccount:inAccount]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for account %@: %@ returned %i (%@)", [self _accountNameForAccount:inAccount], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	return password;
}

- (void)retrievedPassword:(NSDictionary *)requestDict
{
	NSString		*password = [requestDict objectForKey:@"Password"];
	AIAccount		*account = [requestDict objectForKey:@"Account"];
	AIPromptOption	promptOption = [[requestDict objectForKey:@"AIPromptOption"] integerValue];
	id				target = [requestDict objectForKey:@"Target"];
	SEL				selector = NSSelectorFromString([requestDict objectForKey:@"Selector"]);
	id				context = [requestDict objectForKey:@"Context"];
	BOOL			shouldPrompt = YES;

	switch (promptOption)
	{
		case AIPromptAlways:
			shouldPrompt = YES;
			break;
		case AIPromptAsNeeded:
		{
			if (password && [password length])
				shouldPrompt = NO;
			else 
				shouldPrompt = YES;
			break;
		}
		case AIPromptNever:
			shouldPrompt = NO;
			break;
	}
	
	if (shouldPrompt) {
		//Prompt the user for their password
		[ESAccountPasswordPromptController showPasswordPromptForAccount:account
															   password:password
														notifyingTarget:target
															   selector:selector
																context:context];
	} else {
		//Invoke the target right away
		void (*targetMethodSender)(id, SEL, id, AIPasswordPromptReturn, id) = (void (*)(id, SEL, id, AIPasswordPromptReturn, id)) objc_msgSend;
		targetMethodSender(target, selector, password, AIPasswordPromptOKReturn, context);
	}	
}

- (void)threadedPasswordRetrieval:(NSMutableDictionary *)requestDict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString	*password = [self passwordForAccount:[requestDict objectForKey:@"Account"]];
	if (password)
		[requestDict setObject:password forKey:@"Password"];

	[self performSelectorOnMainThread:@selector(retrievedPassword:)
						   withObject:requestDict
						waitUntilDone:NO];
	[pool release];
}

/*!
 * @brief Retrieve the password of an account, prompting the user if necessary
 *
 * @param inAccount account whose password is desired
 * @param promptOption An AIPromptOption determining whether and how a prompt for the password should be displayed if it is needed. This allows forcing or suppressing of the prompt dialogue.
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available
 * @param inContext context passed to target
 */
- (void)passwordForAccount:(AIAccount *)inAccount promptOption:(AIPromptOption)promptOption notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	[NSThread detachNewThreadSelector:@selector(threadedPasswordRetrieval:)
							 toTarget:self
						   withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
									   inAccount, @"Account",
									   [NSNumber numberWithInteger:promptOption], @"AIPromptOption",
									   inTarget, @"Target",
									   NSStringFromSelector(inSelector), @"Selector",
									   inContext, @"Context" /* may be nil so should be last */,
									   nil]];
}

//Proxy Servers --------------------------------------------------------------------------------------------------------
#pragma mark Proxy Servers

/*!
 * @brief Set the password for a proxy server
 *
 * @param inPassword password to store
 * @param server proxy server name
 * @param userName proxy server user name
 *
 * XXX - This is inconsistent.  Above we have a separate forget method, here we forget when nil is passed...
 */
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName
{
	NSError *error = nil;
	[[AIKeychain defaultKeychain_error:&error] setInternetPassword:inPassword
														 forServer:[self _passKeyForProxyServer:server]
														   account:[self _accountNameForProxyServer:server 
																						   userName:userName]
														  protocol:FOUR_CHAR_CODE('AdIM')
															 error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't ignore it if we're trying to set the password, though (because that would be strange).
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (inPassword || (err != errSecItemNotFound)) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not %@ password for proxy server %@: %@ returned %i (%@)",
			      inPassword ? @"set" : @"remove",
			      [self _accountNameForProxyServer:server
				                          userName:userName],
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
				  err,
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

/*!
 * @brief Retrieve the password for a proxy server
 * 
 * @param server proxy server name
 * @param userName proxy server user name
 * @return proxy server password, or nil if the password is not available
 */
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName
{
	NSError		*error    = nil;
	AIKeychain	*keychain = [AIKeychain defaultKeychain_error:&error];
	NSString	*password = [keychain internetPasswordForServer:[self _passKeyForProxyServer:server]
														account:[self _accountNameForProxyServer:server 
																						userName:userName]
													   protocol:FOUR_CHAR_CODE('AdIM')
														  error:&error];
	if (error) {
		OSStatus err = [error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (err != errSecItemNotFound) {
			NSDictionary *userInfo = [error userInfo];
			NSLog(@"could not retrieve password for proxy server %@: %@ returned %i (%@)",
				  [self _accountNameForProxyServer:server
				                          userName:userName],
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
				  err,
				  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
	return password;
}

/*!
 * @brief Retrieve the password for a proxy server, prompting the user if necessary
 *
 * @param server proxy server name
 * @param userName proxy server user name
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available
 * @param inContext context passed to target
 */
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	NSString	*password = [self passwordForProxyServer:server userName:userName];
	
	if (password && [password length] != 0) {
		//Invoke the target right away
		//Invoke the target right away
		void (*targetMethodSender)(id, SEL, id, AIPasswordPromptReturn, id) = (void (*)(id, SEL, id, AIPasswordPromptReturn, id)) objc_msgSend;
		targetMethodSender(inTarget, inSelector, password, AIPasswordPromptOKReturn, inContext);

	} else {
		//Prompt the user for their password
		[ESProxyPasswordPromptController showPasswordPromptForProxyServer:server
																 userName:userName
														  notifyingTarget:inTarget
																 selector:inSelector
																  context:inContext];
	}
}


//Password Keys --------------------------------------------------------------------------------------------------------
#pragma mark Password Keys

/*!
 * @brief Old-style Keychain identifier for an account
 */
- (NSString *)_oldStyleAccountNameForAccount:(AIAccount *)inAccount{
	return [NSString stringWithFormat:@"%@.%@",[[inAccount service] serviceID],[inAccount internalObjectID]];
}
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount{
	if ([[[adium loginController] userArray] count] > 1) {
		return [NSString stringWithFormat:@"Adium.%@.%@",[[adium loginController] currentUser],[self _oldStyleAccountNameForAccount:inAccount]];
	} else {
		return [NSString stringWithFormat:@"Adium.%@",[self _oldStyleAccountNameForAccount:inAccount]];
	}
}

/*!
 * @brief New-style Keychain identifier for an account
 */
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount {
	return [[inAccount UID] compactedString];
}
- (NSString *)_serverNameForAccount:(AIAccount *)inAccount {
	return [NSString stringWithFormat:@"%@.%@", [[inAccount service] serviceID], [self _accountNameForAccount:inAccount]];
}

/*!
 * @brief Keychain identifier for a proxy server
 */
- (NSString *)_accountNameForProxyServer:(NSString *)proxyServer userName:(NSString *)userName{
	return [NSString stringWithFormat:@"%@.%@",proxyServer,userName];
}
- (NSString *)_passKeyForProxyServer:(NSString *)proxyServer{
	if ([[[adium loginController] userArray] count] > 1) {
		return [NSString stringWithFormat:@"Adium.%@.%@",[[adium loginController] currentUser],proxyServer];
	} else {
		return [NSString stringWithFormat:@"Adium.%@",proxyServer];	
	}
}

#pragma mark Upgrade code

/*!
 * @brief Changes the naming of the Keychain password entries from AdIM://Adium.{Service ID}.{Account internalObjectID} to AdIM://{Service ID}.{Account UID}.
 */
- (void)_upgradeAccountPasswordKeychainEntries
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:KEY_PERFORMED_ACCOUNT_PASSWORD_UPGRADE]) {
		NSError			*error;
		AIKeychain		*keychain = [AIKeychain defaultKeychain_error:&error];
		NSArray			*accounts = [[adium accountController] accounts];
		AIAccount		*account;
		NSString		*password;
		
		for (account in accounts) {
			password = [keychain internetPasswordForServer:[self _passKeyForAccount:account]
												   account:[self _oldStyleAccountNameForAccount:account]
												  protocol:FOUR_CHAR_CODE('AdIM')
													 error:&error];
			if (error) {
				OSStatus err = [error code];
				if (err != errSecItemNotFound) {
					NSDictionary *userInfo = [error userInfo];
					NSLog(@"could not retrieve password for account %@: %@ returned %i (%@)", [self _oldStyleAccountNameForAccount:account], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
				}
			} else {
				[self setPassword:password forAccount:account];
				
				// Delete old keychain entry
				[keychain deleteInternetPasswordForServer:[self _passKeyForAccount:account]
												  account:[self _oldStyleAccountNameForAccount:account]
												 protocol:FOUR_CHAR_CODE('AdIM')
													error:&error];
				if (error) {
					OSStatus err = [error code];
					/*errSecItemNotFound: no entry in the keychain. a harmless error.
					 *we don't get here at all for noErr (error will be nil).
					 */
					if (err != errSecItemNotFound) {
						NSDictionary *userInfo = [error userInfo];
						NSLog(@"could not delete password for account %@: %@ returned %i (%@)", [self _oldStyleAccountNameForAccount:account], [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
					}
				}
			}
		}
		
		[[NSUserDefaults standardUserDefaults] setBool:YES
												forKey:KEY_PERFORMED_ACCOUNT_PASSWORD_UPGRADE];
	}
}

@end
