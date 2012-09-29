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

#import "CBStatusMenuItemPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@interface CBStatusMenuItemPlugin()
- (void)adiumFinishedLaunching:(NSNotification *)notification;
@end


@implementation CBStatusMenuItemPlugin

- (void)installPlugin
{
	itemController = nil;

	//Register our defaults
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:STATUS_MENU_ITEM_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_STATUS_MENU_ITEM];

	//Wait for Adium to finish launching before we perform further actions
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Observe for preference changes, initially loading our status menu item controller
	[adium.preferenceController registerPreferenceObserver:self
													forGroup:PREF_GROUP_STATUS_MENU_ITEM];
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:AIApplicationDidFinishLoadingNotification
										object:nil];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[itemController release]; itemController = nil;
}

- (void)preferencesChangedForGroup:(NSString *)group
							   key:(NSString *)key
							object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict
						 firstTime:(BOOL)firstTime
{
	if ([[prefDict objectForKey:KEY_STATUS_MENU_ITEM_ENABLED] boolValue]) {
		//If it hasn't been created yet, create it. It will be created visible.
		if (!itemController) {
			itemController = [[CBStatusMenuItemController statusMenuItemController] retain];
		}		
	} else {
		// NSTimer retains its target, so we need to invalidate any timers the controller has going on.
		[itemController invalidateTimers];
		[itemController autorelease]; itemController = nil;
	}
}

@end
