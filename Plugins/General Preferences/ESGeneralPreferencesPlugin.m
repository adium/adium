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

/* 
 General Preferences. Currently responsible for:
	- Logging enable/disable
	- Message sending key (enter, return)
	- Message tabs (create in tabs, organize tabs by group, sort tabs)
	- Tab switching keys
	- Sound:
		- Volume
	- Status icon packs
 
 In the past, these various items were with specific plugins.  While this provides a nice level of abstraction,
 it also makes it much more difficult to ensure a consistent look/feel to the preferences.
*/

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "ESGeneralPreferences.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISendingTextView.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#import "SGHotKey.h"
#import "SGHotKeyCenter.h"

#define	TAB_DEFAULT_PREFS			@"TabDefaults"

#define	SENDING_KEY_DEFAULT_PREFS	@"SendingKeyDefaults"

#define CONFIRMATION_DEFAULT_PREFS	@"ConfirmationDefaults"

@implementation ESGeneralPreferencesPlugin

- (void)installPlugin
{
	//Defaults
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:TAB_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_INTERFACE];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_GENERAL];
	
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONFIRMATION_DEFAULT_PREFS
																		forClass:[self class]]
                                          forGroup:PREF_GROUP_CONFIRMATIONS];
	
	//Install our preference view
	preferences = (ESGeneralPreferences *)[ESGeneralPreferences preferencePaneForPlugin:self];	
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
}

- (void)uninstallPlugin
{

}

- (void)hitHotKey:(SGHotKey *)hotKey
{
	if (![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
        //Switch to the appropriate window, just like clicking the dock; this method will handle switching to a chat with unviewed content, for example.
        [adium.interfaceController handleReopenWithVisibleWindows:NO];

        //Now ensure that all Adium windows are visible
        [NSApp unhide:nil];
	} else {
        [NSApp hide:self];
    }
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || [key isEqualToString:KEY_GENERAL_HOTKEY]) {
		if (globalHotKey) {
			//Unregister the old global hot key if it exists
			[[SGHotKeyCenter sharedCenter] unregisterHotKey:globalHotKey];
			globalHotKey = nil;
		}
		
		id plistRepresentation = [prefDict objectForKey:KEY_GENERAL_HOTKEY];
		if (plistRepresentation) {
			//Register a new one if we want one
			globalHotKey = [[SGHotKey alloc] initWithIdentifier:KEY_GENERAL_HOTKEY
													   keyCombo:[[SGKeyCombo alloc] initWithPlistRepresentation:plistRepresentation]];
			
			[globalHotKey setTarget:self];
			[globalHotKey setAction:@selector(hitHotKey:)];

			[[SGHotKeyCenter sharedCenter] registerHotKey:globalHotKey];
		} 
	}
}

@end
