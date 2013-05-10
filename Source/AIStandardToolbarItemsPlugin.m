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

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIStandardToolbarItemsPlugin.h"
#import <Adium/AIToolbarControllerProtocol.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

#define MESSAGE	AILocalizedString(@"Message", nil)

@interface AIStandardToolbarItemsPlugin ()
- (IBAction)showSourceDestinationPicker:(NSToolbarItem *)toolbarItem;
@end

/*!
 * @class AIStandardToolbarItemsPlugin
 * @brief Component to provide general-use toolbar items
 *
 * Just provides a Source/Destination picker toolbar item at present.
 */
@implementation AIStandardToolbarItemsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //New Message
    NSToolbarItem   *toolbarItem = 
	[AIToolbarUtilities toolbarItemWithIdentifier:@"SourceDestination"
											label:AILocalizedString(@"Source/Destination", nil)
									 paletteLabel:AILocalizedString(@"Change Source or Destination", nil)
										  toolTip:AILocalizedString(@"If multiple accounts can send to this contact or this is a combined contact, change the source and/or destination of this chat", nil)
										   target:self
								  settingSelector:@selector(setImage:)
									  itemContent:[NSImage imageNamed:@"msg-source-destination" forClass:[self class] loadLazily:YES]
										   action:@selector(showSourceDestinationPicker:)
											 menu:nil];
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"MessageWindow"];
}

/*!
 * @brief New chat with the selected list object
 */
- (IBAction)showSourceDestinationPicker:(NSToolbarItem *)toolbarItem
{
    AIListObject	*object = adium.interfaceController.selectedListObject;

    if ([object isKindOfClass:[AIListContact class]]) {
		AIChat  *chat = [adium.chatController openChatWithContact:(AIListContact *)object
												 onPreferredAccount:YES];
        [adium.interfaceController setActiveChat:chat];
    }
	
}

@end
