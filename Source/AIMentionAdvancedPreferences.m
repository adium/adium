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

#import "AIMentionAdvancedPreferences.h"
#import "AIPreferenceWindowController.h"

#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

@interface AIMentionAdvancedPreferences()
- (void)saveTerms;
@end

@implementation AIMentionAdvancedPreferences

#pragma mark Preference pane settings
- (AIPreferenceCategory)category
{
    return AIPref_Events;
}
- (NSString *)paneIdentifier{
	return @"MentionAdvanced";
}
- (NSString *)paneName{
    return AILocalizedString(@"Mention",nil);
}
- (NSString *)nibName{
    return @"AIMentionAdvancedPreferences";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-mention" forClass:[AIPreferenceWindowController class]];
}

- (void)saveTerms
{
	NSMutableArray *termsCopy = [[mentionTerms mutableCopy] autorelease];
	
	// Never save a blank term.
	[termsCopy removeObject:@""];
	
	[adium.preferenceController setPreference:termsCopy
									   forKey:PREF_KEY_MENTIONS
										group:PREF_GROUP_GENERAL];
}

/*!
 * @brief Add a new row, select it for editing
 */
- (IBAction)add:(id)sender
{
	[mentionTerms addObject:@""];
	
	[tableView reloadData];
	
	NSInteger idx = mentionTerms.count-1;
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	[tableView editColumn:0 row:idx withEvent:nil select:YES];
}

/*!
 * @brief Remove the selected rows
 */
- (IBAction)remove:(id)sender
{
	NSIndexSet *indexes = [tableView selectedRowIndexes];
	
	[mentionTerms removeObjectsAtIndexes:indexes];
	[self saveTerms];
	
	[tableView reloadData];
	[tableView deselectAll:nil];
}

/*!
 * @brief The view loaded
 */
- (void)viewDidLoad
{
	mentionTerms = [[NSMutableArray alloc] initWithArray:[adium.preferenceController preferenceForKey:PREF_KEY_MENTIONS group:PREF_GROUP_GENERAL]];
	
	[super viewDidLoad];
}

- (void)localizePane
{
	[label_explanation setStringValue:AILocalizedString(@"Messages are highlighted when the following terms are spoken. Your username is always highlighted.", nil)];
}

- (void)viewWillClose
{
	[mentionTerms release]; mentionTerms = nil;
	
	[super viewWillClose];
}

#pragma mark Table view Delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return mentionTerms.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"text"]) {
		return [mentionTerms objectAtIndex:rowIndex];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"text"]) {
		[mentionTerms replaceObjectAtIndex:row withObject:object];
		[self saveTerms];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self remove:nil];
}

@end
