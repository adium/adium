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

#define KEY_COUNT_ALL_CONTACTS					@"Count All Contacts"
#define KEY_COUNT_ONLINE_CONTACTS				@"Count Online Contacts"

#define	KEY_HIDE_CONTACT_LIST_GROUPS			@"Hide Contact List Groups"

/*!
 * @class CBContactCountingDisplayPlugin
 *
 * @brief Component to handle displaying counts of contacts, both online and total, next to group names
 *
 * This componenet adds two menu items, "Count All Contacts" and "Count Online Contacts." Both default to being off.
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
	
	//set up the prefs
	countAllObjects = NO;
	countOnlineObjects = NO;
	
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
		([key isEqualToString:KEY_COUNT_ONLINE_CONTACTS] || [key isEqualToString:KEY_COUNT_ALL_CONTACTS] || firstTime)) {
		countAllObjects = [[prefDict objectForKey:KEY_COUNT_ALL_CONTACTS] boolValue];
		countOnlineObjects = [[prefDict objectForKey:KEY_COUNT_ONLINE_CONTACTS] boolValue];
		
		[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];

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
	NSMutableSet	*groups = [NSMutableSet set];

	//We never update for an AIAccount object
	
	if ([inObject isKindOfClass:[AIListContact class]] && [inModifiedKeys containsObject:@"isOnline"]) {
		// We need to update *all* of this contact's groups for its online change.
		[groups unionSet:inObject.groups];
	} else if ([inObject isKindOfClass:[AIListGroup class]]
			   && (!inModifiedKeys || ([inModifiedKeys containsObject:@"ObjectCount"] || [inModifiedKeys containsObject:@"VisibleObjectCount"]))
			   && ![inObject.UID isEqualToString:ADIUM_ROOT_GROUP_NAME]) {
		
		/* We check against a nil inModifiedKeys so we can remove our Counting information from the display when the user
		 * toggles it off.
		 *
		 * We update for any group which isn't the root group when its contained objects count changes.
		 */	
		[groups addObject:inObject];
	} else {
		// We don't need to update anything.
		return nil;
	}

	for (AIListGroup *inGroup in groups) {

		NSString		*countString = nil;

		NSUInteger onlineObjects = 0;
		
		for (AIListObject *listObject in inGroup.visibleContainedObjects) {
			if ([listObject boolValueForProperty:@"isOnline"]) {
				onlineObjects++;
			}
		}

		NSUInteger totalObjects = inGroup.countOfContainedObjects;

		/*
		 * Create our count string for displaying in the list group's cell
		 * If the number of online objects is the same as the number of total objects, just display one number.
		 * If the group is the offline group, just display the number of total objects if we should.
		 */
		if (countOnlineObjects && countAllObjects && (onlineObjects != totalObjects) && (inGroup != adium.contactController.offlineGroup)) {
			countString = [NSString stringWithFormat:AILocalizedString(@"%lu of %lu", "Used in the display for the contact list for the number of online contacts out of the number of total contacts"),
													onlineObjects, totalObjects];
		} else if (countAllObjects) {
			countString = [NSString stringWithFormat:@"%lu", totalObjects];
		} else if (inGroup != adium.contactController.offlineGroup) {
			countString = [NSString stringWithFormat:@"%lu", onlineObjects];
		} else {
			countString = @"";
		}

		[inGroup setValue:countString
			  forProperty:@"countText"
				   notify:NotifyNever];
		[inGroup setValue:[NSNumber numberWithBool:(countOnlineObjects || countAllObjects)]
			  forProperty:@"showCount"
				   notify:NotifyNever];

		[[AIContactObserverManager sharedManager] listObjectAttributesChanged:inGroup
																 modifiedKeys:[NSSet setWithObject:@"countText"]];
	}
	
	return nil;
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
