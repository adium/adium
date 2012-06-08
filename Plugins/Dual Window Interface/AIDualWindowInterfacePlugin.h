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

#import <Adium/AIInterfaceControllerProtocol.h>

@class AIContactListWindowController, AIDualWindowPreferences, AIMessageTabViewItem, AIChat;

@protocol AIInterfaceComponent; 

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"

#define DUAL_INTERFACE_DEFAULT_PREFS		@"DualWindowDefaults"

#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
//#define KEY_USE_LAST_WINDOW					@"Use Last Window"
#define KEY_AUTOHIDE_TABBAR					@"Autohide Tab Bar"
#define KEY_TABBAR_OVERFLOW					@"Use Overflow Menu"
#define KEY_KEEP_TABS_ARRANGED				@"Keep Tabs Arranged"
#define KEY_ARRANGE_TABS_BY_GROUP			@"Arrange Tabs By Group"
#define KEY_TABBAR_POSITION					@"Tab Bar Position"
#define KEY_TABBAR_SHOW_UNREAD_COUNT		@"Show Unread Message Count in Tabs"
#define KEY_TABBAR_SHOW_UNREAD_COUNT_GROUP	@"Show Unread Message Count in Group Chat Tabs"
#define KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP	@"Show Unread Mention Count Only in Group Chat Tabs"

#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
#define KEY_USE_LAST_WINDOW					@"Use Last Window"
#define KEY_AUTOHIDE_TABBAR					@"Autohide Tab Bar"
#define KEY_ENABLE_INACTIVE_TAB_CLOSE		@"Enable Inactive Tab Close"
#define KEY_KEEP_TABS_ARRANGED				@"Keep Tabs Arranged"
#define KEY_ARRANGE_TABS_BY_GROUP			@"Arrange Tabs By Group"
#define	KEY_WINDOW_LEVEL					@"Window Level"
#define KEY_WINDOW_HIDE						@"Hide While in Background"
#define KEY_PSYCHIC							@"Open Chats When typing Begins"

@interface AIDualWindowInterfacePlugin : AIPlugin <AIInterfaceComponent> {
    
	NSMutableArray			*delayedContainerShowArray;
	NSMutableDictionary		*containers;
	NSInteger						uniqueContainerNumber;
	
    //Menus
    NSMutableArray			*windowMenuArray;
    NSMenuItem				*menuItem_close;
    NSMenuItem				*menuItem_closeTab;
    NSMenuItem				*menuItem_nextMessage;
    NSMenuItem				*menuItem_previousMessage;

    NSMenuItem				*menuItem_openInNewWindow;
    NSMenuItem				*menuItem_openInPrimaryWindow;
    NSMenuItem				*menuItem_consolidate;
	NSMenuItem				*menuItem_splitByGroup;
	NSMenuItem				*menuItem_toggleTabBar;
	
	NSMenuItem				*menuItem_arrangeTabs;
	NSMenuItem				*menuItem_arrangeTabs_alternate;
    
    //Containers
    AIContactListWindowController 	*contactListWindowController;
    id <AIChatContainer>		activeContainer;

    //messageWindow stuff
    NSMutableArray			*messageWindowControllerArray;
    AIMessageWindowController		*lastUsedMessageWindow;
    NSMutableArray			*lastUsedContainerArray;
	NSMutableDictionary		*arrangeByGroupWindowList;
    
    //Preferences
    AIDualWindowPreferences                 *preferenceController;

	BOOL					applicationIsHidden;

}

- (AIMessageWindowController *)openContainerWithID:(NSString *)containerID name:(NSString *)containerName;
- (void)closeContainer:(AIMessageWindowController *)container;
- (void)containerDidClose:(AIMessageWindowController *)container;
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem toContainer:(id)newMessageWindow atIndex:(NSInteger)index withTabBarAtPoint:(NSPoint)screenPoint;
- (id)openNewContainer;

@end
