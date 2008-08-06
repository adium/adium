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

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "AIOfflineContactHidingPlugin.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import "AIContactController.h"

#define SHOW_CONTACTS_MENU_TITLE		AILocalizedString(@"Show All Contacts",nil)
#define HIDE_CONTACTS_MENU_TITLE		AILocalizedString(@"Hide Certain Contacts",nil)
#define SHOW_OFFLINE_MENU_TITLE			AILocalizedString(@"Show Offline Contacts",nil)
#define HIDE_OFFLINE_MENU_TITLE			AILocalizedString(@"Hide Offline Contacts",nil)
#define SHOW_IDLE_MENU_TITLE			AILocalizedString(@"Show Idle Contacts",nil)
#define HIDE_IDLE_MENU_TITLE			AILocalizedString(@"Hide Idle Contacts",nil)
#define SHOW_MOBILE_MENU_TITLE			AILocalizedString(@"Show Mobile Contacts",nil)
#define HIDE_MOBILE_MENU_TITLE			AILocalizedString(@"Hide Mobile Contacts",nil)
#define SHOW_BLOCKED_MENU_TITLE			AILocalizedString(@"Show Blocked Contacts",nil)
#define HIDE_BLOCKED_MENU_TITLE			AILocalizedString(@"Hide Blocked Contacts",nil)
#define	SHOW_OFFLINE_GROUP_MENU_TITLE	AILocalizedString(@"Show Offline Group",nil)
#define	HIDE_OFFLINE_GROUP_MENU_TITLE	AILocalizedString(@"Hide Offline Group",nil)

#define OFFLINE_CONTACTS_IDENTIFER		@"OfflineContacts"

/*!
 * @class AIOfflineContactHidingPlugin
 * @brief Component to handle showing or hiding offline contacts and hiding empty groups.
 *
 * Only manages menu items and preferences. The actaual hiding is done by AIContactHidingController
 */
@implementation AIOfflineContactHidingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{	
	//Default preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:@"OfflineContactHidingDefaults" forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

	//"Hide Contacts" menu item
	menuItem_hideContacts = [[NSMenuItem alloc] initWithTitle:HIDE_CONTACTS_MENU_TITLE
													   target:self
													   action:@selector(toggleHide:)
												keyEquivalent:@"H"];
	[[adium menuController] addMenuItem:menuItem_hideContacts toLocation:LOC_View_Toggles];

	//Show offline contacts menu item
    menuItem_hideOffline = [[NSMenuItem alloc] initWithTitle:HIDE_OFFLINE_MENU_TITLE
													  target:self
													  action:@selector(toggleHide:)
											   keyEquivalent:@""];
	[menuItem_hideOffline setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideOffline toLocation:LOC_View_Toggles];

    menuItem_hideIdle = [[NSMenuItem alloc] initWithTitle:HIDE_IDLE_MENU_TITLE
												   target:self
												   action:@selector(toggleHide:)
											keyEquivalent:@""];
	[menuItem_hideIdle setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideIdle toLocation:LOC_View_Toggles];

    menuItem_hideMobile = [[NSMenuItem alloc] initWithTitle:HIDE_MOBILE_MENU_TITLE
													 target:self
													 action:@selector(toggleHide:)
											  keyEquivalent:@""];
	[menuItem_hideMobile setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideMobile toLocation:LOC_View_Toggles];

	menuItem_hideBlocked = [[NSMenuItem alloc] initWithTitle:HIDE_BLOCKED_MENU_TITLE
													  target:self
													  action:@selector(toggleHide:)
											   keyEquivalent:@""];
	[menuItem_hideBlocked setIndentationLevel:1];
	[[adium menuController] addMenuItem:menuItem_hideBlocked toLocation:LOC_View_Toggles];

	menuItem_useOfflineGroup = [[NSMenuItem alloc] initWithTitle:SHOW_OFFLINE_GROUP_MENU_TITLE
														  target:self
														  action:@selector(toggleHide:)
												   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem_useOfflineGroup toLocation:LOC_View_Toggles];

	//Register preference observer first so values will be correct for the following calls
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[menuItem_hideOffline release]; menuItem_hideOffline = nil;
	[menuItem_hideIdle release]; menuItem_hideIdle = nil;
	[menuItem_useOfflineGroup release]; menuItem_useOfflineGroup = nil;
	[menuItem_hideBlocked release]; menuItem_hideBlocked = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	hideContacts = [[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue];
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	showIdleContacts = [[prefDict objectForKey:KEY_SHOW_IDLE_CONTACTS] boolValue];
	showMobileContacts = [[prefDict objectForKey:KEY_SHOW_MOBILE_CONTACTS] boolValue];
	showBlockedContacts = [[prefDict objectForKey:KEY_SHOW_BLOCKED_CONTACTS] boolValue];

	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);

	//Update our menu to reflect the current preferences
	[menuItem_hideContacts setTitle:(hideContacts ? SHOW_CONTACTS_MENU_TITLE : HIDE_CONTACTS_MENU_TITLE)];
	[menuItem_hideOffline setTitle:(showOfflineContacts ? HIDE_OFFLINE_MENU_TITLE : SHOW_OFFLINE_MENU_TITLE)];
	[menuItem_hideIdle setTitle:(showIdleContacts ? HIDE_IDLE_MENU_TITLE : SHOW_IDLE_MENU_TITLE)];
	[menuItem_hideMobile setTitle:(showMobileContacts ? HIDE_MOBILE_MENU_TITLE : SHOW_MOBILE_MENU_TITLE)];
	[menuItem_hideBlocked setTitle:(showBlockedContacts ? HIDE_BLOCKED_MENU_TITLE : SHOW_BLOCKED_MENU_TITLE)];
	[menuItem_useOfflineGroup setTitle:(useOfflineGroup ? HIDE_OFFLINE_GROUP_MENU_TITLE : SHOW_OFFLINE_GROUP_MENU_TITLE)];	
}

/*!
 * @brief Toggle contact/group hiding
 */
- (IBAction)toggleHide:(id)sender
{
	if (sender == menuItem_hideContacts) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!hideContacts]
											 forKey:KEY_HIDE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideOffline) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showOfflineContacts]
											 forKey:KEY_SHOW_OFFLINE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideIdle) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showIdleContacts]
											 forKey:KEY_SHOW_IDLE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideMobile) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showMobileContacts]
											 forKey:KEY_SHOW_MOBILE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];		
	} else if (sender == menuItem_hideBlocked) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!showBlockedContacts]
											 forKey:KEY_SHOW_BLOCKED_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_useOfflineGroup) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:!useOfflineGroup]
											 forKey:KEY_USE_OFFLINE_GROUP
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
}


#pragma mark Offline group

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_useOfflineGroup) {
		//Can only show offline group if groups and offline contacts are both shown
		return (useContactListGroups && (showOfflineContacts || !hideContacts));

	} else if (menuItem == menuItem_hideOffline ||
			   menuItem == menuItem_hideIdle ||
			   menuItem == menuItem_hideMobile ||
			   menuItem == menuItem_hideBlocked) {
		return hideContacts;
	}
	
	return YES;
}
@end
