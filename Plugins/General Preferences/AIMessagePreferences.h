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

#import "AIPreferencePane.h"

@interface AIMessagePreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton *popUp_sendKeys;
	IBOutlet	NSPopUpButton *popUp_tabKeys;
	IBOutlet	NSPopUpButton *popUp_tabPositionMenu;
	
	IBOutlet	AILocalizationTextField *label_messages;
	IBOutlet	AILocalizationTextField *label_tabs;
	IBOutlet	AILocalizationTextField *label_sendWith;
	IBOutlet	AILocalizationTextField *label_showTabs;
	IBOutlet	AILocalizationTextField *label_switchTabs;
	IBOutlet	AILocalizationTextField *label_recentMessages;
	
	IBOutlet	AILocalizationButton *checkbox_logMessages;
	IBOutlet	AILocalizationButton *checkbox_showHistory;
	IBOutlet	AILocalizationButton *checkbox_logSecureChats;
	IBOutlet	AILocalizationButton *checkbox_logCertainAccounts;
	IBOutlet	AILocalizationButton *checkbox_reopenChats;
	IBOutlet	AILocalizationButton *checkbox_psychicOpen;
	IBOutlet	AILocalizationButton *checkbox_showTabs;
	IBOutlet	AILocalizationButton *checkbox_useTabs;
	IBOutlet	AILocalizationButton *checkbox_organizeTabs;
	IBOutlet	AILocalizationButton *button_logCertainChats;
	
	IBOutlet	NSTextField *textfield_numberOfLines;
	IBOutlet	NSStepper *stepper_numberOfLines;
}

- (IBAction)configureLogCertainAccounts:(id)sender;

@end
