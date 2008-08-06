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
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AISoundController.h"
#import "AIStatusController.h"
#import "ESFastUserSwitchingSupportPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIStatusGroup.h>

@interface ESFastUserSwitchingSupportPlugin (PRIVATE)
-(void)switchHandler:(NSNotification*) notification;
@end

/*!
 * @class ESFastUserSwitchingSupportPlugin
 * @brief Handle Fast User Switching and Screen Savers with a changed status and sound muting
 *
 * When the Screen Saver activates, or another user logs in via Fast User Switching (OS X 10.3 and above),
 * this plugin sets a status state if an away state is not already set.
 */
@implementation ESFastUserSwitchingSupportPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[workspaceCenter addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:NSWorkspaceSessionDidBecomeActiveNotification
	                      object:nil];

	[workspaceCenter addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:NSWorkspaceSessionDidResignActiveNotification
	                      object:nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:@"com.apple.screensaver.didstart"
	                      object:nil];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:@"com.apple.screensaver.didstop"
	                      object:nil];

	//Observe preference changes for updating when and how we should automatically change our state
	[[adium preferenceController] registerPreferenceObserver:self
														forGroup:PREF_GROUP_STATUS_PREFERENCES];
}

/*!
 * @brief Preferences changed
 *
 * Note whether we are supposed to change states on FUS or SS.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[fastUserSwitchStatusID release];
	fastUserSwitchStatusID = [[prefDict objectForKey:KEY_STATUS_FUS_STATUS_STATE_ID] retain];
	[screenSaverStatusID release];
	screenSaverStatusID    = [[prefDict objectForKey:KEY_STATUS_SS_STATUS_STATE_ID] retain];
	
	fastUserSwitchStatus = [[prefDict objectForKey:KEY_STATUS_FUS] boolValue];
	screenSaverStatus = [[prefDict objectForKey:KEY_STATUS_SS] boolValue];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	//Clear the fast switch away if we had it up before
	[self switchHandler:nil];

	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[previousStatusStateDict release];
	[accountsToReconnect release];
	
	[fastUserSwitchStatusID release];
	[screenSaverStatusID release];

	[super dealloc];
}

/*!
 * @brief Handle a fast user switch or screen saver event
 *
 * Calling this with (notification == nil) is the same as when the user switches back.
 *
 * @param notification The notification has a name NSWorkspaceSessionDidResignActiveNotification when the user switches away and NSWorkspaceSessionDidBecomeActiveNotification when the user switches back.
 */
-(void)switchHandler:(NSNotification*) notification
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (notification &&
		(([[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification] && fastUserSwitchStatus) ||
			([[notification name] isEqualToString:@"com.apple.screensaver.didstart"] && screenSaverStatus))) {
		//Deactivation - go away
		//Go away if we aren't already away, noting the current status states for restoration later
		NSEnumerator	*enumerator;
		AIAccount		*account;
		AIStatusItem	*targetStatusState;

		if (!previousStatusStateDict) previousStatusStateDict = [[NSMutableDictionary alloc] init];

		if ([[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification])
			targetStatusState = [[adium statusController] statusStateWithUniqueStatusID:fastUserSwitchStatusID];
		else
			targetStatusState = [[adium statusController] statusStateWithUniqueStatusID:screenSaverStatusID];
		
		if ([targetStatusState isKindOfClass:[AIStatusGroup class]]) {
			targetStatusState = [(AIStatusGroup *)targetStatusState anyContainedStatus];
		}
		
		if (targetStatusState) {
			enumerator = [[[adium accountController] accounts] objectEnumerator];
			while ((account = [enumerator nextObject])) {
				AIStatus	*currentStatusState = [account statusState];
				if ([currentStatusState statusType] == AIAvailableStatusType) {
					//Store the state the account is in at present
					[previousStatusStateDict setObject:currentStatusState
												forKey:[NSNumber numberWithUnsignedInt:[account hash]]];

					if ([account online]) {
						//If online, set the state
						[account setStatusState:(AIStatus *)targetStatusState];
						
						//If we just brought the account offline, note that it will need to be reconnected later
						if ([targetStatusState statusType] == AIOfflineStatusType) {
							if (!accountsToReconnect) accountsToReconnect = [[NSMutableSet alloc] init];
							[accountsToReconnect addObject:account];
						}
					} else {
						//If offline, set the state without coming online
						[account setStatusStateAndRemainOffline:(AIStatus *)targetStatusState];
					}
				}
			}
		}

	} else if (!notification ||
			   (([[notification name] isEqualToString:NSWorkspaceSessionDidBecomeActiveNotification] && fastUserSwitchStatus) ||
				([[notification name] isEqualToString:@"com.apple.screensaver.didstop"] && screenSaverStatus))) {
		//Activation - return from away

		//Remove the away status flag if we set it originally
		NSEnumerator	*enumerator;
		AIAccount		*account;

		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			AIStatus		*targetStatusState;
			NSNumber		*accountHash = [NSNumber numberWithUnsignedInt:[account hash]];

			targetStatusState = [previousStatusStateDict objectForKey:accountHash];
			if (targetStatusState) {
				if ([account online] || [accountsToReconnect containsObject:account]) {
					//If online or needs to be reconnected, set the previous state, going online if necessary
					[account setStatusState:targetStatusState];
				} else {
					//If offline, set the state without coming online
					[account setStatusStateAndRemainOffline:targetStatusState];
				}
			}
		}

		[previousStatusStateDict release]; previousStatusStateDict = nil;
		[accountsToReconnect release]; accountsToReconnect = nil;
	}
	
	[pool release];
}

@end
