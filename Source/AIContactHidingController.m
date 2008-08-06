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
#import "AIContactController.h"

@interface AIContactHidingController (PRIVATE)
- (void)setVisibility:(BOOL)visibleFlag ofListContact:(AIListContact *)listContact withReason:(AIVisibilityReason)reason;
- (BOOL)visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)listContact;
- (BOOL)evaluatePredicateOnListContact:(AIListContact *)listContact withSearchString:(NSString *)inSearchString;
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end;

/*!
 *	@class AIContactHidingController
 *	@brief Manages the visibility state of contacts. 
 *	Currently, it prevents conflicts between offline contact hiding and contact list filtering by following a set of rules in setVisibility:ofListContact:withReason
 *	It also handles actually filtering contacts based on a search string and keeping track of offline/idle/mobile contacts
 */

@implementation AIContactHidingController

- (id)init
{
	self = [super init];
	if (self != nil) {
		//Register preference observer first so values will be correct for the following calls
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	}
	return self;
}

- (void)dealloc
{
	[[adium contactController] unregisterListObjectObserver:self];
	[searchString release];
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
	
	if (firstTime) {
		[[adium contactController] registerListObjectObserver:self];
	} else {
		//Refresh visibility of all contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		//Resort the entire list, forcing the visibility changes to hae an immediate effect (we return nil in the 
		//updateListObject: method call, so the contact controller doesn't know we changed anything)
		[[adium contactController] sortContactList];
	}
}

/*!
 * @brief Returns the current contact filtering search string
 */
- (NSString *)contactFilteringSearchString
{
    return searchString; 
}

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
	
	if(refilterContacts)
		[self refilterContacts];
}

/*!
 * @brief Sets the visibility of a contact
 * @param visibileFlag YES if the contact should be visible, otherwise NO
 * @param listContact The list contact whose visibility is being modified
 * @param reason The AIVisibilityReason which is causing the visibility change
 */
- (void)setVisibility:(BOOL)visibleFlag
		ofListContact:(AIListContact *)listContact
		   withReason:(AIVisibilityReason)reason;
{	
	if ([listContact visible] == visibleFlag) {
		// The contact already has this visibility set
		return;
	}

	if (reason == AIOfflineContactHidingReason) {
		// If the contact is to be shown, make sure it also matches the current search term.
		// -evaluatePredicateOnListObject:withSearchString: returns YES on an empty search string.
		[listContact setVisible:(visibleFlag && [self evaluatePredicateOnListContact:listContact withSearchString:searchString])];
	} else if (reason == AIContactFilteringReason) {
		// visibileFlag = YES if we're part of the search set, otherwise NO if we're no longer part of the search.
		[listContact setVisible:visibleFlag];
	}
}

/*!
 * @brief Update visibility of a list object
 */
- (NSSet *)updateListObject:(AIListObject *)inObject
					   keys:(NSSet *)inModifiedKeys
					 silent:(BOOL)silent
{
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:@"Online"] ||
		[inModifiedKeys containsObject:@"IdleSince"] ||
		[inModifiedKeys containsObject:@"Signed Off"] ||
		[inModifiedKeys containsObject:@"New Object"] ||
		[inModifiedKeys containsObject:@"VisibleObjectCount"] ||
		[inModifiedKeys containsObject:@"IsMobile"] ||
		[inModifiedKeys containsObject:@"IsBlocked"] ||
		[inModifiedKeys containsObject:@"AlwaysVisible"]) {
		
		if ([inObject isKindOfClass:[AIListContact class]]) {
			[self setVisibility:[self visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)inObject]
				  ofListContact:(AIListContact *)inObject
					 withReason:AIOfflineContactHidingReason];
			
		} else if ([inObject isKindOfClass:[AIListGroup class]]) {
			[inObject setVisible:((useContactListGroups) &&
								  ([(AIListGroup *)inObject visibleCount] > 0 || [inObject integerValueForProperty:@"New Object"]) &&
								  (useOfflineGroup || ((AIListGroup *)inObject != [[adium contactController] offlineGroup])))];
		}
	}
	
	return nil;
}

/*!
 * @brief Determines a contact's visibility based on the contact hiding preferences
 * @result Returns YES if the contact should be visible, otherwise NO
 */
- (BOOL)visibilityBasedOnOfflineContactHidingPreferencesOfListContact:(AIListContact *)listContact
{
	// Don't do any processing for a contact that's always visible.
	if ([listContact alwaysVisible]) {
		return YES;
	}
	
	BOOL visible = YES;
	
	// If we're hiding contacts, and these meet a criteria for hiding
	if (hideOfflineIdleOrMobileContacts && ((!showIdleContacts &&
											 [listContact valueForProperty:@"IdleSince"]) ||
											(!showOfflineContacts &&
											 ![listContact online] &&
											 ![listContact integerValueForProperty:@"Signed Off"] &&
											 ![listContact integerValueForProperty:@"New Object"]) ||
											(!showMobileContacts && 
											 [listContact isMobile]) ||
											(!showBlockedContacts &&
											 [listContact isBlocked]))) {
		visible = NO;
	}
	
	if ([listContact conformsToProtocol:@protocol(AIContainingObject)]) {
		// A meta contact must meet the criteria for a contact to be visible and also have at least 1 contained contact
		visible = (visible && ([(AIListContact<AIContainingObject> *)listContact visibleCount] > 0));
	} 
	
	return visible;
}

/*!
 * @brief Determines if any contacts match the given search string
 * @param inSearchString The search string contacts are evaluated against
 * @result Returns YES if one or more contacts match the string, otherwise NO
 */
- (BOOL)searchTermMatchesAnyContacts:(NSString *)inSearchString
{
	NSMutableArray *listContacts = [[adium contactController] allContacts];
	[listContacts addObjectsFromArray:[[adium contactController] allBookmarks]];
	
	NSEnumerator	*enumerator = [listContacts objectEnumerator];
	AIListContact	*listContact;
	
	while ((listContact = [enumerator nextObject])) {
		if ([self evaluatePredicateOnListContact:listContact withSearchString:inSearchString]) {
			return YES;
		}
	}
	
	return NO;
}

/*! 
 * @brief Refilters all contacts for visibility
 */
- (void)refilterContacts
{
	if (!searchString)
		return;
	
	// If the search string is empty, refresh the visibility of all contacts.
	// This allows us to show *all* contacts when searching, and rehide them when searching is complete.
	if ([searchString isEqualToString:@""]) {
		[[adium contactController] updateAllListObjectsForObserver:self];
		
		// Restore all group chats to visible
		NSEnumerator		*enumerator = [[[adium contactController] allBookmarks] objectEnumerator];
		AIListBookmark		*bookmark;
		
		while ((bookmark = [enumerator nextObject])) {
			[bookmark setVisible:YES];
		}
		
		return;
	}
	
	NSMutableArray *listContacts = [[adium contactController] allContacts];
	[listContacts addObjectsFromArray:[[adium contactController] allBookmarks]];
	
	// Delay list object notifications until we're done
	[[adium contactController] delayListObjectNotifications];
	
	NSEnumerator	*enumerator = [listContacts objectEnumerator];
	AIListContact	*listContact;

	while ((listContact = [enumerator nextObject])) {
		// If this contact is in a meta contact, we need to check the meta contact, not this particular contact.
		if ([[listContact containingObject] isKindOfClass:[AIMetaContact class]]) {
			listContact = (AIListContact *)[listContact containingObject];
		}

		[self setVisibility:[self evaluatePredicateOnListContact:listContact withSearchString:searchString]
			  ofListContact:listContact
				 withReason:AIContactFilteringReason];
	}
	
	// Stop delaying list object notifications
	[[adium contactController] endListObjectNotificationsDelay];
}	

/*!
 * @brief Evaluates a search string on a list contact
 * @param listContact The contact or meta contact to compare to the search string
 * @param inSearchString The search string the listContact should be compared with
 * @result Returns YES if the display name, formatted UID or status message contain inSearchString, or if inSearchString is empty. Otherwise NO.
 */
static NSPredicate *filterPredicateTemplate;
- (BOOL)evaluatePredicateOnListContact:(AIListContact *)listContact
					  withSearchString:(NSString *)inSearchString
{	
	// If we aren't given a contact, return NO.
	if (!listContact)
		return NO;

	// If the search string is nil or empty, return YES.
	if(!inSearchString || [inSearchString isEqualToString:@""])
		return YES;
	
	// Create a static predicate to search the properties of a contact.
	if (!filterPredicateTemplate)
		filterPredicateTemplate = [[NSPredicate predicateWithFormat:@"displayName contains[cd] $SEARCH_STRING OR formattedUID contains[cd] $SEARCH_STRING OR statusMessageString contains[cd] $SEARCH_STRING"] retain];
	
	NSPredicate *predicate = [filterPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:inSearchString forKey:@"SEARCH_STRING"]];
	
	// If the given contact is a meta contact, check all of its contained objects.
	if ([listContact isKindOfClass:[AIMetaContact class]]) {
		NSEnumerator	*enumerator = [[(AIMetaContact *)listContact containedObjects] objectEnumerator];
		AIListContact	*listContact;
		
		while ((listContact = [enumerator nextObject])) {
			if ([predicate evaluateWithObject:listContact]) {
				return YES;
			}
		}

		return NO;
	} else {
		return [predicate evaluateWithObject:listContact];
	}
}

@end
