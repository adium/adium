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
    IBOutlet	NSButton		*checkBox_messagesInTabs;
    IBOutlet	NSButton		*checkBox_arrangeByGroup;
	IBOutlet	NSButton		*checkBox_updatesAutomatic;
	IBOutlet	NSButton		*checkBox_updatesProfileInfo;	
	IBOutlet	NSButton		*checkBox_updatesIncludeBetas;
	
	IBOutlet	NSPopUpButton	*popUp_tabKeys;
	IBOutlet	NSPopUpButton	*popUp_sendKeys;
	IBOutlet	NSPopUpButton	*popUp_tabPositionMenu;

	IBOutlet	NSTextField		*label_logging;
	IBOutlet	NSTextField		*label_messagesSendOn;
	IBOutlet	NSTextField		*label_messagesTabs;
	IBOutlet	NSTextField		*label_switchTabsWith;	
	
	IBOutlet	NSTextField		*label_shortcutRecorder;

    IBOutlet    NSView          *placeholder_shortcutRecorder;
    SRRecorderControl           *shortcutRecorder;		
}

- (IBAction)configureLogCertainAccounts:(id)sender;

@property (nonatomic, retain) SRRecorderControl *shortcutRecorder;

@end
