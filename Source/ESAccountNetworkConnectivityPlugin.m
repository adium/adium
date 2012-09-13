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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import "ESAccountNetworkConnectivityPlugin.h"
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIHostReachabilityMonitor.h>
#import <AIUtilities/AISleepNotification.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>

@interface ESAccountNetworkConnectivityPlugin ()
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable;
- (BOOL)_accountsAreOnlineOrDisconnecting:(BOOL)considerConnecting;

- (void)adiumFinishedLaunching:(NSNotification *)notification;
- (void)systemWillSleep:(NSNotification *)notification;
- (void)systemDidWake:(NSNotification *)notification;
- (void)accountListChanged:(NSNotification *)notification;
@end

/*!
 * @class ESAccountNetworkConnectivityPlugin
 * @brief Handle account connection and disconnection
 *
 * Accounts are automatically connected and disconnected based on:
 *	| If the account is enabled (at Adium launch if the network is available)
 *  | Network connectivity (disconnect when the Internet is not available and connect when it is available again)
 *  | System sleep (disconnect when the system sleeps and connect when it wakes up)
 *
 * Uses AIHostReachabilityMonitor and AISleepNotification from AIUtilities.
 */
@implementation ESAccountNetworkConnectivityPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	//Wait for Adium to finish launching to handle autoconnecting enabled accounts
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	//Monitor system sleep so we can cleanly disconnect / reconnect
    [notificationCenter addObserver:self
						   selector:@selector(systemWillSleep:)
							   name:AISystemWillSleep_Notification
							 object:nil];
    [notificationCenter addObserver:self
						   selector:@selector(systemDidWake:)
							   name:AISystemDidWake_Notification
							 object:nil];
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Adium finished launching
 *
 * Attempt to autoconnect accounts if shift is not being pressed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	NSArray						*accounts = adium.accountController.accounts;
	AIHostReachabilityMonitor	*monitor = [AIHostReachabilityMonitor defaultMonitor];
	BOOL						shiftHeld = [NSEvent shiftKey];
	
	//Start off forbidding all accounts from auto-connecting.
	accountsToConnect    = [[NSMutableSet alloc] initWithArray:accounts];
	accountsToNotConnect = [accountsToConnect mutableCopy];
	knownHosts			 = [[NSMutableSet alloc] init];
	
	/* Add ourselves to the default host-reachability monitor as an observer for each account's host.
	 * At the same time, weed accounts that are to be auto-connected out of the accountsToNotConnect set.
	 */
	AIAccount		*account;
	
	for (account in accounts) {
		BOOL	connectAccount = (!shiftHeld  &&
								  account.enabled &&
								  [[account preferenceForKey:KEY_AUTOCONNECT
													  group:GROUP_ACCOUNT_STATUS] boolValue]);

		if (account.enabled &&
			[account connectivityBasedOnNetworkReachability]) {
			NSString *host = ([account proxyType] == Adium_Proxy_Tor ? [account proxyHost] : [account host]);
			if (host && ![knownHosts containsObject:host]) {
				[monitor addObserver:self forHost:host];
				[knownHosts addObject:host];
			}
			
			//If this is an account we should auto-connect, remove it from accountsToNotConnect so that we auto-connect it.
			if (connectAccount) {
				[accountsToNotConnect removeObject:account];
				[account setValue:[NSNumber numberWithBool:YES] forProperty:@"isWaitingForNetwork" notify:NotifyNow];
				continue; //prevent the account from being removed from accountsToConnect.
			}
			
		}  else if (connectAccount) {
			/* This account does not connect based on network reachability, but should autoconnect.
			 * Connect it immediately.
			 */
			[account setShouldBeOnline:YES];
		}
		
		[accountsToConnect removeObject:account];
	}
	
	//Watch for future changes to our account list
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];
}

- (void)networkDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:AINetworkDidChangeNotification
											  object:nil];
}

/*!
 * @brief Network connectivity changed
 *
 * Connect or disconnect accounts as appropriate to the new network state.
 *
 * @param networkIsReachable Indicates whether the given host is now reachable.
 * @param host The host that is now reachable (or not).
 */
- (void)hostReachabilityChanged:(BOOL)networkIsReachable forHost:(NSString *)host
{
	//Connect or disconnect accounts in response to the connectivity change
	for (AIAccount *account in adium.accountController.accounts) {
		if (networkIsReachable && [accountsToNotConnect containsObject:account]) {
			[accountsToNotConnect removeObject:account];
		} else {
            NSString *accountHost = ([account proxyType] == Adium_Proxy_Tor ? [account proxyHost] : [account host]);
            
			if ([accountHost isEqualToString:host]) {
				[self handleConnectivityForAccount:account reachable:networkIsReachable];
			}
		}
	}
	
	//Collate reachability changes for multiple hosts into a single notification
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(networkDidChange)
											   object:nil];
	[self performSelector:@selector(networkDidChange) withObject:nil afterDelay:1.0];
}

#pragma mark AIHostReachabilityObserver compliance

- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host {
	[self hostReachabilityChanged:YES forHost:host];
}
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host {
	[self hostReachabilityChanged:NO forHost:host];
}

#pragma mark Connecting/Disconnecting Accounts
/*!
 * @brief Connect or disconnect an account as appropriate to a new network reachable state
 *
 * This method uses the accountsToConnect collection to track which accounts were disconnected and should therefore be
 * later reconnected.
 *
 * @param account The account to change if appropriate
 * @param reachable The new network reachable state
 */
- (void)handleConnectivityForAccount:(AIAccount *)account reachable:(BOOL)reachable
{
	AILog(@"handleConnectivityForAccount: %@ reachable: %i",account,reachable);

	if (reachable) {
		//If we are now online and are waiting to connect this account, do it if the account hasn't already
		//been taken care of.
		[account setValue:nil forProperty:@"isWaitingForNetwork" notify:NotifyNow];
		if ([accountsToConnect containsObject:account] ||
			[account valueForProperty:@"waitingToReconnect"]) {
			if (!account.online &&
				![account boolValueForProperty:@"isConnecting"]) {
				[account setShouldBeOnline:YES];
				[accountsToConnect removeObject:account];
			}
		}
	} else {
		//If we are no longer online and this account is connected, disconnect it.
		[account setValue:[NSNumber numberWithBool:YES] forProperty:@"isWaitingForNetwork" notify:NotifyNow];
		if ((account.online ||
			 [account boolValueForProperty:@"isConnecting"]) &&
			![account boolValueForProperty:@"isDisconnecting"]) {
			[account disconnectFromDroppedNetworkConnection];
			[accountsToConnect addObject:account];
		}
	}
}

//Disconnect / Reconnect on sleep --------------------------------------------------------------------------------------
#pragma mark Disconnect/Reconnect On Sleep
/*!
 * @brief System is sleeping
 */
- (void)systemWillSleep:(NSNotification *)notification
{
	AILog(@"***** System sleeping...");
	//Disconnect all online or connecting accounts
	if ([self _accountsAreOnlineOrDisconnecting:YES]) {
		for (AIAccount *account in adium.accountController.accounts) {
			if (account.online ||
				[account boolValueForProperty:@"isConnecting"] ||
				[account valueForProperty:@"waitingToReconnect"]) {

				// Disconnect the account if it's online
				if (account.online) {
					[account disconnect];
				// Cancel any reconnect attempts
				} else if ([account valueForProperty:@"waitingToReconnect"]) {
					[account cancelAutoReconnect];
				}
				// Add it to our list to reconnect
				[accountsToConnect addObject:account];
			}
		}
	}
		
	//While some accounts disconnect immediately, others may need a second or two to finish the process.  For
	//these accounts we'll want to hold system sleep until they are ready.  We monitor account status changes
	//and will lift the hold once all accounts are finished.
	//Don't delay sleep for connecting or reconnecting accounts
	if ([self _accountsAreOnlineOrDisconnecting:NO]) {
		AILog(@"Posting AISystemHoldSleep_Notification...");
		[[NSNotificationCenter defaultCenter] postNotificationName:AISystemHoldSleep_Notification object:nil];
		waitingToSleep = YES;
	}
}

/*!
 * @brief Invoked when our accounts change status
 *
 * Once all accounts are offline we will remove our hold on system sleep
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if (waitingToSleep &&
			[inModifiedKeys containsObject:@"isOnline"]) {
			//Don't delay sleep for connecting or reconnecting accounts
			if (![self _accountsAreOnlineOrDisconnecting:NO]) {
				AILog(@"Posting AISystemContinueSleep_Notification...");
				[[NSNotificationCenter defaultCenter] postNotificationName:AISystemContinueSleep_Notification object:nil];
				waitingToSleep = NO;

			} else {
				AILog(@"Continuing to wait to sleep...");
			}
		}
		if ([inModifiedKeys containsObject:@"Enabled"]) {
			AIAccount *account = (AIAccount *)inObject;

			if (account.enabled) {
				//Start observing for this host if we're not already
				if ([account connectivityBasedOnNetworkReachability]) {
					NSString *host = ([account proxyType] == Adium_Proxy_Tor ? [account proxyHost] : [account host]);
					AIHostReachabilityMonitor *monitor = [AIHostReachabilityMonitor defaultMonitor];
	
					[account setValue:[NSNumber numberWithBool:YES] forProperty:@"isWaitingForNetwork" notify:NotifyNow];
					if (host &&
						![monitor observer:self isObservingHost:host]) {
						[monitor addObserver:self forHost:host];
					}
				}
				
			} else {
				BOOL			enabledAccountUsingThisHost = NO;
				NSString		*thisHost = [account host];
				
				[account setValue:nil forProperty:@"isWaitingForNetwork" notify:NotifyNow];

				//Check if any enabled accounts are still using this now-disabled account's host
				for (AIAccount *loopAccount in adium.accountController.accounts) {
					if (loopAccount.enabled && loopAccount.connectivityBasedOnNetworkReachability) {
						if ([thisHost caseInsensitiveCompare:loopAccount.host] == NSOrderedSame) {
							enabledAccountUsingThisHost = YES;
							break;
						}
					}
				}

				//If not, stop observing it entirely
				if (!enabledAccountUsingThisHost) {
					AIHostReachabilityMonitor *monitor = [AIHostReachabilityMonitor defaultMonitor];
					[monitor removeObserver:self forHost:thisHost];
				}
			}
		}
	}

	return nil;
}

/*!
 * @brief Returns YES if any accounts are currently in the process of disconnecting
 *
 * @param considerConnecting Consider accounts which are connecting or waiting to reconnect
 */
- (BOOL)_accountsAreOnlineOrDisconnecting:(BOOL)considerConnecting
{
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online ||
		   [account boolValueForProperty:@"isDisconnecting"]) {
			AILog(@"%@ (and possibly others) is still %@",account, (account.online ? @"online" : @"disconnecting"));
			return YES;
		} else if (considerConnecting &&
				   ([account boolValueForProperty:@"isConnecting"] ||
					[account valueForProperty:@"waitingToReconnect"])) {
			return YES;
		}
	}
	
	return NO;
}

/*!
 * @brief System is waking from sleep
 */
- (void)systemDidWake:(NSNotification *)notification
{
	AILog(@"***** System did wake...");

	/* We could have been waiting to sleep but then timed out and slept anyways; clear the flag if that happened and it wasn't cleared
	 * in updateListObject::: above.
	 */
	waitingToSleep = NO;

	//Immediately re-connect accounts which are ignoring the server reachability
	for (AIAccount *account in adium.accountController.accounts) {
		if (![account connectivityBasedOnNetworkReachability] && [accountsToConnect containsObject:account]) {
			[account setShouldBeOnline:YES];
			[accountsToConnect removeObject:account];
		} else if ([accountsToConnect containsObject:account]) {
			[account setValue:[NSNumber numberWithBool:YES] forProperty:@"isWaitingForNetwork" notify:NotifyNow];
		}
	}
}

#pragma mark Changes to the account list
/*!
 * @brief When the account list changes, ensure we're monitoring for each account
 */
- (void)accountListChanged:(NSNotification *)notification
{
	AIHostReachabilityMonitor	*monitor = [AIHostReachabilityMonitor defaultMonitor];

	//Immediately re-connect accounts which are ignoring the server reachability
	for (AIAccount *account in adium.accountController.accounts) {
		if (account.enabled &&
			[account connectivityBasedOnNetworkReachability]) {
			NSString *host = ([account proxyType] == Adium_Proxy_Tor ? [account proxyHost] : [account host]);
			
			if (host &&
				![monitor observer:self isObservingHost:host]) {
				[monitor addObserver:self forHost:host];
			}
		}
	}
}

@end
