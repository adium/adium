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

@class SRRecorderControl;

@interface ESGeneralPreferences : AIPreferencePane {
	IBOutlet	AILocalizationTextField *label_status;
	IBOutlet	AILocalizationTextField *label_globalShortcut;
	IBOutlet	AILocalizationTextField *label_updates;
	IBOutlet	AILocalizationTextField *label_IMLinks;
	IBOutlet	AILocalizationTextField *label_confirmations;
	IBOutlet	AILocalizationTextField *label_shortcutRecorder;
	
	IBOutlet	AILocalizationButton *checkbox_showInMenu;
	IBOutlet	AILocalizationButton *checkbox_updatesAutomatic;
	IBOutlet	AILocalizationButton *checkbox_updatesProfileInfo;
	IBOutlet	AILocalizationButton *checkbox_updatesIncludeBetas;
	IBOutlet	AILocalizationButton *button_defaultApp;
	IBOutlet	AILocalizationButton *button_customizeDefaultApp;
	IBOutlet	AILocalizationButton *button_resetAllWarnings;

	IBOutlet    NSView *placeholder_shortcutRecorder;
	
	SRRecorderControl           *shortcutRecorder;
}

@property (nonatomic, retain) SRRecorderControl *shortcutRecorder;
- (IBAction)setAsDefaultApp:(id)sender;
- (IBAction)customizeDefaultApp:(id)sender;
- (IBAction)resetAllWarnings:(id)sender;

@end
