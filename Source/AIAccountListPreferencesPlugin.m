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

#import "AIAccountListPreferencesPlugin.h"
#import "AIAccountListPreferences.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>

/*!
 * @class AIAccountListPreferencesPlugin
 * @brief Manages the accounts configuration preferences
 */
@implementation AIAccountListPreferencesPlugin

/*!
 * @brief Install the plugin
 */
- (void)installPlugin
{
	accountListPreferences = [(AIAccountListPreferences *)[AIAccountListPreferences preferencePaneForPlugin:self] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(editAccount:)
									   name:@"AIEditAccount"
									 object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[accountListPreferences release];

	[super dealloc];
}

/*!
 * @brief Edit an account
 *
 * @param inNotification An AIEditAccount notification whose object is the AIAccount to edit
 */
- (void)editAccount:(NSNotification *)inNotification
{
	AIAccount	*account = [inNotification object];
	
	//Open the preferences to the accounts pane
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Accounts"];

	//Then edit the account
	[accountListPreferences editAccount:account];
}

@end
