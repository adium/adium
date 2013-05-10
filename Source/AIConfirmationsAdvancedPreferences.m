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

#import "AIConfirmationsAdvancedPreferences.h"
#import "AIPreferenceWindowController.h"

#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>

#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

@implementation AIConfirmationsAdvancedPreferences
#pragma mark Preference pane settings
- (AIPreferenceCategory)category
{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Confirmations",nil);
}
- (NSString *)nibName{
    return @"AIConfirmationsAdvancedPreferences";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-confirmations" forClass:[AIPreferenceWindowController class]];
}

/*!
 * @brief The view loaded
 */
- (void)viewDidLoad
{
	[label_quitConfirmation setLocalizedString:AILocalizedString(@"Quit Confirmation", "Preference")];
	[checkBox_confirmBeforeQuitting setLocalizedString:AILocalizedString(@"Confirm before quitting Adium", "Quit Confirmation preference")];
	[checkBox_quitConfirmFT setLocalizedString:AILocalizedString(@"File transfers are in progress", "Quit Confirmation preference")];
	[checkBox_quitConfirmUnread setLocalizedString:AILocalizedString(@"There are unread messages", "Quit Confirmation preference")];
	[checkBox_quitConfirmOpenChats setLocalizedString:AILocalizedString(@"There are open chat windows", "Quit Confirmation preference")];
	[[matrix_quitConfirmType cellWithTag:AIQuitConfirmAlways] setTitle:AILocalizedString(@"Always","Confirmation preference")];
	[[matrix_quitConfirmType cellWithTag:AIQuitConfirmSelective] setTitle:[AILocalizedString(@"Only when","Quit Confirmation preference") stringByAppendingEllipsis]];
	
	[label_messageCloseConfirmation setLocalizedString:AILocalizedString(@"Window Close Confirmation", "Preference")];
	[checkBox_confirmBeforeClosing setLocalizedString:AILocalizedString(@"Confirm before closing multiple chat windows", "Message close confirmation preference")];
	[[matrix_closeConfirmType cellWithTag:AIMessageCloseAlways] setTitle:AILocalizedString(@"Always", "Confirmation preference")];
	[[matrix_closeConfirmType cellWithTag:AIMessageCloseUnread] setTitle:AILocalizedString(@"Only when there are unread messages", "Message close confirmation preference")];
	
	NSDictionary *confirmationDict = [adium.preferenceController preferencesForGroup:PREF_GROUP_CONFIRMATIONS];

	[checkBox_confirmBeforeQuitting setState:[[confirmationDict objectForKey:KEY_CONFIRM_QUIT] boolValue]];
	[matrix_quitConfirmType selectCellWithTag:[[confirmationDict objectForKey:KEY_CONFIRM_QUIT_TYPE] integerValue]];
	[checkBox_quitConfirmFT setState:![[confirmationDict objectForKey:KEY_CONFIRM_QUIT_FT] boolValue]];
	[checkBox_quitConfirmOpenChats setState:![[confirmationDict objectForKey:KEY_CONFIRM_QUIT_OPEN] boolValue]];
	[checkBox_quitConfirmUnread setState:![[confirmationDict objectForKey:KEY_CONFIRM_QUIT_UNREAD] boolValue]];
	
	[checkBox_confirmBeforeClosing setState:[[confirmationDict objectForKey:KEY_CONFIRM_MSG_CLOSE] boolValue]];
	[matrix_closeConfirmType selectCellWithTag:[[confirmationDict objectForKey:KEY_CONFIRM_MSG_CLOSE_TYPE] integerValue]];
	
	[self configureControlDimming];
	
	[super viewDidLoad];
}

- (void)viewWillClose
{	
	[super viewWillClose];
}

- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_confirmBeforeQuitting) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
										   forKey:KEY_CONFIRM_QUIT
											group:PREF_GROUP_CONFIRMATIONS];
		
		[self configureControlDimming];
	}
	
	if (sender == checkBox_quitConfirmFT) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:![sender state]]
										   forKey:KEY_CONFIRM_QUIT_FT
											group:PREF_GROUP_CONFIRMATIONS];
	}
	
	if (sender == checkBox_quitConfirmUnread) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:![sender state]]
										   forKey:KEY_CONFIRM_QUIT_UNREAD
											group:PREF_GROUP_CONFIRMATIONS];		
	}
	
	if (sender == checkBox_quitConfirmOpenChats) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:![sender state]]
										   forKey:KEY_CONFIRM_QUIT_OPEN
											group:PREF_GROUP_CONFIRMATIONS];
	}
	
	if (sender == matrix_quitConfirmType) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedCell] tag]]
								   forKey:KEY_CONFIRM_QUIT_TYPE
									group:PREF_GROUP_CONFIRMATIONS];
		
		[self configureControlDimming];
	}
	
	if (sender == checkBox_confirmBeforeClosing) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
										   forKey:KEY_CONFIRM_MSG_CLOSE
											group:PREF_GROUP_CONFIRMATIONS];		
		
		[self configureControlDimming];		
	}
	
	if (sender == matrix_closeConfirmType) {
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:[[sender selectedCell] tag]]
								   forKey:KEY_CONFIRM_MSG_CLOSE_TYPE
									group:PREF_GROUP_CONFIRMATIONS];		
	}
	
	[self viewDidLoad];
}

- (void)configureControlDimming
{
	BOOL		confirmQuitEnabled			= (checkBox_confirmBeforeQuitting.state == NSOnState);
	BOOL		enableSpecificConfirmations = (confirmQuitEnabled && [[matrix_quitConfirmType selectedCell] tag] == AIQuitConfirmSelective);
	
	[matrix_quitConfirmType	setEnabled:confirmQuitEnabled];
	[checkBox_quitConfirmFT	setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmUnread	setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmOpenChats setEnabled:enableSpecificConfirmations];
	
	BOOL		confirmCloseEnabled			= (checkBox_confirmBeforeClosing.state == NSOnState);
	[matrix_closeConfirmType setEnabled:confirmCloseEnabled];
}

@end
