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

#import "AIAdvancedPreferences.h"
#import <Adium/AIAdvancedPreferencePane.h>
#import <Adium/KNShelfSplitView.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIViewAdditions.h>

#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"
#define KEY_ADVANCED_PREFERENCE_SHELF_WIDTH		@"AdvancedPrefs:ShelfWidth"

@interface AIAdvancedPreferences ()
- (void)_configureAdvancedPreferencesTable;
@end

@implementation AIAdvancedPreferences
+ (AIPreferencePane *)preferencePane
{
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:150]
																										forKey:KEY_ADVANCED_PREFERENCE_SHELF_WIDTH]
																   forGroup:PREF_GROUP_WINDOW_POSITIONS];
	
	return [super preferencePane];
}

- (NSString *)paneIdentifier
{
	return @"Advanced";
}
- (NSString *)paneName{
	return AILocalizedString(@"Advanced", "Title of the messages preferences");
}
- (NSString *)nibName{
    return @"AdvancedPreferences";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-advanced"];
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	[shelf_splitView setFrame:[[shelf_splitView superview] frame]];
	[shelf_splitView setShelfWidth:(CGFloat)[[adium.preferenceController preferenceForKey:KEY_ADVANCED_PREFERENCE_SHELF_WIDTH
																			 group:PREF_GROUP_WINDOW_POSITIONS] doubleValue]];

	[tableView_categories accessibilitySetOverrideValue:AILocalizedString(@"Advanced Preference Categories", nil)
										   forAttribute:NSAccessibilityRoleDescriptionAttribute];

	[self _configureAdvancedPreferencesTable];
}

- (void)viewWillClose
{
	//Select the previously selected row
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:[tableView_categories selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];

	[adium.preferenceController setPreference:[NSNumber numberWithDouble:[shelf_splitView shelfWidth]]
										 forKey:KEY_ADVANCED_PREFERENCE_SHELF_WIDTH
										  group:PREF_GROUP_WINDOW_POSITIONS];
	
	//Close open panes
	[loadedAdvancedPanes makeObjectsPerformSelector:@selector(closeView)];
	[modularPane removeAllSubviews];
	[loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
	[_advancedCategoryArray release]; _advancedCategoryArray = nil;
}

/*!
* @brief Returns an array containing all the available advanced preference views
 */
- (NSArray *)advancedCategoryArray
{
    if (!_advancedCategoryArray) {
        _advancedCategoryArray = [[[adium.preferenceController advancedPaneArray] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
    }
    
    return _advancedCategoryArray;
}

/*!
 * @brief Displays the passed AIPreferencePane in the advanced preferences tab of our window
 */
- (void)configureAdvancedPreferencesForPane:(AIAdvancedPreferencePane *)preferencePane
{
	//Close open panes
	[loadedAdvancedPanes makeObjectsPerformSelector:@selector(closeView)];
	[modularPane removeAllSubviews];
	[loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
	
	//Load new panes
	if (preferencePane) {
		loadedAdvancedPanes = [[NSArray arrayWithObject:preferencePane] retain];
		[modularPane setPanes:loadedAdvancedPanes];
	}
}

/*!
* @brief Configure the advanced preference category table view
 */
- (void)_configureAdvancedPreferencesTable
{	
	[[tableView_categories enclosingScrollView] setAutohidesScrollers:YES];
	
	AIImageTextCell *cell = [[[AIImageTextCell alloc] initTextCell:@""] autorelease];
	[cell setFont:[NSFont systemFontOfSize:11]];
	[cell setLineBreakMode:NSLineBreakByTruncatingTail];
	
	[[tableView_categories tableColumnWithIdentifier:@"description"] setDataCell:cell];

	//Select the previously selected row
	NSInteger row = [[adium.preferenceController preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
														group:PREF_GROUP_WINDOW_POSITIONS] integerValue];
	if (row < 0 || row >= [tableView_categories numberOfRows]) row = 1;
	
	[tableView_categories selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[self tableViewSelectionDidChange:nil];
}

/*!
* @brief Return the number of accounts
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self advancedCategoryArray] count];
}

/*!
* @brief Return the account description or image
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"description"]) {
		return [[[self advancedCategoryArray] objectAtIndex:row] label];
	} else if ([identifier isEqualToString:@"image"]) {
		[[tableColumn dataCell] setImageAlignment:NSImageAlignRight];
		return [[[self advancedCategoryArray] objectAtIndex:row] image];
	}
	
	return nil;
}

/*!
* @brief Update our advanced preferences for the selected pane
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger row = [tableView_categories selectedRow];

	if (row >= 0 && row < [[self advancedCategoryArray] count]) {		
		[self configureAdvancedPreferencesForPane:[[self advancedCategoryArray] objectAtIndex:row]];
	}
}

@end
