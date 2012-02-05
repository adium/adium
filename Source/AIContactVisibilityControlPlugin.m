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
#import "AIContactVisibilityControlPlugin.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import "AIContactController.h"

#define HIDE_CONTACTS_MENU_TITLE		AILocalizedString(@"Hide Certain Contacts",nil)
#define HIDE_OFFLINE_MENU_TITLE			AILocalizedString(@"Hide Offline Contacts",nil)
#define HIDE_IDLE_MENU_TITLE			AILocalizedString(@"Hide Idle Contacts",nil)
#define HIDE_MOBILE_MENU_TITLE			AILocalizedString(@"Hide Mobile Contacts",nil)
#define HIDE_BLOCKED_MENU_TITLE			AILocalizedString(@"Hide Blocked Contacts",nil)
#define HIDE_ACCOUNT_CONTACT_MENU_TITLE	AILocalizedString(@"Hide Contacts for Accounts",nil)
#define HIDE_AWAY_MENU_TITLE			AILocalizedString(@"Hide Away Contacts",nil)
#define	USE_OFFLINE_GROUP_MENU_TITLE	AILocalizedString(@"Use Offline Group",nil)

@interface AIContactVisibilityControlPlugin()
- (void)updateAccountMenu;
- (IBAction)toggleHide:(id)sender;
@end

/*!
 * @class AIContactVisibilityControlPlugin
 * @brief Component to handle showing or hiding offline contacts and hiding empty groups.
 *
 * Only manages menu items and preferences. The actaual hiding is done by their containing objects.
 */
@implementation AIContactVisibilityControlPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{		
	//Default preferences
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"OfflineContactHidingDefaults" forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	menu_hideAccounts = [[NSMenu alloc] init];
	[menu_hideAccounts setDelegate:self];
	
	array_hideAccounts = [[NSMutableArray alloc] init];	
	
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountNoSubmenu showTitleVerbs:NO] retain];
	
	//"Hide Contacts" menu item
	menuItem_hideContacts = [[NSMenuItem alloc] initWithTitle:HIDE_CONTACTS_MENU_TITLE
													   target:self
													   action:@selector(toggleHide:)
												keyEquivalent:@"H"];
	[adium.menuController addMenuItem:menuItem_hideContacts toLocation:LOC_View_Toggles];
	
	//Hide Contacts for Account
	menuItem_hideAccountContact = [[NSMenuItem alloc] initWithTitle:HIDE_ACCOUNT_CONTACT_MENU_TITLE
															 target:self
															 action:@selector(toggleHide:)
													  keyEquivalent:@""];
	[menuItem_hideAccountContact setIndentationLevel:1];
	[menuItem_hideAccountContact setSubmenu:menu_hideAccounts];	
	[adium.menuController addMenuItem:menuItem_hideAccountContact toLocation:LOC_View_Toggles];

	//Hide Offline Contacts
    menuItem_hideOffline = [[NSMenuItem alloc] initWithTitle:HIDE_OFFLINE_MENU_TITLE
													  target:self
													  action:@selector(toggleHide:)
											   keyEquivalent:@""];
	[menuItem_hideOffline setIndentationLevel:1];
	[adium.menuController addMenuItem:menuItem_hideOffline toLocation:LOC_View_Toggles];

	//Hide Idle Contacts
    menuItem_hideIdle = [[NSMenuItem alloc] initWithTitle:HIDE_IDLE_MENU_TITLE
												   target:self
												   action:@selector(toggleHide:)
											keyEquivalent:@""];
	[menuItem_hideIdle setIndentationLevel:1];
	[adium.menuController addMenuItem:menuItem_hideIdle toLocation:LOC_View_Toggles];
	
	//Hide Away Contacts
	menuItem_hideAway = [[NSMenuItem alloc] initWithTitle:HIDE_AWAY_MENU_TITLE
													 target:self
													 action:@selector(toggleHide:)
											  keyEquivalent:@""];
	[menuItem_hideAway setIndentationLevel:1];
	[adium.menuController addMenuItem:menuItem_hideAway toLocation:LOC_View_Toggles];

	//Hide Mobile Contacts
    menuItem_hideMobile = [[NSMenuItem alloc] initWithTitle:HIDE_MOBILE_MENU_TITLE
													 target:self
													 action:@selector(toggleHide:)
											  keyEquivalent:@""];
	[menuItem_hideMobile setIndentationLevel:1];
	[adium.menuController addMenuItem:menuItem_hideMobile toLocation:LOC_View_Toggles];
	
	//Hide Blocked Contacts
	menuItem_hideBlocked = [[NSMenuItem alloc] initWithTitle:HIDE_BLOCKED_MENU_TITLE
													  target:self
													  action:@selector(toggleHide:)
											   keyEquivalent:@""];
	[menuItem_hideBlocked setIndentationLevel:1];
	[adium.menuController addMenuItem:menuItem_hideBlocked toLocation:LOC_View_Toggles];
	
	//Hide Offline Contacts
	menuItem_useOfflineGroup = [[NSMenuItem alloc] initWithTitle:USE_OFFLINE_GROUP_MENU_TITLE
														  target:self
														  action:@selector(toggleHide:)
												   keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_useOfflineGroup toLocation:LOC_View_Toggles];
	
	//Register preference observer first so values will be correct for the following calls
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[menu_hideAccounts release]; menu_hideAccounts = nil;
	[array_hideAccounts release]; array_hideAccounts = nil;
	[accountMenu release]; accountMenu = nil;
	[menuItem_hideOffline release]; menuItem_hideOffline = nil;
	[menuItem_hideIdle release]; menuItem_hideIdle = nil;
	[menuItem_useOfflineGroup release]; menuItem_useOfflineGroup = nil;
	[menuItem_hideBlocked release]; menuItem_hideBlocked = nil;
	[menuItem_hideAccountContact release]; menuItem_hideAccountContact = nil;
	[menuItem_hideAway release]; menuItem_hideAway = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

/*!
 * @brief Preferences changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object)
		return;
	
	hideContacts = [[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue];
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	showIdleContacts = [[prefDict objectForKey:KEY_SHOW_IDLE_CONTACTS] boolValue];
	showMobileContacts = [[prefDict objectForKey:KEY_SHOW_MOBILE_CONTACTS] boolValue];
	showBlockedContacts = [[prefDict objectForKey:KEY_SHOW_BLOCKED_CONTACTS] boolValue];
	showAwayContacts = [[prefDict objectForKey:KEY_SHOW_AWAY_CONTACTS] boolValue];
	
	[array_hideAccounts removeAllObjects];
	[array_hideAccounts addObjectsFromArray:[prefDict objectForKey:KEY_HIDE_ACCOUNT_CONTACTS]];
	
	[self updateAccountMenu];

	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);

	//Update our menu to reflect the current preferences
	[menuItem_hideAccountContact setState:(array_hideAccounts.count ? NSMixedState : NSOffState)];
	[menuItem_hideContacts setState:hideContacts];
	[menuItem_hideOffline setState:!showOfflineContacts];
	[menuItem_hideIdle setState:!showIdleContacts];
	[menuItem_hideAway setState:!showAwayContacts];
	[menuItem_hideMobile setState:!showMobileContacts];
	[menuItem_hideBlocked setState:!showBlockedContacts];
	[menuItem_useOfflineGroup setState:useOfflineGroup];
}

/*!
 * @brief Toggle contact/group hiding
 */
- (IBAction)toggleHide:(id)sender
{
	if (sender == menuItem_hideContacts) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!hideContacts]
											 forKey:KEY_HIDE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideOffline) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!showOfflineContacts]
											 forKey:KEY_SHOW_OFFLINE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideIdle) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!showIdleContacts]
											 forKey:KEY_SHOW_IDLE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideMobile) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!showMobileContacts]
											 forKey:KEY_SHOW_MOBILE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];		
	} else if (sender == menuItem_hideBlocked) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!showBlockedContacts]
											 forKey:KEY_SHOW_BLOCKED_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_hideAway) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!showAwayContacts]
										   forKey:KEY_SHOW_AWAY_CONTACTS
											group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	} else if (sender == menuItem_useOfflineGroup) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:!useOfflineGroup]
											 forKey:KEY_USE_OFFLINE_GROUP
											  group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
}


#pragma mark Menu Methods

/*!
 * @brief Update our account menu
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[menu_hideAccounts removeAllItems];
	
	// Add all the accounts as menu items.
	for(NSMenuItem *menuItem in menuItems) {
		[menu_hideAccounts addItem:[[menuItem copy] autorelease]];
	}
	
	// Remove any dead accounts from the array.
	BOOL removedAnyAccounts = NO;
	for (NSString *internalID in [[array_hideAccounts copy] autorelease]) {
		if(![adium.accountController accountWithInternalObjectID:internalID]) {
			[array_hideAccounts removeObject:internalID];
			removedAnyAccounts = YES;
		}
	}
	
	// Save if necessary.
	if(removedAnyAccounts) {
		[adium.preferenceController setPreference:[[array_hideAccounts copy] autorelease]
										   forKey:KEY_HIDE_ACCOUNT_CONTACTS
											group:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
	
	[self updateAccountMenu];
}

/*!
 * @brief Toggle an account.
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	NSString *accountID = [[inAccount.internalObjectID copy] autorelease];
	
	if ([array_hideAccounts containsObject:accountID]) {
		[array_hideAccounts removeObject:accountID];
	} else {
		[array_hideAccounts addObject:accountID];
	}
	
	[adium.preferenceController setPreference:[[array_hideAccounts copy] autorelease]
									   forKey:KEY_HIDE_ACCOUNT_CONTACTS
										group:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

/*!
 * @brief Include all accounts.
 */
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return YES;
}

/*!
 * @brief Update our account menu for current state information.
 */
- (void)updateAccountMenu
{
	for(NSMenuItem *menuItem in menu_hideAccounts.itemArray) {
		NSUInteger itemState = NSOffState;
		
		if([array_hideAccounts containsObject:((AIAccount *)menuItem.representedObject).internalObjectID]) {
			itemState = NSOnState;
		}
		
		[menuItem setState:itemState];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == menuItem_useOfflineGroup) {
		// Can only change the offline group preference if groups are enabled.
		return useContactListGroups;

	} else if (menuItem == menuItem_hideOffline ||
			   menuItem == menuItem_hideIdle ||
			   menuItem == menuItem_hideMobile ||
			   menuItem == menuItem_hideBlocked ||
			   menuItem == menuItem_hideAway ||
			   menuItem == menuItem_hideAccountContact) {
		return hideContacts;
	}
	
	return YES;
}
@end
