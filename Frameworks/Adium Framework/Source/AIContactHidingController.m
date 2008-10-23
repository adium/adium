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
#import "AIContactHidingController.h"

#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIListBookmark.h>
#import "AIContactController.h"

@interface AIContactHidingController ()
- (BOOL)evaluatePredicateOnListObject:(AIListObject *)listObject withSearchString:(NSString *)inSearchString;
@end;

static NSPredicate *filterPredicateTemplate;
static NSPredicate *filterPredicate;

/*!
 *	@class AIContactHidingController
 *	@brief Manages the visibility state of contacts. 
 */
@implementation AIContactHidingController

static AIContactHidingController *sharedControllerInstance = nil;

+ (AIContactHidingController *)sharedController
{
	if(!sharedControllerInstance)
		sharedControllerInstance = [[AIContactHidingController alloc] init];
	return sharedControllerInstance;
}

- (id)init
{
	if ((self = [super init])) {
		//Register preference observer first so values will be correct for the following calls
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
	return self;
}

- (void)dealloc
{
	[searchString release];
	[filterPredicate release];
	[super dealloc];
}

- (void)preferencesChangedForGroup:(NSString *)group
							   key:(NSString *)key
							object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict
						 firstTime:(BOOL)firstTime
{
	// Don't update for specific objects.
	if (object != nil)
		return;
	
	hideOfflineIdleOrMobileContacts = [[prefDict objectForKey:KEY_HIDE_CONTACTS] boolValue];
	showOfflineContacts = [[prefDict objectForKey:KEY_SHOW_OFFLINE_CONTACTS] boolValue];
	showIdleContacts = [[prefDict objectForKey:KEY_SHOW_IDLE_CONTACTS] boolValue];
	showMobileContacts = [[prefDict objectForKey:KEY_SHOW_MOBILE_CONTACTS] boolValue];
	showBlockedContacts = [[prefDict objectForKey:KEY_SHOW_BLOCKED_CONTACTS] boolValue];
	
	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);
	
	if (!firstTime) {
		[adium.contactController sortContactList];
	}
}

@synthesize contactFilteringSearchString = searchString;

/*!
 * @brief Sets the contact filtering search string
 *
 * @param inSearchString The search string
 * @param refilterContacts If YES, all contacts will be reevaluated against the string
 */
- (void)setContactFilteringSearchString:(NSString *)inSearchString refilterContacts:(BOOL)refilterContacts
{
	[searchString release];
	searchString = [inSearchString retain];
	[filterPredicate release];
	filterPredicate = nil;
	
	if(refilterContacts)
		[adium.contactController sortContactList];;
}

/*!
 * @brief Determines a contact's visibility based on the contact hiding preferences
 * @result Returns YES if the contact should be visible, otherwise NO
 */
- (BOOL)visibilityOfListObject:(AIListObject *)listObject
{
	// Don't do any processing for a contact that's always visible.
	if (listObject.alwaysVisible)
		return YES;

	if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
		// A meta contact must meet the criteria for a contact to be visible and also have at least 1 contained contact
		return ([(AIListContact<AIContainingObject> *)listObject visibleCount] > 0);
	}
	
	if (searchString && [searchString length])
		return [self evaluatePredicateOnListObject:listObject withSearchString:searchString];
	
	if (!hideOfflineIdleOrMobileContacts)
		return YES;
	
	BOOL online = listObject.online || [listObject boolValueForProperty:@"Signed Off"] || [listObject boolValueForProperty:@"New Object"];
	
	if ([listObject isKindOfClass:[AIListBookmark class]])
		return online;
	
	//we can cast to AIListContact here since groups and metas were handled up above
	if (!online && (!showOfflineContacts || !(((AIListContact *)listObject).parentContact.containingObject && ((AIListContact *)listObject).parentContact.containingObject == adium.contactController.offlineGroup)))
		return NO;
	
	if (!showIdleContacts && [listObject valueForProperty:@"IdleSince"])
		return NO;

	if (!showMobileContacts && listObject.isMobile)
		return NO;
	
	if (!showBlockedContacts && listObject.isBlocked)
		return NO;

	return YES;
}

/*!
 * @brief Determines if any contacts match the given search string
 * @param inSearchString The search string contacts are evaluated against
 * @result Returns YES if one or more contacts match the string, otherwise NO
 */
- (BOOL)searchTermMatchesAnyContacts:(NSString *)inSearchString
{	
	for (AIListContact *listContact in [adium.contactController.allContacts arrayByAddingObjectsFromArray:adium.contactController.allBookmarks]) {
		if ([self evaluatePredicateOnListObject:listContact withSearchString:inSearchString]) {
			return YES;
		}
	}
	
	return NO;
}

/*!
 * @brief Evaluates a search string on a list contact
 * @param listContact The contact or meta contact to compare to the search string
 * @param inSearchString The search string the listContact should be compared with
 * @result Returns YES if the display name, formatted UID or status message contain inSearchString, or if inSearchString is empty. Otherwise NO.
 */
- (BOOL)evaluatePredicateOnListObject:(AIListObject *)listObject
					  withSearchString:(NSString *)inSearchString
{	
	// If we aren't given a contact, return NO.
	if (!listObject)
		return NO;

	// If the search string is nil or empty, return YES.
	if(!inSearchString || ![inSearchString length])
		return YES;
	
	// Create a static predicate to search the properties of a contact.
	if (!filterPredicateTemplate)
		filterPredicateTemplate = [[NSPredicate predicateWithFormat:@"displayName contains[cd] $SEARCH_STRING OR formattedUID contains[cd] $SEARCH_STRING OR statusMessageString contains[cd] $SEARCH_STRING"] retain];
	
	if (!filterPredicate)
		filterPredicate = [[filterPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:inSearchString forKey:@"SEARCH_STRING"]] retain];
	
	// If the given contact is a meta contact, check all of its contained objects.
	if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
		
		for (AIListContact *containedContact in (AIListContact<AIContainingObject> *)listObject) {
			if ([filterPredicate evaluateWithObject:containedContact])
				return YES;
		}

		return NO;
	} else {
		return [filterPredicate evaluateWithObject:listObject];
	}
}

@end
