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

#import "AIAlphabeticalSort.h"
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIListObject.h>

#define KEY_SORT_BY_LAST_NAME				@"ABC:Sort by Last Name"
#define KEY_SORT_GROUPS						@"ABC:Sort Groups"
#define ALPHABETICAL_SORT_DEFAULT_PREFS		@"AlphabeticalSortDefaults"

static 	BOOL	sortGroups;
static  BOOL	sortByLastName;

/*!
 * @class AIAlphabeticalSort
 * @brief Sort controller to sort contacts and groups alphabetically.
 */
@implementation AIAlphabeticalSort

/*!
 * @brief Did become active first time
 *
 * Called only once; gives the sort controller an opportunity to set defaults and load preferences lazily.
 */
- (void)didBecomeActiveFirstTime
{
	//Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:ALPHABETICAL_SORT_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];
	
	//Load our preferences
	sortGroups = [[adium.preferenceController preferenceForKey:KEY_SORT_GROUPS
														   group:PREF_GROUP_CONTACT_SORTING] boolValue];
	sortByLastName = [[adium.preferenceController preferenceForKey:KEY_SORT_BY_LAST_NAME
															   group:PREF_GROUP_CONTACT_SORTING] boolValue];
}

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{
    return @"Alphabetical";
}

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{
    return AILocalizedString(@"Sort Contacts Alphabetically",nil);
}

/*!
 * @brief Properties which, when changed, should trigger a resort
 */
- (NSSet *)statusKeysRequiringResort{
	return nil;
}

/*!
 * @brief Attribute keys which, when changed, should trigger a resort
 */
- (NSSet *)attributeKeysRequiringResort{
	return [NSSet setWithObject:@"Display Name"];
}

#pragma mark Configuration
/*!
 * @brief Window title when configuring the sort
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortWindowTitle{
	return AILocalizedString(@"Configure Alphabetical Sort",nil);	
}

/*!
 * @brief Nib name for configuration
 */
- (NSString *)configureNibName{
	return @"AlphabeticalSortConfiguration";
}

/*!
 * @brief View did load
 */
- (void)viewDidLoad{
	[checkBox_sortByLastName setLocalizedString:AILocalizedString(@"Sort contacts by last name",nil)];
	[checkBox_sortGroups setLocalizedString:AILocalizedString(@"Sort groups alphabetically",nil)];
	
	[checkBox_sortByLastName setState:sortByLastName];
	[checkBox_sortGroups setState:sortGroups];
}

/*!
 * @brief Preference changed
 *
 * Sort controllers should live update as preferences change.
 */
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_sortGroups) {
		sortGroups = [sender state];
		[adium.preferenceController setPreference:[NSNumber numberWithBool:sortGroups]
                                             forKey:KEY_SORT_GROUPS
                                              group:PREF_GROUP_CONTACT_SORTING];		
	} else if (sender == checkBox_sortByLastName) {
		sortByLastName = [sender state];
		[adium.preferenceController setPreference:[NSNumber numberWithBool:sortByLastName]
                                             forKey:KEY_SORT_BY_LAST_NAME
                                              group:PREF_GROUP_CONTACT_SORTING];			
	}
	
	[adium.contactController sortContactList];
}

#pragma mark Sorting
/*!
 * @brief Alphabetical sort
 */
NSInteger alphabeticalSort(id objectA, id objectB, BOOL groups, id<AIContainingObject> container)
{
	//If we were not passed groups or if we should be sorting groups, sort alphabetically
    
    // Changed from "caseInsensitiveCompare" to "localizedCaseInsensitive" to get the correct ordering for languages like Swedish
	if (!groups) {
		if (sortByLastName) {
			NSString	*space = @" ";
			NSString	*displayNameA = [objectA displayName];
			NSString	*displayNameB = [objectB displayName];
			NSArray		*componentsA = [displayNameA componentsSeparatedByString:space];
			NSArray		*componentsB = [displayNameB componentsSeparatedByString:space];
			
			NSComparisonResult returnValue = [[componentsA lastObject] localizedCaseInsensitiveCompare:[componentsB lastObject]];
			//If the last names are the same, compare the whole object, which will amount to sorting these objects by first name
			if (returnValue == NSOrderedSame) {
				returnValue = [displayNameA localizedCaseInsensitiveCompare:displayNameB];
			}
			
			return (returnValue);
		} else {
			return [[objectA longDisplayName] localizedCaseInsensitiveCompare:[objectB longDisplayName]];
		}

	} else {
		//If sorting groups, do a caseInsesitiveCompare; otherwise, keep groups in manual order
		if (sortGroups) {
			return [[objectA longDisplayName] localizedCaseInsensitiveCompare:[objectB longDisplayName]];
		} else if ([container orderIndexForObject:objectA] > [container orderIndexForObject:objectB]) {
			return NSOrderedDescending;
		} else {
			return NSOrderedAscending;
		}
	}
}

/*!
 * @brief Sort function
 */
- (sortfunc)sortFunction{
	return &alphabeticalSort;
}

- (IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:configureView.window];
}

@end
