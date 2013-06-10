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

@interface AIAppearancePreferences : AIPreferencePane <NSMenuDelegate> {
	IBOutlet	NSPopUpButton *popUp_serviceIcons;
	IBOutlet	NSPopUpButton *popUp_statusIcons;
	IBOutlet	NSPopUpButton *popUp_menuBarIcons;
	IBOutlet	NSPopUpButton *popUp_emoticons;
	IBOutlet	NSPopUpButton *popUp_dockIcon;
	
	IBOutlet	NSTextField *label_serviceIcons;
	IBOutlet	NSTextField *label_statusIcons;
	IBOutlet	NSTextField *label_menuBarIcons;
	IBOutlet	NSTextField *label_emoticons;
	IBOutlet	NSTextField *label_dockIcons;
	
	IBOutlet	NSButton *button_emoticons;
	IBOutlet	NSButton *button_dockIcons;
}

- (IBAction)showAllDockIcons:(id)sender;
- (IBAction)customizeEmoticons:(id)sender;
- (void)xtrasChanged:(NSNotification *)notification;

@end
