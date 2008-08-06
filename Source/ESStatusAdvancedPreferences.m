//
//  ESStatusAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import "CBStatusMenuItemPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if (sender == matrix_quitConfirmation || sender == checkBox_quitConfirmEnabled) {
		[self configureControlDimming];
	}
}

- (void)configureControlDimming
{
	BOOL		confirmQuitEnabled			= ([checkBox_quitConfirmEnabled state] == NSOnState);
	BOOL		enableSpecificConfirmations = (confirmQuitEnabled && [[matrix_quitConfirmation selectedCell] tag] == AIQuitConfirmSelective);
	
	[matrix_quitConfirmation		setEnabled:confirmQuitEnabled];
	[checkBox_quitConfirmFT			setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmUnread		setEnabled:enableSpecificConfirmations];
	[checkBox_quitConfirmOpenChats	setEnabled:enableSpecificConfirmations];
}

//Configure the preference view
- (void)viewDidLoad
{
	[checkBox_unreadConversations setLocalizedString:AILocalizedString(@"Count unread conversations instead of unread messages", nil)];
	
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];
	
	[label_statusMenuItem setLocalizedString:AILocalizedString(@"Status Menu Item", nil)];
	[checkBox_statusMenuItemBadge setLocalizedString:AILocalizedString(@"Badge the menu item with current status", nil)];
	[checkBox_statusMenuItemFlash setLocalizedString:AILocalizedString(@"Flash when there are unread messages", nil)];
	[checkBox_statusMenuItemCount setLocalizedString:AILocalizedString(@"Show unread message count in the menu bar", nil)];
	
	[label_quitConfirmation setLocalizedString:AILocalizedString(@"Quit Confirmation", @"Preference")];
	[checkBox_quitConfirmEnabled setLocalizedString:AILocalizedString(@"Confirm before quitting Adium", @"Quit Confirmation preference")];
	[checkBox_quitConfirmFT setLocalizedString:AILocalizedString(@"File transfers are in progress", @"Quit Confirmation preference")];
	[checkBox_quitConfirmUnread setLocalizedString:AILocalizedString(@"There are unread messages", @"Quit Confirmation preference")];
	[checkBox_quitConfirmOpenChats setLocalizedString:AILocalizedString(@"There are open chat windows", @"Quit Confirmation preference")];
	
	[[matrix_quitConfirmation cellWithTag:AIQuitConfirmAlways] setTitle:AILocalizedString(@"Always",@"Quit Confirmation preference")];
	[[matrix_quitConfirmation cellWithTag:AIQuitConfirmSelective] setTitle:[AILocalizedString(@"Only when",@"Quit Confirmation preference") stringByAppendingEllipsis]];
	
	[self configureControlDimming];
	
	[super viewDidLoad];
}


@end
