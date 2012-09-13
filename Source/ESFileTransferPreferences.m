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

#import "ESFileTransferPreferences.h"
#import "ESFileTransferController.h"
#import "AILocalizationButton.h"
#import "AILocalizationTextField.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation ESFileTransferPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
	return AIPref_Advanced;
}
- (NSString *)paneIdentifier
{
	return @"File Transfer";
}
- (NSString *)paneName{
	return AILocalizedString(@"File Transfer", nil);
}
- (NSString *)nibName{
    return @"FileTransferPrefs";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-file-transfer" forClass:[self class]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if ((sender == checkBox_autoAcceptFiles) ||
		(sender == checkBox_autoAcceptOnlyFromCLList)) {
		AIFileTransferAutoAcceptType autoAcceptType;
		
		if ([checkBox_autoAcceptFiles state] == NSOffState) {
			autoAcceptType = AutoAccept_None;
		} else {
			if ([checkBox_autoAcceptOnlyFromCLList state] == NSOnState) {
				autoAcceptType = AutoAccept_FromContactList;
			} else {
				autoAcceptType = AutoAccept_All;
			}
		}
		
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:autoAcceptType]
                                             forKey:KEY_FT_AUTO_ACCEPT
                                              group:PREF_GROUP_FILE_TRANSFER];
	}
}

//Configure the preference view
- (void)viewDidLoad
{
	AIFileTransferAutoAcceptType	autoAcceptType = [[adium.preferenceController preferenceForKey:KEY_FT_AUTO_ACCEPT
																				   group:PREF_GROUP_FILE_TRANSFER] intValue];
	
	
	switch (autoAcceptType) {
		case AutoAccept_None:
			[checkBox_autoAcceptFiles setState:NSOffState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOffState];			
			break;
			
		case AutoAccept_FromContactList:
			[checkBox_autoAcceptFiles setState:NSOnState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOnState];
			break;

		case AutoAccept_All:
			[checkBox_autoAcceptFiles setState:NSOnState];
			[checkBox_autoAcceptOnlyFromCLList setState:NSOffState];
			break;
	}	
}

- (void)localizePane
{
	[label_whenReceivingFiles setLocalizedString:AILocalizedString(@"Receiving files:","File Transfer preferences label")];
	[label_transferProgress setLocalizedString:AILocalizedString(@"Progress:","File Transfer preferences label")];
	
	[checkBox_autoAcceptFiles setLocalizedString:[AILocalizedString(@"Automatically save files to Downloads","File Transfer preferences") stringByAppendingEllipsis]];
	[checkBox_autoAcceptOnlyFromCLList setLocalizedString:AILocalizedString(@"only from contacts on my Contact List","File Transfer preferences")];
	[checkBox_showProgress setLocalizedString:AILocalizedString(@"Show the File Transfers window automatically","File Transfer preferences")];
}

@end
