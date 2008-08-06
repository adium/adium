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

#import <Adium/AIWindowController.h>

#define AIMessageWindow_ControllersChanged 		@"AIMessageWindow_ControllersChanged"
#define AIMessageWindow_ControllerOrderChanged 		@"AIMessageWindow_ControllerOrderChanged"
#define AIMessageWindow_SelectedControllerChanged 	@"AIMessageWindow_SelectedControllerChanged"

typedef enum
{
	AdiumTabPositionBottom = 0,
	AdiumTabPositionTop,
	AdiumTabPositionLeft,
	AdiumTabPositionRight,
} AdiumTabPosition;

@class AIMessageSendingTextView, AIMessageTabViewItem, AIMessageViewController, AIDualWindowInterfacePlugin, AIMessageTabSplitView;
@class PSMTabBarControl, PSMAdiumTabStyle;
@class AIChat;
@protocol AIFlexibleToolbarItemDelegate;

@interface AIMessageWindowController : AIWindowController {
    IBOutlet	NSTabView			*tabView_messages;
    IBOutlet	PSMTabBarControl	*tabView_tabBar;
	PSMAdiumTabStyle				*tabView_tabStyle;
	AIMessageTabSplitView			*tabView_splitView;
    AIDualWindowInterfacePlugin 	*interface;
	NSString						*containerName;
	NSString						*containerID;

	BOOL			windowIsClosing;
	BOOL			alwaysShowTabs;		//YES if the tabs should always be visible, even if there is only 1

	AdiumTabPosition tabPosition;
	float			 lastTabBarWidth;

	NSDictionary	*toolbarItems;
	NSMutableArray	*containedChats;
	
	BOOL			hasShownDocumentButton;
	
	BOOL			toolbar_selectedTabChanged;
	NSToolbar *toolbar;
}

+ (AIMessageWindowController *)messageWindowControllerForInterface:(AIDualWindowInterfacePlugin *)inInterface
															withID:(NSString *)inContainerID
															  name:(NSString *)inName;
- (IBAction)closeWindow:(id)sender;
- (NSString *)containerID;
- (PSMTabBarControl *)tabBar;
- (AdiumTabPosition)tabPosition;
- (NSString *)name;
- (AIChat *)activeChat;

//Contained Chats
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem;
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem atIndex:(int)index silent:(BOOL)silent;
- (void)removeTabViewItem:(AIMessageTabViewItem *)inTabViewItem silent:(BOOL)silent;
- (void)moveTabViewItem:(AIMessageTabViewItem *)inTabViewItem toIndex:(int)index;
- (BOOL)containerIsEmpty;
- (NSArray *)containedChats;

//Tabs
- (void)updateIconForTabViewItem:(AIMessageTabViewItem *)tabViewItem;

//Toolbar
-(void)removeToolbarItemWithIdentifier:(NSString*)identifier;

@end
