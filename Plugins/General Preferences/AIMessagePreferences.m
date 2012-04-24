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

#import "AIMessagePreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import "AIMessageWindowController.h"
#import "AILogByAccountWindowController.h"
#import "AIWebKitMessageViewPlugin.h"

#define KEY_TABBAR_POSITION					@"Tab Bar Position"
#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"

@interface AIMessagePreferences ()
- (NSMenu *)tabChangeKeysMenu;
- (NSMenu *)sendKeysMenu;
- (NSMenu *)tabPositionMenu;
@end

@implementation AIMessagePreferences

+ (NSSet *)keyPathsForValuesAffectingChatHistoryDisplayActive
{
	return [NSSet setWithObjects:@"adium.preferenceController.Logging.Enable Logging",
			@"adium.preferenceController.Message Context Display.Display Message Context",
			nil];
}

//Preference pane properties
- (AIPreferenceCategory)category
{
	return AIPref_General;
}
- (NSString *)paneIdentifier
{
	return @"Messages";
}
- (NSString *)paneName{	
    return AILocalizedString(@"Messages", nil);
}
- (NSString *)nibName{
    return @"Preferences-Messages";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-messages" forClass:[self class]];
}

//Configure the preference view
- (void)viewDidLoad
{
	BOOL			sendOnEnter, sendOnReturn;
	
	//Chat Cycling
	[popUp_tabKeys setMenu:[self tabChangeKeysMenu]];
	[popUp_tabKeys selectItemWithTag:[[adium.preferenceController preferenceForKey:KEY_TAB_SWITCH_KEYS
																			 group:PREF_GROUP_CHAT_CYCLING] intValue]];
	
	//General
	sendOnEnter = [[adium.preferenceController preferenceForKey:SEND_ON_ENTER
														  group:PREF_GROUP_GENERAL] boolValue];
	sendOnReturn = [[adium.preferenceController preferenceForKey:SEND_ON_RETURN
														   group:PREF_GROUP_GENERAL] boolValue];
	[popUp_sendKeys setMenu:[self sendKeysMenu]];
	
	if (sendOnEnter && sendOnReturn) {
		[popUp_sendKeys selectItemWithTag:AISendOnBoth];
	} else if (sendOnEnter) {
		[popUp_sendKeys selectItemWithTag:AISendOnEnter];			
	} else if (sendOnReturn) {
		[popUp_sendKeys selectItemWithTag:AISendOnReturn];
	}
	
	[popUp_tabPositionMenu setMenu:[self tabPositionMenu]];
	[popUp_tabPositionMenu selectItemWithTag:[[adium.preferenceController preferenceForKey:KEY_TABBAR_POSITION
																					 group:PREF_GROUP_DUAL_WINDOW_INTERFACE] intValue]];
	
    [self configureControlDimming];
}

- (void)localizePane
{
	[label_messages setLocalizedString:AILocalizedString(@"Messages:", nil)];
	[label_recentMessages setLocalizedString:AILocalizedString(@" recent messages in new chats", nil)];
	[label_sendWith setLocalizedString:AILocalizedString(@"Send with:", nil)];
	[label_showTabs setLocalizedString:AILocalizedString(@"Show tabs on the:", nil)];
	[label_switchTabs setLocalizedString:AILocalizedString(@"Switch tabs with:", nil)];
	[label_tabs setLocalizedString:AILocalizedString(@"Tabs:", nil)];
	
	[button_logCertainChats setLocalizedString:AILocalizedString(@"Customize…", nil)];
	
	[checkbox_logCertainAccounts setLocalizedString:AILocalizedString(@"Log only certain accounts", nil)];
	[checkbox_logMessages setLocalizedString:AILocalizedString(@"Log messages", nil)];
	[checkbox_logSecureChats setLocalizedString:AILocalizedString(@"Log secure chats", nil)];
	[checkbox_organizeTabs setLocalizedString:AILocalizedString(@"Organize tabs into new windows by group", nil)];
	[checkbox_psychicOpen setLocalizedString:AILocalizedString(@"Open chats as soon as contacts begin typing", nil)];
	[checkbox_reopenChats setLocalizedString:AILocalizedString(@"Reopen chats from last time on startup", nil)];
	[checkbox_showHistory setLocalizedString:AILocalizedString(@"Show", nil)];
	[checkbox_showTabs setLocalizedString:AILocalizedString(@"Always show tab bar", nil)];
	[checkbox_useTabs setLocalizedString:AILocalizedString(@"Create new chats in tabs", nil)];
}

- (IBAction)changePreference:(id)sender
{
    if (sender == popUp_tabKeys) {
		AITabKeys keySelect = (AITabKeys)[[sender selectedItem] tag];
		
		[adium.preferenceController setPreference:[NSNumber numberWithInt:keySelect]
										   forKey:KEY_TAB_SWITCH_KEYS
											group:PREF_GROUP_CHAT_CYCLING];
		
	} else if (sender == popUp_sendKeys) {
		AISendKeys 	keySelect = (AISendKeys)[[sender selectedItem] tag];
		BOOL		sendOnEnter = (keySelect == AISendOnEnter || keySelect == AISendOnBoth);
		BOOL		sendOnReturn = (keySelect == AISendOnReturn || keySelect == AISendOnBoth);
		
		[adium.preferenceController setPreference:[NSNumber numberWithInt:sendOnEnter]
										   forKey:SEND_ON_ENTER
											group:PREF_GROUP_GENERAL];
		[adium.preferenceController setPreference:[NSNumber numberWithInt:sendOnReturn]
										   forKey:SEND_ON_RETURN
											group:PREF_GROUP_GENERAL];
	}
	
	[self configureControlDimming];
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
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Arrows (%@ and %@)","Directional arrow keys word"), [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW], [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Shift + Arrows (%@ and %@)","Shift key word + Directional arrow keys word"), [NSString stringWithUTF8String:SHIFT_ARROW PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW], [NSString stringWithUTF8String:SHIFT_ARROW PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISwitchShiftArrows];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Option + Arrows (%@ and %@)","Option key word + Directional arrow keys word"), [NSString stringWithUTF8String:OPTION_KEY PLACE_OF_INTEREST_SIGN LEFTWARDS_ARROW], [NSString stringWithUTF8String:OPTION_KEY PLACE_OF_INTEREST_SIGN RIGHTWARDS_ARROW]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIOptArrows];	
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Brackets (%@ and %@)","Word for [ and ] keys"), [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "["], [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "]"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBrackets];
	
	[menu addItemWithTitle:[NSString stringWithFormat:AILocalizedString(@"Curly braces (%@ and %@)","Word for { and } keys"), [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "{"], [NSString stringWithUTF8String:PLACE_OF_INTEREST_SIGN "}"]]
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AIBraces];
	
	
	return [menu autorelease];		
}

- (NSMenu *)sendKeysMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItemWithTitle:AILocalizedString(@"Enter","Enter key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnEnter];
	
	[menu addItemWithTitle:AILocalizedString(@"Return","Return key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnReturn];
	
	[menu addItemWithTitle:AILocalizedString(@"Enter and Return","Enter and return key for sending messages")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AISendOnBoth];
	
	return [menu autorelease];		
}

- (NSMenu *)tabPositionMenu
{
	NSMenu		*menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItemWithTitle:AILocalizedString(@"Top","Position menu item for tabs at the top of the message window")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AdiumTabPositionTop];
	
	[menu addItemWithTitle:AILocalizedString(@"Bottom","Position menu item for tabs at the bottom of the message window")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AdiumTabPositionBottom];
	
	[menu addItemWithTitle:AILocalizedString(@"Left","Position menu item for tabs at the left of the message window")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AdiumTabPositionLeft];
	
	[menu addItemWithTitle:AILocalizedString(@"Right","Position menu item for tabs at the right of the message window")
					target:nil
					action:nil
			 keyEquivalent:@""
					   tag:AdiumTabPositionRight];
	
	return [menu autorelease];
}

- (BOOL)chatHistoryDisplayActive
{
	return ([[adium.preferenceController preferenceForKey:@"Display Message Context" group:@"Message Context Display"] boolValue] &&
			[[adium.preferenceController preferenceForKey:@"Enable Logging" group:@"Logging"] boolValue]);
}
- (void)setChatHistoryDisplayActive:(BOOL)flag
{
	[adium.preferenceController setPreference:[NSNumber	numberWithBool:flag]
									   forKey:@"Display Message Context"
										group:@"Message Context Display"];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
	[sheet.windowController release];
}
- (IBAction)configureLogCertainAccounts:(id)sender
{
	AILogByAccountWindowController *windowController = [[AILogByAccountWindowController alloc] initWithWindowNibName:@"AILogByAccountWindow"];
	
	[NSApp beginSheet:windowController.window
	   modalForWindow:self.view.window
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

@end
