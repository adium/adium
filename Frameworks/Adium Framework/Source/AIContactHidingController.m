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
#import <Adium/AIListBookmark.h>
#import <Adium/AIService.h>
#import "AIContactController.h"

@interface AIContactHidingController ()
- (BOOL)evaluatePredicateOnListObject:(AIListObject *)listObject withSearchString:(NSString *)inSearchString;
@end;

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
	
		hideAccounts = nil;
		matchedContacts = [[NSMutableDictionary alloc] init];
		
		// contains[cd] - c = case insensitive, d = diacritic insensitive
		filterPredicateTemplate = [[NSPredicate predicateWithFormat:@"displayName contains[cd] $KEYWORD OR formattedUID contains[cd] $KEYWORD OR uid contains[cd] $KEYWORD"] retain];
	}
	return self;
}

- (void)dealloc
{
	[matchedContacts release]; matchedContacts = nil;
	[searchString release]; searchString = nil;
	[filterPredicate release]; filterPredicate = nil;
	[filterPredicateTemplate release]; filterPredicateTemplate = nil;
	[hideAccounts release]; hideAccounts = nil;
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
	showAwayContacts = [[prefDict objectForKey:KEY_SHOW_AWAY_CONTACTS] boolValue];
	
	[hideAccounts release];
	hideAccounts = [[prefDict objectForKey:KEY_HIDE_ACCOUNT_CONTACTS] retain];
	
	useContactListGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
	useOfflineGroup = (useContactListGroups && [[prefDict objectForKey:KEY_USE_OFFLINE_GROUP] boolValue]);
	
	if (!firstTime) {
		[[NSNotificationCenter defaultCenter] postNotificationName:CONTACT_VISIBILITY_OPTIONS_CHANGED_NOTIFICATION object:nil];
		[adium.contactController sortContactList];
	}
}

@synthesize contactFilteringSearchString = searchString;

/*!
 * @brief Sets the contact filtering search string
 *
 * @param inSearchString The search string
 */
- (BOOL)filterContacts:(NSString *)inSearchString
{
	[searchString release];
	searchString = [inSearchString retain];
	[filterPredicate release];
	filterPredicate = nil;
	[matchedContacts removeAllObjects];
	
	BOOL atLeastOneMatch = NO;
	
	for (AIListContact *listContact in [adium.contactController.allContacts arrayByAddingObjectsFromArray:adium.contactController.allBookmarks]) {
		BOOL matched = [self evaluatePredicateOnListObject:listContact withSearchString:inSearchString];
		
		atLeastOneMatch = atLeastOneMatch || matched;
		
		[matchedContacts setObject:[NSNumber numberWithBool:matched] forKey:listContact.UID];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTACT_VISIBILITY_OPTIONS_CHANGED_NOTIFICATION object:nil];
	[adium.contactController sortContactList];
	
	return atLeastOneMatch;
}

/*!
 * @brief Determines a contact's visibility in a particular group based on the contact hiding preferences
 * @result Returns YES if the contact should be visible, otherwise NO
 */
- (BOOL)visibilityOfListObject:(AIListObject *)listObject inContainer:(id<AIContainingObject>)container
{
	if (![container containsObject:listObject])
		return NO;
	
	if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
		// A meta contact must meet the criteria for a contact to be visible and also have at least 1 contained contact
		return ([(id<AIContainingObject>)listObject visibleCount] > 0 || ([listObject boolValueForProperty:@"New Object"] &&
																		  useContactListGroups));
	}
	
	if (searchString && [searchString length]) {
		NSNumber *matched = [matchedContacts objectForKey:listObject.UID];
		if (matched)
			return [matched boolValue];
		return [self evaluatePredicateOnListObject:listObject withSearchString:searchString];
	}
	
	// Don't do any processing for a contact that's always visible.
	if (listObject.alwaysVisible)
		return YES;
	
	if ([listObject isKindOfClass:[AIListBookmark class]])
		return ((AIListBookmark *)listObject).account.online;
	
	if (!hideOfflineIdleOrMobileContacts)
		return YES;
	
	BOOL online = listObject.online || [listObject boolValueForProperty:@"signedOff"] || [listObject boolValueForProperty:@"New Object"];
	
	if (!showOfflineContacts && !online)
		return NO;
		
	if (!showIdleContacts && [listObject boolValueForProperty:@"isIdle"])
		return NO;
	
	if (!showMobileContacts && listObject.isMobile)
		return NO;
	
	if (!showBlockedContacts && listObject.isBlocked)
		return NO;
	
	if (!showAwayContacts && listObject.statusType == AIAwayStatusType)
		return NO;
	
	if ([listObject isKindOfClass:[AIListContact class]] &&
		[hideAccounts containsObject:((AIListContact *)listObject).account.internalObjectID])
		return NO;
	
	return YES;
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
	
	if (!filterPredicate)
		filterPredicate = [[self createPredicateWithSearchString:inSearchString] retain];
	
	// If the given contact is a meta contact, check all of its contained objects.
	if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
		
		for (AIListContact *containedContact in (id<AIContainingObject>)listObject) {
			if ([filterPredicate evaluateWithObject:containedContact])
				return YES;
		}

		return NO;
	} else {
		return [filterPredicate evaluateWithObject:listObject];
	}
}

/*!
 * @brief Generate a predicate by splitting the search string into keywords
 * @param inSearchString The search string to split
 * @result Returns an NSPredicate to compare a contact to, or if inSearchString is empty, a predicate that matches everything
 */
- (NSPredicate*) createPredicateWithSearchString: (NSString *) inSearchString
{
	// Special-case the empty search-string
	if (!inSearchString || ![inSearchString length]) 
		return [NSPredicate predicateWithFormat: @"TRUEPREDICATE"];

	NSMutableArray *subpredicates = [[NSMutableArray alloc] init];
	
	// Tokenize the string looking for words and iterate over tokens, storing an NSPredicate for each keyword
	// Use CFStringTokenizer for multi-language support and to handle empty tokens
	CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(nil, (CFStringRef)inSearchString, CFRangeMake(0, inSearchString.length), kCFStringTokenizerUnitWord, NULL);
	CFStringTokenizerTokenType tokenType;
	while ((tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)) != kCFStringTokenizerTokenNone) {
		CFRange range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
		NSRange nsRange = NSMakeRange(range.location, range.length);
		NSString* keyword = [inSearchString substringWithRange: nsRange];
		NSPredicate* predicate = [filterPredicateTemplate predicateWithSubstitutionVariables: [NSDictionary dictionaryWithObject:keyword forKey:@"KEYWORD"]];
		[subpredicates addObject: predicate];
	}
	
	// Build a compound predicate based on the predicate for each token.
	NSPredicate* retval = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];

	CFRelease(tokenizer);
	[subpredicates release];
	
	return retval;
}

@end
