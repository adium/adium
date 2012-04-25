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

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AISoundController.h"
#import <ShortcutRecorder/SRRecorderControl.h>
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import "SGHotKeyCenter.h"
#import "SGHotKey.h"
#import "SGHotKey.h"
#import "AIMessageWindowController.h"
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AILogByAccountWindowController.h"
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
	
    self.shortcutRecorder = [[[SRRecorderControl alloc] initWithFrame:placeholder_shortcutRecorder.frame] autorelease];
    shortcutRecorder.delegate = self;
    [[placeholder_shortcutRecorder superview] addSubview:shortcutRecorder];

	//Global hotkey
	TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();
	
	if (TISGetInputSourceProperty(currentLayout, kTISPropertyUnicodeKeyLayoutData)) {
		SGKeyCombo *keyCombo = [[[SGKeyCombo alloc] initWithPlistRepresentation:[adium.preferenceController preferenceForKey:KEY_GENERAL_HOTKEY
																														 group:PREF_GROUP_GENERAL]] autorelease];
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

- (void)localizePane
{
	[label_confirmations setLocalizedString:AILocalizedString(@"Confirmations:", nil)];
	[label_globalShortcut setLocalizedString:AILocalizedString(@"Global Shortcut:", nil)];
	[label_IMLinks setLocalizedString:AILocalizedString(@"Open IM links:", nil)];
	[label_status setLocalizedString:AILocalizedString(@"Status:", nil)];
	[label_updates setLocalizedString:AILocalizedString(@"Updates:", nil)];
	
	[button_defaultApp setLocalizedString:AILocalizedString(@"Make Adium default application", nil)];
	[button_customizeDefaultApp setLocalizedString:AILocalizedString(@"Customize…", nil)];
	
	[checkbox_showInMenu setLocalizedString:AILocalizedString(@"Show Adium's status in the menu bar", nil)];
	[checkbox_updatesAutomatic setLocalizedString:AILocalizedString(@"Automatically check for updates", nil)];
	[checkbox_updatesIncludeBetas setLocalizedString:AILocalizedString(@"Update to beta versions when available", nil)];
	[checkbox_updatesProfileInfo setLocalizedString:AILocalizedString(@"Include anonymous system profile", nil)];
	[checkbox_confirmBeforeQuitting setLocalizedString:AILocalizedString(@"Confirm before quitting Adium", "Quit Confirmation preference")];
	[checkbox_quitConfirmFT setLocalizedString:AILocalizedString(@"File transfers are in progress", "Quit Confirmation preference")];
	[checkbox_quitConfirmUnread setLocalizedString:AILocalizedString(@"There are unread messages", "Quit Confirmation preference")];
	[checkbox_quitConfirmOpenChats setLocalizedString:AILocalizedString(@"There are open chat windows", "Quit Confirmation preference")];
	[[matrix_quitConfirmType cellWithTag:AIQuitConfirmAlways] setTitle:AILocalizedString(@"Always","Confirmation preference")];
	[[matrix_quitConfirmType cellWithTag:AIQuitConfirmSelective] setTitle:[AILocalizedString(@"Only when","Quit Confirmation preference") stringByAppendingEllipsis]];
	
	[checkbox_confirmBeforeClosing setLocalizedString:AILocalizedString(@"Confirm before closing multiple chat windows", "Message close confirmation preference")];
	[[matrix_closeConfirmType cellWithTag:AIMessageCloseAlways] setTitle:AILocalizedString(@"Always", "Confirmation preference")];
	[[matrix_closeConfirmType cellWithTag:AIMessageCloseUnread] setTitle:AILocalizedString(@"Only when there are unread messages", "Message close confirmation preference")];
}

- (void)dealloc
{
    self.shortcutRecorder = nil;

    [super dealloc];
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

/*!
 * @brief Construct our menu by hand for easy localization
 */
- (NSMenu *)tabChangeKeysMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
#define PLACE_OF_INTEREST_SIGN	"\u2318"
#define LEFTWARDS_ARROW			"\u2190"
#define RIGHTWARDS_ARROW		"\u2192"
#define SHIFT_ARROW				"\u21E7"
#define OPTION_KEY				"\u2325"
#define TAB_KEY					"\u21E5"
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Ctrl + Tab (%@ and %@)","Ctrl/Ctrl+Shift + Tab key word"),
							[NSString stringWithUTF8String:"^" TAB_KEY],
							[NSString stringWithUTF8String:"^" SHIFT_ARROW TAB_KEY]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AICtrlTab];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Arrows (%@ and %@)","Directional arrow keys word"),
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW],
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Shift + Arrows (%@ and %@)","Shift key word + Directional arrow keys word"),
							[NSString stringWithUTF8String:SHIFT_ARROW PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW],
							[NSString stringWithUTF8String:SHIFT_ARROW PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchShiftArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Option + Arrows (%@ and %@)","Option key word + Directional arrow keys word"),
							[NSString stringWithUTF8String:OPTION_KEY PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW],
							[NSString stringWithUTF8String:OPTION_KEY PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIOptArrows];	
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Brackets (%@ and %@)","Word for [ and ] keys"),
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "["],
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "]"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBrackets];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Curly braces (%@ and %@)","Word for { and } keys"),
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "{"],
							[NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "}"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBraces];
	
	return [menu autorelease];		
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

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
	[sheet.windowController release];
}

- (IBAction)customizeDefaultApp:(id)sender
{
	AIURLHandlerWindowController *windowController = [[AIURLHandlerWindowController alloc] initWithWindowNibName:@"AIURLHandlerPreferences"];
	
	[NSApp beginSheet:windowController.window
	   modalForWindow:self.view.window
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}
@end
