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

#import "AIContactSortSelectionPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import "AIAlphabeticalSort.h"
#import "ESStatusSort.h"
#import "AIManualSort.h"

#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define CONTACT_SORTING_DEFAULT_PREFS	@"SortingDefaults"

@interface AIContactSortSelectionPlugin ()
- (void)_setActiveSortControllerFromPreferences;

- (void)adiumFinishedLaunching:(NSNotification *)notification;
@end

/*!
 * @class AIContactSortSelectionPlugin
 * @brief Component to manage contact sorting selection
 */
@implementation AIContactSortSelectionPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	enableConfigureSort = NO;
	
    //Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_SORTING_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];

	//Wait for Adium to finish launching before we set up the sort controller
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
	
	[AISortController registerSortController:[[AIAlphabeticalSort alloc] init]];
	[AISortController registerSortController:[[ESStatusSort alloc] init]];
	[AISortController registerSortController:[[AIManualSort alloc] init]];
}

/*!
 * @brief Our available sort controllers changed
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Inform the contactController of the active sort controller
	[self _setActiveSortControllerFromPreferences];
}

/*!
 * @brief Set the active sort controller from the preferences
 */
- (void)_setActiveSortControllerFromPreferences
{
	NSString *identifier = [adium.preferenceController preferenceForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER
														  group:PREF_GROUP_CONTACT_SORTING];
	
	AISortController *controller = nil;
	for (controller in [AISortController availableSortControllers]) {
		if ([identifier compare:[controller identifier]] == NSOrderedSame) {
			[AISortController setActiveSortController:controller];
			break;
		}
	}
	
	//Temporary failsafe for old preferences
	if (!controller) {
		[AISortController setActiveSortController:[[AISortController availableSortControllers] objectAtIndex:0]];
	}
}

@end
