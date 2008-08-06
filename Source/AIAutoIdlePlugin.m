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

#import "AIAutoIdlePlugin.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIStatusController.h"
#import <Adium/AIAccount.h>

/*!
 * @class AIAutoIdlePlugin
 * @brief Provides auto-idle functionality for the state system
 *
 * This class implements auto-idling.  When the user is inactive for a period of time, the idle status flag is set
 * for all accounts.  Once the user returns this flag is removed.  This plugin works independently of the state
 * system, so this automatic idle flag won't interfere with the currently active state.
 */
@implementation AIAutoIdlePlugin

/*!
 * @brief Initialize the auto-idle system
 *
 * When AIMachineIdleUpdateNotification is posted, check the time idle against the time at which to report that we
 * are idle (as specified by the user in the preferences).  When AIMachineIsActiveNotification, return us from idle
 * if we reported as idle previously.
 */
- (void)installPlugin
{
	automaticIdleSet = NO;

	//Ensure no idle time is set as we load
	[[adium preferenceController] setPreference:nil
										 forKey:@"IdleSince"
										  group:GROUP_ACCOUNT_STATUS];

	NSNotificationCenter *adiumNotificationCenter = [adium notificationCenter];
	[adiumNotificationCenter addObserver:self
	                            selector:@selector(machineIdleUpdate:)
	                                name:AIMachineIdleUpdateNotification
	                              object:nil];
	[adiumNotificationCenter addObserver:self
	                            selector:@selector(machineIsActive:)
	                                name:AIMachineIsActiveNotification
	                              object:nil];

	//Observe preference changes for updating if and when we should report being idle
	[[adium preferenceController] registerPreferenceObserver:self 
													forGroup:PREF_GROUP_STATUS_PREFERENCES];	
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Preferences changed
 *
 * Note whether we are supposed to report idle time, and, if so, after how much time.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	reportIdleTime = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE] boolValue];
	idleTimeInterval = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue];	
}

/*!
 * @brief Invoked when machine idle updates
 *
 * Invoked when Adium has an update on machine activity.  If we are not yet idle, and the current length of inactivity
 * is over the threshold, set our accounts to idle status.
 */
- (void)machineIdleUpdate:(NSNotification *)notification
{
	if (!automaticIdleSet && reportIdleTime) {
		double	duration = [[[notification userInfo] objectForKey:@"Duration"] doubleValue];
		
		if (duration > idleTimeInterval) {
			//If we are over the idle threshold, set our accounts to idle
			automaticIdleSet = YES;
			[[adium preferenceController] setPreference:[[notification userInfo] objectForKey:@"IdleSince"]
												 forKey:@"IdleSince"
												  group:GROUP_ACCOUNT_STATUS];
		}
	}
}

/*!
 * @brief Invoked when machine becomes active
 *
 * Invoked when Adium has an update on machine activity.  If we are currently idle, set our accounts back to active.
 */
- (void)machineIsActive:(NSNotification *)notification
{
	if (automaticIdleSet) {
		[[adium preferenceController] setPreference:nil
											 forKey:@"IdleSince"
											  group:GROUP_ACCOUNT_STATUS];		
		automaticIdleSet = NO;
	}
}

@end
