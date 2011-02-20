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

#import "ESStatusPreferencesPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "ESStatusPreferences.h"
#import <Adium/AIMenuControllerProtocol.h>
#import "AIStatusController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define	STATUS_DEFAULT_PREFS @"StatusDefaults"

@interface ESStatusPreferencesPlugin ()
- (void)showStatusPreferences:(id)sender;
@end

/*!
 * @class ESStatusPreferencesPlugin
 * @brief Component to install our status preferences pane
 */
@implementation ESStatusPreferencesPlugin

/*!
 * @brief Install
 *
 * Install our preference pane, and add a menu item to the Status menu which opens it.
 */
- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	//Install our preference view
    preferences = [[ESStatusPreferences preferencePaneForPlugin:self] retain];
	advancedPreferences = [[ESStatusAdvancedPreferences preferencePaneForPlugin:self] retain];

	//Add our menu item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Status Menu",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(showStatusPreferences:)
															  keyEquivalent:@""] autorelease];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Status_Additions];
	
	//Register defaults
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:STATUS_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_STATUS_PREFERENCES];	
	
}

/*!
 * Open the preferences to the status pane
 */
- (void)showStatusPreferences:(id)sender
{
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Status"];
}

@end
