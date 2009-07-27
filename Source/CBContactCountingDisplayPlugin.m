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
#import "CBContactCountingDisplayPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>

#define CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS  @"ContactCountingDisplayDefaults"

#define SHOW_COUNT_VISIBLE_CONTACTS_TITLE				AILocalizedString(@"Show Group Visible Count", nil)
#define SHOW_COUNT_ALL_CONTACTS_TITLE				AILocalizedString(@"Show Group Total Count", nil)

#define KEY_COUNT_ALL_CONTACTS					@"Count All Contacts"
#define KEY_COUNT_VISIBLE_CONTACTS				@"Count Online Contacts" //Kept as "Online" to preserve preferences

#define	KEY_HIDE_CONTACT_LIST_GROUPS			@"Hide Contact List Groups"

/*!
 * @class CBContactCountingDisplayPlugin
 *
 * @brief Component to handle displaying counts of contacts, both visible and total, next to group names
 *
 * This componenet adds two menu items, "Count All Contacts" and "Count Visible Contacts." Both default to being off.
 * When on, these options display the appropriate count for an AIListGroup's contained objects.
 */
@implementation CBContactCountingDisplayPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //register our defaults
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_COUNTING_DISPLAY_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_LIST];
	
    //init our menu items
    menuItem_countVisibleObjects = [[NSMenuItem alloc] initWithTitle:SHOW_COUNT_VISIBLE_CONTACTS_TITLE 
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
    [adium.menuController addMenuItem:menuItem_countVisibleObjects toLocation:LOC_View_Counting_Toggles];		

    menuItem_countAllObjects = [[NSMenuItem alloc] initWithTitle:SHOW_COUNT_ALL_CONTACTS_TITLE
														 target:self 
														 action:@selector(toggleMenuItem:)
												  keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_countAllObjects toLocation:LOC_View_Counting_Toggles];		
    
	//set up the prefs
	countAllObjects = NO;
	countVisibleObjects = NO;
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

/*!
 * @brief Preferences changed
 *
 * PREF_GROUP_CONTACT_LIST preferences changed; update our counting display as necessary.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	// Don't update for specific objects.
	if (object != nil)
		return;
	
	if ([group isEqualToString:PREF_GROUP_CONTACT_LIST] &&
		([key isEqualToString:KEY_COUNT_VISIBLE_CONTACTS] || [key isEqualToString:KEY_COUNT_ALL_CONTACTS] || firstTime)) {
		countAllObjects = [[prefDict objectForKey:KEY_COUNT_ALL_CONTACTS] boolValue];
		countVisibleObjects = [[prefDict objectForKey:KEY_COUNT_VISIBLE_CONTACTS] boolValue];
		
		[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
	
		[menuItem_countVisibleObjects setState:countVisibleObjects];
		[menuItem_countAllObjects setState:countAllObjects];

	} else if (([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) &&
			   (!key || [key isEqualToString:KEY_HIDE_CONTACT_LIST_GROUPS])) {		
		showingGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	}
}

/*!
 * @brief Update the counts when a group changes its object count or a contact signs on or off
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{    
	NSSet		*modifiedAttributes = nil;

	//We never update for an AIAccount object
	if (![inObject isKindOfClass:[AIListGroup class]]) return nil;
	
	AIListGroup *inGroup = (AIListGroup *)inObject;

	/* We check against a nil inModifiedKeys so we can remove our Counting information from the display when the user
	 * toggles it off.
	 *
	 * We update for any group which isn't the root group when its contained objects count changes.
	 * We update a contact's containing group when its visible state changes.
	 */	
	if ((inModifiedKeys == nil) ||
		(([inModifiedKeys containsObject:@"ObjectCount"] || [inModifiedKeys containsObject:@"VisibleObjectCount"]) &&
		 (![inObject.UID isEqualToString:ADIUM_ROOT_GROUP_NAME]))) {
		
		NSString		*countString = nil;
		
		NSUInteger visibleObjects = inGroup.visibleCount;
		NSUInteger totalObjects = inGroup.countOfContainedObjects;
	
		// Create our count string for displaying in the list group's cell
		// If the number of visible objects is the same as the number of total objects, just display one number.
		if (countVisibleObjects && countAllObjects && (visibleObjects != totalObjects)) {
			countString = [NSString stringWithFormat:AILocalizedString(@"%lu of %lu", "Used in the display for the contact list for the number of visible contacts out of the number of total contacts"),
													visibleObjects, totalObjects];
		} else if (countAllObjects) {
			countString = [NSString stringWithFormat:@"%lu", totalObjects];
		} else {
			countString = [NSString stringWithFormat:@"%lu", visibleObjects];
		}

		[inObject setValue:countString
			   forProperty:@"Count Text"
					notify:NotifyNever];
		[inObject setValue:[NSNumber numberWithBool:(countVisibleObjects || countAllObjects)]
			   forProperty:@"Show Count"
					notify:NotifyNever];
	
		modifiedAttributes = [NSSet setWithObject:@"Count Text"];
	}
	
	return modifiedAttributes;
}

/*!
 * @brief User toggled one of our two menu items
 */
- (void)toggleMenuItem:(id)sender
{
	if (sender == menuItem_countVisibleObjects) {
		BOOL	newPref = !countVisibleObjects;

		//Toggle and set, which will call back on preferencesChanged: above
		[adium.preferenceController setPreference:[NSNumber numberWithBool:newPref]
											 forKey:KEY_COUNT_VISIBLE_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST];

	} else if (sender == menuItem_countAllObjects) {
		BOOL	newPref = !countAllObjects;

		//Toggle and set, which will call back on preferencesChanged: above
		[adium.preferenceController setPreference:[NSNumber numberWithBool:newPref]
											 forKey:KEY_COUNT_ALL_CONTACTS
											  group:PREF_GROUP_CONTACT_LIST];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ((menuItem == menuItem_countVisibleObjects) || (menuItem == menuItem_countAllObjects)) {
		return showingGroups;
	}
	
	return YES;
}

/*
 * Uninstall
 */
- (void)uninstallPlugin
{
    //we are no longer an observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

@end
