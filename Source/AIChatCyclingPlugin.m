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

#import "AIChatCyclingPlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>

#define PREVIOUS_MESSAGE_MENU_TITLE		AILocalizedString(@"Previous Chat",nil)
#define NEXT_MESSAGE_MENU_TITLE			AILocalizedString(@"Next Chat",nil)

#define DEFAULT_CHAT_CYCLING_PREFS		@"ChatCyclingDefaults"
#define OLD_DEFAULT_CHAT_CYCLING_PREFS	@"ChatCyclingDefaults-Old"

/*!
 * @class AIChatCyclingPlugin
 * @brief Component to manage the chat cycling menu items
 *
 * Adium supports several different key combinations for switching tabs, configuring via the General Preferences.
 */
@implementation AIChatCyclingPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	id<AIMenuController> menuController = adium.menuController;

	//Cycling menu items
	previousChatMenuItem = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE
													  target:self 
													  action:@selector(previousChat:)
											   keyEquivalent:@""];
	[menuController addMenuItem:previousChatMenuItem toLocation:LOC_Window_Commands];

	nextChatMenuItem = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE 
												  target:self
												  action:@selector(nextChat:)
										   keyEquivalent:@""];
	[menuController addMenuItem:nextChatMenuItem toLocation:LOC_Window_Commands];
		
	/* Adium 1.5.8+ use the new defaults for chat switching, ctrl+tab, to match Safari's default user-visible behavior */
	NSDictionary *defaults = [NSDictionary dictionaryNamed:(([adium compareVersion:adium.earliestLaunchedAdiumVersion
																		 toVersion:@"1.5.8"] == NSOrderedAscending) ?
															OLD_DEFAULT_CHAT_CYCLING_PREFS :
															DEFAULT_CHAT_CYCLING_PREFS)
												  forClass:[self class]];
	[adium.preferenceController registerDefaults:defaults
											forGroup:PREF_GROUP_CHAT_CYCLING];

	//Prefs
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CHAT_CYCLING];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

/*!
 * @brief Preferences changed
 *
 * Update the key equivalents for our previous and next chat menu items
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
	//Configure our tab switching hotkeys
	unichar 		left = NSLeftArrowFunctionKey;
	unichar 		right = NSRightArrowFunctionKey;
	NSString		*leftKey, *rightKey;
	NSUInteger		leftKeyMask = NSCommandKeyMask, rightKeyMask = NSCommandKeyMask;
	
	switch ([[prefDict objectForKey:KEY_TAB_SWITCH_KEYS] integerValue]) {
		case AISwitchArrows:
		default:
			leftKey = [NSString stringWithCharacters:&left length:1];
			rightKey = [NSString stringWithCharacters:&right length:1];
			break;
		case AISwitchShiftArrows:
			leftKey = [NSString stringWithCharacters:&left length:1];
			rightKey = [NSString stringWithCharacters:&right length:1];
			leftKeyMask = rightKeyMask = (NSCommandKeyMask | NSShiftKeyMask);
			break;
		case AIBrackets:
			leftKey = @"[";
			rightKey = @"]";
			break;
		case AIBraces:
			leftKey = @"{";
			rightKey = @"}";
			break;
		case AIOptArrows:
			leftKey = [NSString stringWithCharacters:&left length:1];
			rightKey = [NSString stringWithCharacters:&right length:1];
			leftKeyMask = rightKeyMask = (NSCommandKeyMask | NSAlternateKeyMask);
			break;
		case AICtrlTab:
			leftKey = rightKey = @"\t";
			leftKeyMask = (NSControlKeyMask | NSShiftKeyMask);
			rightKeyMask = NSControlKeyMask;
			break;
	}

	//Previous and nextMessage menuItems are in the same menu, so the setMenuChangedMessagesEnabled applies to both.
	[[previousChatMenuItem menu] setMenuChangedMessagesEnabled:NO];		
	[previousChatMenuItem setKeyEquivalent:@""];
	[previousChatMenuItem setKeyEquivalent:leftKey];
	[previousChatMenuItem setKeyEquivalentModifierMask:leftKeyMask];
	[nextChatMenuItem setKeyEquivalent:@""];
	[nextChatMenuItem setKeyEquivalent:rightKey];
	[nextChatMenuItem setKeyEquivalentModifierMask:rightKeyMask];
	[[previousChatMenuItem menu] setMenuChangedMessagesEnabled:YES];
}

/*!
 * @brief Menu item validation
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (!adium.interfaceController.activeChat) return NO;
	
	NSString *containerID = [adium.interfaceController containerIDForChat:adium.interfaceController.activeChat];
	
	return ([adium.interfaceController openChatsInContainerWithID:containerID].count > 0);
}

/*!
 * @brief Select the next chat
 */
- (IBAction)nextChat:(id)sender
{
	[adium.interfaceController nextChat:nil];
}

/*!
 * @brief Select the previous chat
 */
- (IBAction)previousChat:(id)sender
{
	[adium.interfaceController previousChat:nil];
}	

@end
