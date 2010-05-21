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

#import "AICLPreferences.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemePreviewCell.h"
#import "AIListThemeWindowController.h"
#import "AISCLViewPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAbstractListController.h>

//Handles the interface interaction, and sets preference values
//The outline view plugin is responsible for reading & setting the preferences, as well as observing changes in them

@interface AICLPreferences (PRIVATE)
- (void)configureView;
- (void)changeFont:(id)sender;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
- (void)configureControlDimming;

- (void)updateLayouts;
- (void)updateThemes;
- (void)updateSelectedLayoutAndTheme;

- (void)applySet:(NSDictionary *)setDictionary toPreferenceGroup:(NSString *)preferenceGroup;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
@end

@implementation AICLPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return @"General Appearance";
}
- (NSString *)nibName{
    return @"AICLPrefView";
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
	AIImageTextCell *dataCell;

	currentLayoutName = [@"Default" retain];
	currentThemeName = [@"Default" retain];
	[self updateLayouts];
	[self updateThemes];

	//Observe for installation of new themes/layouts
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	
	//Images
	layoutStandard = [[NSImage imageNamed:@"style-standard" forClass:[self class]] retain];
	layoutBorderless = [[NSImage imageNamed:@"style-borderless" forClass:[self class]] retain];
	layoutMockie = [[NSImage imageNamed:@"style-mockie" forClass:[self class]] retain];
	layoutPillows = [[NSImage imageNamed:@"style-pillows" forClass:[self class]] retain];
	
	//
	[button_themeEdit setTitle:@"Edit"];
	[button_layoutEdit setTitle:@"Edit"];
	
	//
	dataCell = [[[AIImageTextCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_layout tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
	
	dataCell = [[[AIGradientCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];	
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_layout tableColumnWithIdentifier:@"preview"] setDataCell:dataCell];

	dataCell = [[[AIImageTextCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_theme tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
	
	//
    [tableView_layout setTarget:self];
	[tableView_layout setDoubleAction:@selector(editLayout:)];
    [tableView_theme setTarget:self];
	[tableView_theme setDoubleAction:@selector(editTheme:)];
}

//Preference view is closing
- (void)viewWillClose
{
	[layoutStandard release]; layoutStandard = nil;
	[layoutBorderless release]; layoutBorderless = nil;
	[layoutMockie release]; layoutMockie = nil;
	[layoutPillows release]; layoutPillows = nil;
	
	[[adium notificationCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[AISCLViewPlugin resetXtrasCache];
}

//Installed xtras have changed
- (void)xtrasChanged:(NSNotification *)notification
{
	if(notification == nil || [[notification object] caseInsensitiveCompare:LIST_LAYOUT_EXTENSION] == 0){
		[AISCLViewPlugin resetXtrasCache];
		[self updateLayouts];
		
	}else if(notification == nil || [[notification object] caseInsensitiveCompare:LIST_THEME_EXTENSION] == 0){
		[AISCLViewPlugin resetXtrasCache];
		[self updateThemes];
	}
}

//Selected theme/layout changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[self updateSelectedLayoutAndTheme];
}

//Update our list of available layouts
- (void)updateLayouts
{
	[layoutArray release];
	layoutArray = [[AISCLViewPlugin availableLayoutSets] retain];
	[tableView_layout reloadData];
	[self updateSelectedLayoutAndTheme];
}

//Update our list of available themes
- (void)updateThemes
{
	[themeArray release];
	themeArray = [[AISCLViewPlugin availableThemeSets] retain];
	[tableView_theme reloadData];
	[self updateSelectedLayoutAndTheme];
}

//Update the selected table rows to match our preferences
- (void)updateSelectedLayoutAndTheme
{
	NSEnumerator	*enumerator;
	NSDictionary	*dict;
	
	[currentLayoutName release];
	[currentThemeName release];
	
	currentLayoutName = [[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME group:PREF_GROUP_CONTACT_LIST] retain];
	currentThemeName = [[adium.preferenceController preferenceForKey:KEY_LIST_THEME_NAME group:PREF_GROUP_CONTACT_LIST] retain];
	
	enumerator = [layoutArray objectEnumerator];
	while((dict = [enumerator nextObject])){
		if([[dict objectForKey:@"name"] isEqualToString:currentLayoutName]){
			[tableView_layout selectRow:[layoutArray indexOfObject:dict] byExtendingSelection:NO];
		}
	}
	
	enumerator = [themeArray objectEnumerator];
	while((dict = [enumerator nextObject])){
		if([[dict objectForKey:@"name"] isEqualToString:currentThemeName]){
			[tableView_theme selectRow:[themeArray indexOfObject:dict] byExtendingSelection:NO];
		}
	}
	
	[self configureControlDimming];
}

- (void)configureControlDimming
{
	[button_layoutEdit setEnabled:([layoutArray count] > 0)];
	[button_layoutDelete setEnabled:([layoutArray count] > 1)];

	[button_themeEdit setEnabled:([themeArray count] > 0)];
	[button_themeDelete setEnabled:([themeArray count] > 1)];
}


//Editing --------------------------------------------------------------------------------------------------------------
#pragma mark Editing
//Create new layout or theme
- (IBAction)spawnLayout:(id)sender
{
	[AIListLayoutWindowController listLayoutOnWindow:[[self view] window]
											withName:[NSString stringWithFormat:@"%@ Copy",currentLayoutName]];
}
- (IBAction)spawnTheme:(id)sender
{
	[AIListThemeWindowController listThemeOnWindow:[[self view] window]
										  withName:[NSString stringWithFormat:@"%@ Copy",currentThemeName]];
}

//Edit a layout or theme
- (IBAction)editTheme:(id)sender
{
	[AIListThemeWindowController listThemeOnWindow:[[self view] window] withName:currentThemeName];
}
- (IBAction)editLayout:(id)sender
{
	[AIListLayoutWindowController listLayoutOnWindow:[[self view] window] withName:currentLayoutName];
}

//Delete a layout
- (IBAction)deleteLayout:(id)sender
{
	if([layoutArray count] > 1){
		NSDictionary	*selected = [layoutArray objectAtIndex:[tableView_layout selectedRow]];
		NSBeginAlertSheet(AILocalizedString(@"Delete Layout",nil), 
						  AILocalizedString(@"Delete",nil), 
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [[self view] window],
						  self,
						  @selector(deleteLayoutSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  selected,
						  AILocalizedString(@"Delete the layout \"%@\" from %@?",nil), 
						  [selected objectForKey:@"name"],
						  [selected objectForKey:@"path"]);
	}
}
- (void)deleteLayoutSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSDictionary *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn && contextInfo){
		NSString *path = [contextInfo objectForKey:@"path"];
		if(path){
			[[NSFileManager defaultManager] trashFileAtPath:path];
			[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed object:LIST_LAYOUT_EXTENSION];
			[self tableView:tableView_layout shouldSelectRow:[tableView_layout selectedRow]];
		}
	}
}

//Delete a theme
- (IBAction)deleteTheme:(id)sender
{
	if([themeArray count] > 1){
		NSDictionary	*selected = [themeArray objectAtIndex:[tableView_theme selectedRow]];
		NSBeginAlertSheet(AILocalizedString(@"Delete Theme",nil), 
						  AILocalizedString(@"Delete",nil), 
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [[self view] window],
						  self,
						  @selector(deleteThemeSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  selected,
						  AILocalizedString(@"Delete the theme \"%@\" from %@?",nil), 
						  [selected objectForKey:@"name"],
						  [selected objectForKey:@"path"]);
	}
}
- (void)deleteThemeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSDictionary *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn && contextInfo){
		NSString *path = [contextInfo objectForKey:@"path"];
		if(path){
			[[NSFileManager defaultManager] trashFileAtPath:path];
			[[adium notificationCenter] postNotificationName:Adium_Xtras_Changed object:LIST_THEME_EXTENSION];
			[self tableView:tableView_theme shouldSelectRow:[tableView_theme selectedRow]];
		}
	}
}


//Table Delegate -------------------------------------------------------------------------------------------------------
#pragma mark Table Delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(tableView == tableView_layout){
		return [layoutArray count];
	}else{
		return [themeArray count];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString	*column = [tableColumn identifier];
	
	if(tableView == tableView_layout){
		NSDictionary	*layoutDict = [layoutArray objectAtIndex:row];
		
		if([column isEqualToString:@"name"]){
			return [layoutDict objectForKey:@"name"];
		}else if([column isEqualToString:@"preview"]){
			return @"-";
		}
	}else if(tableView == tableView_theme){
		NSDictionary	*themeDict = [themeArray objectAtIndex:row];
		
		if([column isEqualToString:@"type"]){
			return @"-";
		}else if([column isEqualToString:@"name"]){
			return [themeDict objectForKey:@"name"];
		}else if([column isEqualToString:@"preview"]){
			return @"-";
		}
	}

	return @"-";
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if(tableView == tableView_layout){
		NSDictionary	*layoutDict = [layoutArray objectAtIndex:row];
		[adium.preferenceController setPreference:[layoutDict objectForKey:@"name"]
											 forKey:KEY_LIST_LAYOUT_NAME
											  group:PREF_GROUP_CONTACT_LIST];
		
	}else if(tableView == tableView_theme){
		NSDictionary	*themeDict = [themeArray objectAtIndex:row];
		[adium.preferenceController setPreference:[themeDict objectForKey:@"name"]
											 forKey:KEY_LIST_THEME_NAME
											  group:PREF_GROUP_CONTACT_LIST];
		
	}
	
	[self updateSelectedLayoutAndTheme];
	
	return YES;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
//	NSString	*column = [tableColumn identifier];
//
//	if(tableView == tableView_layout){
//		if([column isEqualToString:@"name"]){
//			NSImage	*image = nil;
//			switch([[[[layoutArray objectAtIndex:row] objectForKey:@"preferences"] objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]){
//				case WINDOW_STYLE_STANDARD: image = layoutStandard; break;
//				case WINDOW_STYLE_BORDERLESS: image = layoutBorderless; break;
//				case WINDOW_STYLE_MOCKIE: image = layoutMockie; break;
//				case WINDOW_STYLE_PILLOWS: image = layoutPillows; break;
//				case WINDOW_STYLE_PILLOWS_FITTED: image = layoutPillows; break;
//			}
//			[cell setImage:image];
//		}else{
//			[cell setImage:nil];
//		}
//	}else if(tableView == tableView_theme){
//		if([column isEqualToString:@"preview"]){
//			[cell setThemeDict:[[themeArray objectAtIndex:row] objectForKey:@"preferences"]];
//		}		
//	}
}

@end
