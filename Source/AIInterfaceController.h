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

@class AIMenuController, AIChat, AIListObject, AIMessageViewController;

@interface AIInterfaceController : NSObject <AIInterfaceController> {
@private
    IBOutlet	NSMenuItem		*menuItem_close;
    IBOutlet	NSMenuItem		*menuItem_closeChat;
	IBOutlet	NSMenuItem		*menuItem_closeAllChats;

    IBOutlet	NSMenuItem		*menuItem_paste;
	IBOutlet	NSMenuItem		*menuItem_pasteWithImagesAndColors;
    IBOutlet	NSMenuItem		*menuItem_pasteAndMatchStyle;
    
    IBOutlet    NSMenuItem      *menuItem_showFonts;
    IBOutlet    NSMenuItem      *menuItem_bold;
    IBOutlet    NSMenuItem      *menuItem_italic;

	IBOutlet    NSMenuItem      *menuItem_showToolbar;
	IBOutlet    NSMenuItem      *menuItem_customizeToolbar;

	IBOutlet	NSMenuItem		*menuItem_print;
	
	IBOutlet NSMenuItem			*menuItem_reopenTab;

    NSMutableArray				*contactListViewArray;
    NSMutableArray				*messageViewArray;		
    NSMutableArray				*interfaceArray;	
    NSMutableArray				*contactListTooltipEntryArray;
    NSMutableArray              *contactListTooltipSecondaryEntryArray;
    CGFloat                       maxLabelWidth;

	
    NSMutableArray				*flashObserverArray;
    NSTimer						*flashTimer;
    int							flashState;
    AIListObject				*tooltipListObject;
    NSMutableAttributedString   *tooltipBody;
    NSMutableAttributedString   *tooltipTitle;
    NSImage                     *tooltipImage;
	
	BOOL						closeMenuConfiguredForChat;
	
	NSArray						*_cachedOpenChats;
	
	NSMutableArray				*windowMenuArray;
	
	AIChat						*activeChat;
	AIChat						*mostRecentActiveChat;
	
	BOOL						tabbedChatting;
	
	id <AIInterfaceComponent>			interfacePlugin;
	id <AIMultiContactListComponent>	contactListPlugin;
		
	BOOL						groupChatsByContactGroup;
	BOOL						saveContainers;
	
	NSMenuItem					*menuItem_toggleUserlist;
	NSMenuItem					*menuItem_toggleUserlistSide;
	NSMenuItem					*menuItem_clearDisplay;

	IBOutlet NSView				*fontPanelAccessoryView;
	IBOutlet NSButton			*button_fontPanelSetAsDefault;
	
	NSMutableArray				*recentlyClosedChats;
}

- (IBAction)showContactListAndBringToFront:(id)sender;

- (IBAction)closeMenu:(id)sender;
- (IBAction)closeChatMenu:(id)sender;
- (IBAction)closeAllChats:(id)sender;

- (IBAction)paste:(id)sender;
- (IBAction)pasteAndMatchStyle:(id)sender;
- (IBAction)pasteWithImagesAndColors:(id)sender;

- (IBAction)adiumPrint:(id)sender;

- (IBAction)toggleFontPanel:(id)sender;
- (IBAction)setFontPanelSettingsAsDefaultFont:(id)sender;

- (IBAction)toggleFontTrait:(id)sender;
- (IBAction)toggleToolbarShown:(id)sender;
- (IBAction)runToolbarCustomizationPalette:(id)sender;

- (IBAction)showPreferenceWindow:(id)sender;

- (IBAction)reopenChat:(id)sender;

@end
