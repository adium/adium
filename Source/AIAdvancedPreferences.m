//
//  AIAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

#import "AIAdvancedPreferences.h"
#import <Adium/AIAdvancedPreferencePane.h>
#import <Adium/KNShelfSplitView.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIAlternatingRowTableView.h>

#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"
#define KEY_ADVANCED_PREFERENCE_SHELF_WIDTH		@"AdvancedPrefs:ShelfWidth"

@interface AIAdvancedPreferences (PRIVATE)
- (void)_configureAdvancedPreferencesTable;
@end

@implementation AIAdvancedPreferences
+ (AIPreferencePane *)preferencePane
{
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:150]
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
	[shelf_splitView setShelfWidth:[[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SHELF_WIDTH
																			 group:PREF_GROUP_WINDOW_POSITIONS] floatValue]];

	[tableView_categories accessibilitySetOverrideValue:AILocalizedString(@"Advanced Preference Categories", nil)
										   forAttribute:NSAccessibilityRoleDescriptionAttribute];

	[self _configureAdvancedPreferencesTable];
}

- (void)viewWillClose
{
	//Select the previously selected row
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[tableView_categories selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];

	[[adium preferenceController] setPreference:[NSNumber numberWithFloat:[shelf_splitView shelfWidth]]
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
        _advancedCategoryArray = [[[[adium preferenceController] advancedPaneArray] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
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
    AIImageTextCell			*cell;
	
    //Configure our tableView
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:12]];
    [[tableView_categories tableColumnWithIdentifier:@"description"] setDataCell:cell];
	[cell release];
	
    [[tableView_categories enclosingScrollView] setAutohidesScrollers:YES];
	[tableView_categories setDrawsGradientSelection:YES];
	
	//This is the Mail.app source list background color... which differs from the iTunes one.
	[tableView_categories setBackgroundColor:[NSColor colorWithCalibratedRed:.9059
																	   green:.9294
																		blue:.9647
																	   alpha:1.0]];
	
	//Select the previously selected row
	int row = [[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
														group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if (row < 0 || row >= [tableView_categories numberOfRows]) row = 1;
	
	[tableView_categories selectRow:row byExtendingSelection:NO];
	[self tableViewSelectionDidChange:nil];
}

/*!
* @brief Return the number of accounts
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self advancedCategoryArray] count];
}

/*!
* @brief Return the account description or image
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [[[self advancedCategoryArray] objectAtIndex:row] label];
}

/*!
* @brief Set the category image before the cell is displayed
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[cell setImage:[[[self advancedCategoryArray] objectAtIndex:row] image]];
	[cell setSubString:nil];
}

/*!
* @brief Update our advanced preferences for the selected pane
 */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int row = [tableView_categories selectedRow];

	if (row >= 0 && row < [[self advancedCategoryArray] count]) {		
		[self configureAdvancedPreferencesForPane:[[self advancedCategoryArray] objectAtIndex:row]];
	}
}

@end
