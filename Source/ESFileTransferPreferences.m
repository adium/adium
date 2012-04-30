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

@interface ESFileTransferPreferences ()
- (NSMenu *)downloadLocationMenu;
- (void)buildDownloadLocationMenu;
- (void)selectOtherDownloadFolder:(id)sender;
@end

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
	
	[self buildDownloadLocationMenu];
	
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
	[label_defaultReceivingFolder setLocalizedString:AILocalizedString(@"Save files to:","File Transfer preferences label")];
	[label_safeFilesDescription setLocalizedString:AILocalizedString(@"\"Safe\" files include movies, pictures,\nsounds, text documents, and archives.","Description of safe files (files which Adium can open automatically without danger to the user). This description should be on two lines; the lines are separated by \n.")];
	[label_transferProgress setLocalizedString:AILocalizedString(@"Progress:","File Transfer preferences label")];
	
	[checkBox_autoAcceptFiles setLocalizedString:[AILocalizedString(@"Automatically accept files and images","File Transfer preferences") stringByAppendingEllipsis]];
	[checkBox_autoAcceptOnlyFromCLList setLocalizedString:AILocalizedString(@"only from contacts on my Contact List","File Transfer preferences")];
	[checkBox_autoOpenFiles setLocalizedString:AILocalizedString(@"Open \"Safe\" files after receiving","File Transfer preferences")];
	[checkBox_showProgress setLocalizedString:AILocalizedString(@"Show the File Transfers window automatically","File Transfer preferences")];
	[checkBox_autoClearCompleted setLocalizedString:AILocalizedString(@"Clear completed transfers automatically","File Transfer preferences")];
}

- (void)buildDownloadLocationMenu
{
	[popUp_downloadLocation setMenu:[self downloadLocationMenu]];
	[popUp_downloadLocation selectItem:[popUp_downloadLocation itemAtIndex:0]];
}

- (NSMenu *)downloadLocationMenu
{
	NSMenu		*menu;
	NSMenuItem	*menuItem;
	NSString	*userPreferredDownloadFolder;

	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
	//Create the menu item for the current download folder
	userPreferredDownloadFolder = [adium.preferenceController userPreferredDownloadFolder];
	menuItem = [[NSMenuItem alloc] initWithTitle:[[NSFileManager defaultManager] displayNameAtPath:userPreferredDownloadFolder]
																	 target:nil
																	 action:nil
															  keyEquivalent:@""];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menuItem setImage:[[[NSWorkspace sharedWorkspace] iconForFile:userPreferredDownloadFolder] imageByScalingForMenuItem]];
	[menu addItem:menuItem];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	//Create the menu item for changing the current download folder
	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Other",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(selectOtherDownloadFolder:)
															  keyEquivalent:@""];
	[menuItem setRepresentedObject:userPreferredDownloadFolder];
	[menu addItem:menuItem];
	
	return menu;
}

- (void)selectOtherDownloadFolder:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSString	*userPreferredDownloadFolder = [sender representedObject];

	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	openPanel.directoryURL = [NSURL fileURLWithPath:userPreferredDownloadFolder];
	[openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[adium.preferenceController setUserPreferredDownloadFolder:openPanel.URL. path];
		}
		
		[self buildDownloadLocationMenu];
	}];
}

@end
