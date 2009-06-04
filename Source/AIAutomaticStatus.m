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

#import "AIAutomaticStatus.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusGroup.h>

@interface AIAutomaticStatus ()
- (void)notificationHandler:(NSNotification *)notification;
- (void)triggerAutoAwayWithStatusID:(NSNumber *)statusID;
- (void)returnFromAutoAway;
@end

/*!
 * @class AIAutomaticStatus
 *
 * Automatically set accounts to certain statuses when events occur. Currently this handles:
 *  - Fast user switching
 *  - Screensaver activation
 *  - Idle time
 */
@implementation AIAutomaticStatus

/*!
 * @brief Initialize the automatic status system
 */
- (void)installPlugin
{
	// Ensure no idle time is set as we load
	[adium.preferenceController setPreference:nil
									   forKey:@"IdleSince"
										group:GROUP_ACCOUNT_STATUS];
	
	// Initialize our state information
	accountsToReconnect = [[NSMutableSet alloc] init];
	previousStatus = [[NSMutableDictionary alloc] init];
	
	// Register our notifications
	NSNotificationCenter *notificationCenter;
	
	// FUS events are on the sharedWorkspace's notificationCenter
	notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:NSWorkspaceSessionDidBecomeActiveNotification
							 object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:NSWorkspaceSessionDidResignActiveNotification
							 object:nil];
	
	// Screensaver events are distributed notification events
	notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIScreensaverDidStartNotification
							 object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIScreensaverDidStopNotification
							 object:nil];
	
	// Idle events are in the Adium notification center, posted by the AdiumIdleManager
	notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIMachineIdleUpdateNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIMachineIsActiveNotification
							 object:nil];

	// Register for status preference updates
	[adium.preferenceController registerPreferenceObserver:self
												  forGroup:PREF_GROUP_STATUS_PREFERENCES];

}

/*!
 * @brief Uninstall plugin
 *
 * When the plugin is uninstalled, we revert to whatever status we were previously set to.
 */
- (void)uninstallPlugin
{
	// Unregister our notifications
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Unregister our preference observations
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	// Revert to our stored statuses
	if (automaticStatusSet) {
		[self returnFromAutoAway];
	}
}

/*!
 * Deallocate
 */
- (void)dealloc
{
	// State information
	[accountsToReconnect release]; 
	[previousStatus release];
	
	// Stored status IDs
	[fastUserSwitchID release];
	[screenSaverID release];
	[idleID release];
	
	[super dealloc];
}

/*!
 * @brief Preferences changed
 *
 * Note the status IDs, interval information, and enabled information for our preferences
 */
- (void)preferencesChangedForGroup:(NSString *)group
							   key:(NSString *)key
							object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict
						 firstTime:(BOOL)firstTime
{
	if (object) {
		return;
	}

	// Idle reporting
	reportIdleEnabled = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE] boolValue];
	idleReportInterval = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue];
	
	// Idle status change
	[idleID release];
	idleID = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID] retain];
	idleEnabled = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY] boolValue];
	idleStatusInterval = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_INTERVAL] doubleValue];
	
	// Fast user switch
	[fastUserSwitchID release];
	fastUserSwitchID = [[prefDict objectForKey:KEY_STATUS_FUS_STATUS_STATE_ID] retain];
	fastUserSwitchEnabled = [[prefDict objectForKey:KEY_STATUS_FUS] boolValue];
	
	// Screensaver
	[screenSaverID release];
	screenSaverID = [[prefDict objectForKey:KEY_STATUS_SS_STATUS_STATE_ID] retain];
	screenSaverEnabled = [[prefDict objectForKey:KEY_STATUS_SS] boolValue];
}

/*!
 * @brief Handle a notification
 *
 * @param notification The notification to process
 *
 * When a notification comes in, this checks if it's a start or end event
 *
 * A start event will set the status, and the end will revert to the previous status.
 */
- (void)notificationHandler:(NSNotification *)notification
{
	NSString	*notificationName = [notification name];
	NSNumber	*statusID = nil;
	BOOL		startEvent = NO, endEvent = NO;
	
	// Start events
	if ([notificationName isEqualToString:NSWorkspaceSessionDidResignActiveNotification]) {
		AILogWithSignature(@"Fast user switch (start) detected");

		startEvent = fastUserSwitchEnabled;
		statusID = fastUserSwitchID;
	} else if ([notificationName isEqualToString:AIScreensaverDidStartNotification]) {
		AILogWithSignature(@"Screensaver (start) detected.");
		
		startEvent = screenSaverEnabled;
		statusID = screenSaverID;
	} else if ([notificationName isEqualToString:AIMachineIdleUpdateNotification]) {
		double duration = [[[notification userInfo] objectForKey:@"Duration"] doubleValue];
		
		// Update our idle time
		if (!automaticIdleSet && reportIdleEnabled && duration >= idleReportInterval) {
			AILogWithSignature(@"Idle (report) detected.");
			
			automaticIdleSet = YES;
			
			[adium.preferenceController setPreference:[[notification userInfo] objectForKey:@"IdleSince"]
											   forKey:@"IdleSince"
												group:GROUP_ACCOUNT_STATUS];
		}
		
		// Idle events require that we've been idle longer than required
		startEvent = (idleEnabled && duration >= idleStatusInterval);
		statusID = idleID;

		// This is very spammy when we're already idle.
		if (startEvent && !automaticStatusSet) {
			AILogWithSignature(@"Idle (start) detected.");
		}
	}
	
	// End events
	if ([notificationName isEqualToString:NSWorkspaceSessionDidBecomeActiveNotification]) {
		AILogWithSignature(@"Fast user switch (end) detected.");
		
		endEvent = fastUserSwitchEnabled;
	} else if ([notificationName isEqualToString:AIScreensaverDidStopNotification]) {
		AILogWithSignature(@"Screensaver (end) detected.");
		
		endEvent = screenSaverEnabled;
	} else if ([notificationName isEqualToString:AIMachineIsActiveNotification]) {
		AILogWithSignature(@"Idle (end) detected.");
		
		if (automaticIdleSet) {	
			automaticIdleSet = NO;
			
			[adium.preferenceController setPreference:nil
											   forKey:@"IdleSince"
											     group:GROUP_ACCOUNT_STATUS];
		}
		
		endEvent = idleEnabled;
	}
	
	if (startEvent && statusID && !automaticStatusSet) {
		[self triggerAutoAwayWithStatusID:statusID];
	} else if (endEvent && automaticStatusSet) {
		[self returnFromAutoAway];
	}
	
}

/*!
 * @brief Automatically set an account as away
 *
 * @param statusID The status ID to change account status to
 *
 * Sets all available accounts to the status type statusID, while storing the
 */
- (void)triggerAutoAwayWithStatusID:(NSNumber *)statusID
{
	AIStatusItem *targetStatusState = [adium.statusController statusStateWithUniqueStatusID:statusID];
	
	// Grab any group memeber if possible
	if ([targetStatusState isKindOfClass:[AIStatusGroup class]]) {
		targetStatusState = [(AIStatusGroup *)targetStatusState anyContainedStatus];
	}
	
	// If we weren't given a valid state, fail.
	if (!targetStatusState) {
		return;
	}
	
	for (AIAccount *account in adium.accountController.accounts) {
		AIStatus	*currentStatusState = account.statusState;
		
		// Don't modify or store the status of non-available accounts
		if (currentStatusState.statusType != AIAvailableStatusType) {
			continue;
		}
		
		// Store the state of the account
		[previousStatus setObject:currentStatusState
						   forKey:[NSNumber numberWithUnsignedInt:[account hash]]];
		
		AILogWithSignature(@"Setting %@ to status %@", account, targetStatusState);
		
		if (account.online) {
			// Set the account's status to our new value
			[account setStatusState:(AIStatus *)targetStatusState];
			
			// If this status brought the account offline, add it to the list to reconnect.
			if (targetStatusState.statusType == AIOfflineStatusType) {
				[accountsToReconnect addObject:account];
			}
		} else {
			[account setStatusStateAndRemainOffline:(AIStatus *)targetStatusState];
		}
	}
	
	automaticStatusSet = YES;
}

/*!
 * @brief Return from automatic away
 *
 * Returns all accounts with stored status information to their previous status.
 */
- (void)returnFromAutoAway
{
	for (AIAccount *account in adium.accountController.accounts) {
		AIStatus *previousStatusState = [previousStatus objectForKey:[NSNumber numberWithUnsignedInt:[account hash]]];
		
		// Skip accounts without stored information.
		if (!previousStatusState) {
			continue;
		}
		
		AILogWithSignature(@"Returning %@ to status %@", account, previousStatusState);

		if (account.online || [accountsToReconnect containsObject:account]) {
			//If online or needs to be reconnected, set the previous state, going online if necessary
			[account setStatusState:previousStatusState];
		} else {
			//If offline, set the state without coming online
			[account setStatusStateAndRemainOffline:previousStatusState];
		}
	}
	
	[accountsToReconnect removeAllObjects];
	[previousStatus removeAllObjects];
	
	automaticStatusSet = NO;
}

@end
