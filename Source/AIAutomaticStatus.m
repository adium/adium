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
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusGroup.h>

typedef enum {
	AIAwayIdle = (1 << 1),
	AIAwayScreenSaved = (1 << 2),
	AIAwayScreenLocked = (1 << 3),
	AIAwayFastUserSwitched = (1 << 4)
} AIAwayAutomaticType;

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
 *  - Screen(saver|lock) activation
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
									   forKey:@"idleSince"
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
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIScreenLockDidStartNotification
							 object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIScreenLockDidStopNotification
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
	if (automaticStatusBitMap != 0) {
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
	[idleStatusID release];
	
	[oldStatusID release];
	
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
	[idleStatusID release];
	idleStatusID = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID] retain];
	idleStatusEnabled = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY] boolValue];
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
 * If this event changes one of the automatic statusses, the user is set again
 * to the highest priority automatic away status, or if none, returns from autoaway.
 *
 * Priorities: Fast User Switch'ed > Screen(saver|lock) > Idle.
 */
- (void)notificationHandler:(NSNotification *)notification
{
	NSString	*notificationName = [notification name];
	unsigned	oldBitMap = automaticStatusBitMap;
	
	// Start events
	if ([notificationName isEqualToString:NSWorkspaceSessionDidResignActiveNotification]) {
		AILogWithSignature(@"Fast user switch (start) detected");
		
		if (fastUserSwitchEnabled) automaticStatusBitMap |= AIAwayFastUserSwitched;
		
	} else if ([notificationName isEqualToString:AIScreensaverDidStartNotification]) {
		AILogWithSignature(@"Screensaver (start) detected.");
		
		if (screenSaverEnabled) automaticStatusBitMap |= AIAwayScreenSaved;
		
	} else if ([notificationName isEqualToString:AIMachineIdleUpdateNotification]) {
		double duration = [[[notification userInfo] objectForKey:@"Duration"] doubleValue];
		
		if (reportIdleEnabled && duration >= idleReportInterval) {
			NSDate *idleSince = [[notification userInfo] objectForKey:@"idleSince"];
			
			
			if ((NSInteger)[[adium.preferenceController preferenceForKey:@"idleSince"
																   group:GROUP_ACCOUNT_STATUS] timeIntervalSince1970] !=
				(NSInteger)[idleSince timeIntervalSince1970]) {
				
				AILogWithSignature(@"Idle (start) detected. %@ -> %@", [adium.preferenceController preferenceForKey:@"idleSince"
																											  group:GROUP_ACCOUNT_STATUS], idleSince);
				
				// Update our idle time
				[adium.preferenceController setPreference:[[notification userInfo] objectForKey:@"idleSince"]
												   forKey:@"idleSince"
													group:GROUP_ACCOUNT_STATUS];
			}
		}
		
		if (idleStatusEnabled && duration >= idleStatusInterval && !(automaticStatusBitMap & AIAwayIdle)) {
			
			AILogWithSignature(@"Auto-away (start) detected.");

			automaticStatusBitMap |= AIAwayIdle;
		}
		
	} if ([notificationName isEqualToString:AIScreenLockDidStartNotification]) {
		AILogWithSignature(@"Screenlock (start) detected.");
		
		if (screenSaverEnabled) automaticStatusBitMap |= AIAwayScreenLocked;
	}
	
	// End events
	if ([notificationName isEqualToString:NSWorkspaceSessionDidBecomeActiveNotification]) {
		AILogWithSignature(@"Fast user switch (end) detected.");
		
		automaticStatusBitMap &= ~AIAwayFastUserSwitched;
		
	} else if ([notificationName isEqualToString:AIScreensaverDidStopNotification]) {
		AILogWithSignature(@"Screensaver (end) detected.");

		automaticStatusBitMap &= ~AIAwayScreenSaved;
		
	} else if ([notificationName isEqualToString:AIMachineIsActiveNotification]) {
		
		if (automaticStatusBitMap & AIAwayIdle) {
			AILogWithSignature(@"Auto-away (end) detected.");
			
			automaticStatusBitMap &= ~AIAwayIdle;
		}
		
		if (reportIdleEnabled) {
			AILogWithSignature(@"Idle (end) detected.");
			[adium.preferenceController setPreference:nil
											   forKey:@"idleSince"
												group:GROUP_ACCOUNT_STATUS];
		}
		
	} else if ([notificationName isEqualToString:AIScreenLockDidStopNotification]) {
		AILogWithSignature(@"Screenlock (end) detected.");
		
		automaticStatusBitMap &= ~AIAwayScreenLocked;
	}
	
	// Check if a change in status is required: if so, look for the one with the highest priority
	if (oldBitMap != automaticStatusBitMap) {
		NSNumber *statusID = nil;
		
		if (automaticStatusBitMap & AIAwayFastUserSwitched)
			statusID = fastUserSwitchID;

		else if ((automaticStatusBitMap & AIAwayScreenLocked)
				 || (automaticStatusBitMap & AIAwayScreenSaved))
			statusID = screenSaverID;
			
		else if (automaticStatusBitMap & AIAwayIdle)	
			statusID = idleStatusID;
			
		else
			[self returnFromAutoAway];
		
		if (statusID)
			[self triggerAutoAwayWithStatusID:statusID];
	}
	
}

/*!
 * @brief Automatically set an account as away
 *
 * @param statusID The status ID to change account status to
 *
 * Sets all available accounts to the status type statusID, while storing the old one if necessary
 */
- (void)triggerAutoAwayWithStatusID:(NSNumber *)statusID
{
	AIStatusItem *targetStatusState = [adium.statusController statusStateWithUniqueStatusID:statusID];
	
	// Grab any group member if possible
	if ([targetStatusState isKindOfClass:[AIStatusGroup class]]) {
		targetStatusState = [(AIStatusGroup *)targetStatusState anyContainedStatus];
	}
	
	// If we weren't given a valid and new state, fail.
	if (!targetStatusState || [oldStatusID isEqualToNumber:statusID]) {
		return;
	}
	
	for (AIAccount *account in adium.accountController.accounts) {
		AIStatus	*currentStatusState = account.statusState;
		
		// Store the state of the account if there is no previous one saved
		if (![previousStatus objectForKey:[account internalObjectID]]) {
			
			// Don't modify or store the status of (originally!) non-available accounts
			if (currentStatusState.statusType != AIAvailableStatusType) {
				continue;
			}
			
			[previousStatus setObject:currentStatusState
							   forKey:[account internalObjectID]];
		}
		
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
	
	[oldStatusID release];
	oldStatusID = [statusID retain];
}

/*!
 * @brief Return from automatic away
 *
 * Returns all accounts with stored status information to their previous status.
 */
- (void)returnFromAutoAway
{
	for (AIAccount *account in adium.accountController.accounts) {
		AIStatus *previousStatusState = [previousStatus objectForKey:[account internalObjectID]];
		
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
	
	automaticStatusBitMap = 0;
	
	[oldStatusID release];
	oldStatusID = nil;
}

@end
