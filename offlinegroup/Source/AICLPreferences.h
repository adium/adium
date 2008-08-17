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

#import <Adium/AIPreferencePane.h>

#define	PREF_GROUP_CONTACT_LIST			@"Contact List"

@interface AICLPreferences : AIPreferencePane {
	IBOutlet	NSTableView		*tableView_layout;
	IBOutlet	NSTableView		*tableView_theme;
	
	IBOutlet	NSButton		*button_layoutDelete;
	IBOutlet	NSButton		*button_themeDelete;
	IBOutlet	NSButton		*button_layoutEdit;
	IBOutlet	NSButton		*button_themeEdit;
	
	NSString	*currentLayoutName;
	NSString	*currentThemeName;
	
	NSArray		*layoutArray;
	NSArray		*themeArray;

	NSImage		*layoutStandard;
	NSImage		*layoutBorderless;
	NSImage		*layoutMockie;
	NSImage		*layoutPillows;
}

- (void)xtrasChanged:(NSNotification *)notification;
- (void)updateLayouts;
- (void)updateThemes;
- (void)updateSelectedLayoutAndTheme;

//Editing
- (IBAction)spawnLayout:(id)sender;
- (IBAction)spawnTheme:(id)sender;
- (IBAction)editTheme:(id)sender;
- (IBAction)editLayout:(id)sender;
- (IBAction)deleteLayout:(id)sender;
- (IBAction)deleteTheme:(id)sender;

//Table Delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
