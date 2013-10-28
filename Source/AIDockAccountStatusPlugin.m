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

#import "AIDockAccountStatusPlugin.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccount.h>

@interface AIDockAccountStatusPlugin ()
- (BOOL)_accountsWithBoolProperty:(NSString *)inKey;
- (BOOL)_accountsWithProperty:(NSString *)inKey;
@end

/*!
 * @class AIDockAccountStatusPlugin
 * @brief Maintain the dock icon state in relation to global account status
 *
 * This class manages the dock icon state via the dockController.  It specifies the icon which should be shown based
 * on an aggregated, global account status.
 */
@implementation AIDockAccountStatusPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	//Observe account status changes
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];

    //Observer preference changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
    //Remove observers
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Handle preference changes
 *
 * When the active dock icon changes, call updateListObject:keys:silent: to update its state to the global account state
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!key || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]) {
		[self updateListObject:nil keys:nil silent:NO];
	}
}

/*!
 * @brief Update the dock icon state in response to an account changing status
 *
 * If one or more accounts are online, set the Online icon state.  Similarly, handle the Connecting, Away, and Idle
 * dock icon states.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inObject == nil || [inObject isKindOfClass:[AIAccount class]]) {
		id<AIDockController>	dockController = adium.dockController;
		BOOL					shouldUpdateStatus = NO;
		
		if (inObject == nil || [inModifiedKeys containsObject:@"isOnline"]) {
			if ([self _accountsWithBoolProperty:@"isOnline"]) {
				[dockController setIconStateNamed:@"Online"];
			} else {
				[dockController removeIconStateNamed:@"Online"];
			}
			shouldUpdateStatus = YES;
		}

		if (inObject == nil || ([inModifiedKeys containsObject:@"isConnecting"] || [inModifiedKeys containsObject:@"waitingToReconnect"])) {
			if ([self _accountsWithBoolProperty:@"isConnecting"] || [self _accountsWithProperty:@"waitingToReconnect"]) {
				[dockController setIconStateNamed:@"Connecting"];
			} else {
				[dockController removeIconStateNamed:@"Connecting"];
			}
			shouldUpdateStatus = YES;
		}
		
		if (inObject == nil || [inModifiedKeys containsObject:@"idleSince"]) {
			if ([self _accountsWithProperty:@"idleSince"]) {
				[dockController setIconStateNamed:@"Idle"];
			} else {
				[dockController removeIconStateNamed:@"Idle"];
			}	
		}
		
		if (shouldUpdateStatus || [inModifiedKeys containsObject:@"accountStatus"]) {
			BOOL			iconSupportsInvisible = [adium.dockController currentIconSupportsIconStateNamed:@"Invisible"];
			AIStatusType	activeStatusType = [adium.statusController activeStatusTypeTreatingInvisibleAsAway:!iconSupportsInvisible];

			if (activeStatusType == AIAwayStatusType) {
				[dockController setIconStateNamed:@"Away"];
			} else {
				[dockController removeIconStateNamed:@"Away"];
			}

			if (activeStatusType == AIInvisibleStatusType) {
				[dockController setIconStateNamed:@"Invisible"];
			} else {
				[dockController removeIconStateNamed:@"Invisible"];
			}
		}
	}

	return nil;
}

/*!
 * @brief Return if any accounts have a TRUE value for the specified property
 *
 * @param inKey The property for which to search
 * @result YES if any account returns TRUE for the boolean property for inKey
 */
- (BOOL)_accountsWithBoolProperty:(NSString *)inKey
{
	for (AIAccount *account in adium.accountController.accounts) {
		if ([account boolValueForProperty:inKey] && account.enabled) return YES;
    }

    return NO;
}

/*!
 * @brief Return if any accounts have a non-nil value for the specified property
 *
 * @param inKey The property for which to search
 * @result YES if any account returns a non-nil value for the property for inKey
 */
- (BOOL)_accountsWithProperty:(NSString *)inKey
{
	for (AIAccount *account in adium.accountController.accounts) {
		if ([account valueForProperty:inKey] && account.enabled) return YES;
    }

    return NO;
}

@end
