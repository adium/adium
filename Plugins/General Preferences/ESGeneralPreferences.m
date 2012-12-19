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

#import <ShortcutRecorder/SRRecorderControl.h>
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import "SGHotKey.h"
#import "AIMessageWindowController.h"
#import <AIUtilities/AIImageAdditions.h>
#import "AIURLHandlerPlugin.h"
#import "AIURLHandlerWindowController.h"

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_TABBAR_POSITION					@"Tab Bar Position"

@implementation ESGeneralPreferences

@synthesize shortcutRecorder;

// XXX in order to edit the nib, you need the ShortcutReporter palette
// You can download it at http://evands.penguinmilitia.net/ShortcutRecorder.palette.zip
// This comes from http://wafflesoftware.net/shortcut/

+ (NSSet *)keyPathsForValuesAffectingChatHistoryDisplayActive
{
	return [NSSet setWithObjects:@"adium.preferenceController.Logging.Enable Logging",
			@"adium.preferenceController.Message Context Display.Display Message Context",
			nil];
}

//Preference pane properties
- (AIPreferenceCategory)category{
	return AIPref_General;
}
- (NSString *)paneIdentifier
{
	return @"General";
}
- (NSString *)paneName{	
    return AILocalizedString(@"General","General preferences label");
}
- (NSString *)nibName{
    return @"Preferences-General";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-general" forClass:[self class]];
}

//Configure the preference view
- (void)viewDidLoad
{
	// Update Checking
	[checkbox_updatesProfileInfo setEnabled:[checkbox_updatesAutomatic state]];
#ifdef BETA_RELEASE
	[checkbox_updatesIncludeBetas setEnabled:NO];
	[checkbox_updatesIncludeBetas setState:NSOnState];
#else
	[checkbox_updatesIncludeBetas setEnabled:[checkbox_updatesAutomatic state]];
#endif

    self.shortcutRecorder = [[SRRecorderControl alloc] initWithFrame:placeholder_shortcutRecorder.frame];
    shortcutRecorder.delegate = self;
    [[placeholder_shortcutRecorder superview] addSubview:shortcutRecorder];

	//Global hotkey
	TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();
	
	if (TISGetInputSourceProperty(currentLayout, kTISPropertyUnicodeKeyLayoutData)) {
		SGKeyCombo *keyCombo = [[SGKeyCombo alloc] initWithPlistRepresentation:[adium.preferenceController preferenceForKey:KEY_GENERAL_HOTKEY
																														 group:PREF_GROUP_GENERAL]];
		[shortcutRecorder setKeyCombo:SRMakeKeyCombo([keyCombo keyCode], [shortcutRecorder carbonToCocoaFlags:[keyCombo modifiers]])];
		[shortcutRecorder setAnimates:YES];
		[shortcutRecorder setStyle:SRGreyStyle];
		
		[label_shortcutRecorder setLocalizedString:AILocalizedString(@"When pressed, this key combination will bring Adium to the front", nil)];
	} else {
		[shortcutRecorder setEnabled:NO];
		
		[label_shortcutRecorder setLocalizedString:AILocalizedString(@"You are using an old-style (rsrc) keyboard layout which Adium does not support.", nil)];
	}
	
	CFRelease(currentLayout);

    [self configureControlDimming];
}


//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if (sender == matrix_quitConfirmType || sender == checkbox_confirmBeforeQuitting)
		[self configureControlDimming];
}

//Dim controls as needed
- (void)configureControlDimming
{
	BOOL confirmQuitEnabled = (checkbox_confirmBeforeQuitting.state == NSOnState);
	BOOL enableSpecificConfirmations = (confirmQuitEnabled && [[matrix_quitConfirmType selectedCell] tag] == AIQuitConfirmSelective);
	[checkbox_quitConfirmFT setEnabled:enableSpecificConfirmations];
	[checkbox_quitConfirmUnread setEnabled:enableSpecificConfirmations];
	[checkbox_quitConfirmOpenChats setEnabled:enableSpecificConfirmations];
	
	[checkbox_updatesProfileInfo setEnabled:[checkbox_updatesAutomatic state]];
#ifdef BETA_RELEASE
	[checkbox_updatesIncludeBetas setEnabled:NO];
	[checkbox_updatesIncludeBetas setState:NSOnState];
#else
	[checkbox_updatesIncludeBetas setEnabled:[checkbox_updatesAutomatic state]];
#endif
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (aRecorder == shortcutRecorder) {
		SGKeyCombo *keyCombo = [SGKeyCombo keyComboWithKeyCode:[shortcutRecorder keyCombo].code
													 modifiers:[shortcutRecorder cocoaToCarbonFlags:[shortcutRecorder keyCombo].flags]];
		[adium.preferenceController setPreference:[keyCombo plistRepresentation]
											 forKey:KEY_GENERAL_HOTKEY
											  group:PREF_GROUP_GENERAL];
	}
}

- (IBAction)setAsDefaultApp:(id)sender
{
	[[AIURLHandlerPlugin sharedAIURLHandlerPlugin] setAdiumAsDefault];
}

- (IBAction)customizeDefaultApp:(id)sender
{
	AIURLHandlerWindowController *windowController = [[AIURLHandlerWindowController alloc] initWithWindowNibName:@"AIURLHandlerPreferences"];
	
	[windowController showOnWindow:self.view.window];
}

@end
