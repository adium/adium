//
//  AIMentionAdvancedPreferences.m
//  Adium
//
//  Created by Zachary West on 2009-03-31.
//

#import "AIMentionAdvancedPreferences.h"
#import "AIPreferenceWindowController.h"

#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

#define PREF_KEY_MENTIONS		@"Saved Mentions"

@interface AIMentionAdvancedPreferences()
- (void)saveTerms;
@end

@implementation AIMentionAdvancedPreferences

#pragma mark Preference pane settings
- (AIPreferenceCategory)category
{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Mention",nil);
}
- (NSString *)nibName{
    return @"AIMentionAdvancedPreferences";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-events" forClass:[AIPreferenceWindowController class]];
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
	
	NSInteger index = mentionTerms.count-1;
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[tableView editColumn:0 row:index withEvent:nil select:YES];
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
	[label_explanation setLocalizedString:AILocalizedString(@"Messages are highlighted when the following terms are spoken. Your username is always highlighted.", nil)];
	
	mentionTerms = [[NSMutableArray alloc] initWithArray:[adium.preferenceController preferenceForKey:PREF_KEY_MENTIONS group:PREF_GROUP_GENERAL]];
	
	[super viewDidLoad];
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

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"text"]) {
		[mentionTerms setObject:object atIndex:row];
		[self saveTerms];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self remove:nil];
}

@end
