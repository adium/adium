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

#import "ESChatUserListController.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIListContactGroupChatCell.h>
#import <Adium/AIProxyListObject.h>
#import "AIMessageTabViewItem.h"
#import "AIListBookmark.h"

@implementation ESChatUserListController

/*!
 * @brief Notify our delegate when the selection changes.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([[self superclass] instancesRespondToSelector:@selector(outlineViewSelectionDidChange:)]) {
		[super outlineViewSelectionDidChange:notification];
	}
	
	if ([self.delegate respondsToSelector:@selector(outlineViewSelectionDidChange:)]) {
		[self.delegate performSelector:@selector(outlineViewSelectionDidChange:)
							  withObject:notification];
	}
}

//Chat user lists never autoresize
- (BOOL) autoresizeHorizontally
{
	return NO;
}

- (BOOL) autoresizeVertically
{
	return NO;
}

/*!
 * @brief We don't want to change text colors based on the user's status or state
 *
 * This is called by our superclass during configuration.
 */
- (BOOL)shouldUseContactTextColors
{
	return NO;
}

/*!
 * @brief Use the status message for a contact, not its calculated extended status, in the group chat user list
 *
 * This is called by our superclass during configuration.
 */
- (BOOL)useStatusMessageAsExtendedStatus
{
	return YES;
}

#pragma mark Drag & drop

/*!
 * @brief Accept a drop
 *
 * When a drop of a contact is performed onto the user list, invite the contact to the chat
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)idx
{
	//Invite the dragged contact(s) to the chat
	BOOL			success = NO;
	AIChat			*activeChat = [adium.interfaceController activeChatInWindow:[info draggingDestinationWindow]];
	AIAccount		*activeChatAccount = activeChat.account;
	
	for (AIProxyListObject *proxyObject in dragItems) {
		AIListObject *listObject = proxyObject.listObject;
		
		//Dont allow Bookmarks to be invited to chat
		if ([listObject isKindOfClass:[AIListBookmark class]]) {
			success = NO;
			break;
		}
		
		if ([listObject isKindOfClass:[AIMetaContact class]]) {
			listObject = [(AIMetaContact *)listObject preferredContactWithCompatibleService:activeChatAccount.service];
		}

		if ([listObject isKindOfClass:[AIListContact class]] &&
			[listObject.service.serviceClass isEqualToString:activeChatAccount.service.serviceClass]) {
			[activeChatAccount inviteContact:(AIListObject *)listObject toChat:activeChat withMessage:nil];
			success = YES;
		}
	}

	success = [super outlineView:outlineView acceptDrop:info item:item childIndex:idx] && success;
	
	return success;
}

/*!
 * @brief Validate a drop
 *
 * We can use setDropItem:dropChildIndex: to reposition the drop.
 *
 * @param outlineView The outline view which will receive the drop
 * @param info The NSDraggingInfo
 * @param item The item into which the drag would currently drop
 * @param index The index within item into which the drag would currently drop. It may be a 0-based index inside item or may be NSOutlineViewDropOnItemIndex.
 * @result The drag operation we will allow
 */
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)idx
{
	AIChat			*activeChat = [adium.interfaceController activeChatInWindow:[info draggingDestinationWindow]];
	AIAccount		*activeChatAccount = activeChat.account;

	for (AIProxyListObject *proxyObject in dragItems) {
		AIListObject *listObject = proxyObject.listObject;
		
		//Dont allow bookmarks to be dropped
		if ([listObject isKindOfClass:[AIListBookmark class]]) {
			return NSDragOperationNone;
		}
		
		if ([listObject isKindOfClass:[AIMetaContact class]]) {
			listObject = [(AIMetaContact *)listObject preferredContactWithCompatibleService:activeChatAccount.service];
		}

		if ([listObject isKindOfClass:[AIListContact class]] &&
			[listObject.service.serviceClass isEqualToString:activeChatAccount.service.serviceClass] &&
			![activeChat containsObject:listObject]) {
			return NSDragOperationCopy;
		}
	}
	
	return NSDragOperationNone;
}

#pragma mark Contextual menu

/*!
 * @brief Return the contextual menu for a passed list object
 *
 * Assumption: Our delegate is an AIMessageTabViewItem (which responds to chat)
 */
- (NSMenu *)contextualMenuForListObject:(AIListObject *)listObject
{
	NSArray *locationsArray = nil;
	
	if (listObject.isStranger) {
		locationsArray = [NSArray arrayWithObjects:
						  [NSNumber numberWithInteger:Context_Contact_GroupChat_ParticipantAction],		
						  [NSNumber numberWithInteger:Context_Contact_Manage],
						  [NSNumber numberWithInteger:Context_Contact_Action],
						  [NSNumber numberWithInteger:Context_Contact_ListAction],
						  [NSNumber numberWithInteger:Context_Contact_Stranger_ChatAction],
						  [NSNumber numberWithInteger:Context_Contact_NegativeAction],
						  [NSNumber numberWithInteger:Context_Contact_Additions], nil];
	} else {
		locationsArray = [NSArray arrayWithObjects:
						  [NSNumber numberWithInteger:Context_Contact_GroupChat_ParticipantAction],		
						  [NSNumber numberWithInteger:Context_Contact_Manage],
						  [NSNumber numberWithInteger:Context_Contact_Action],
						  [NSNumber numberWithInteger:Context_Contact_ListAction],
						  [NSNumber numberWithInteger:Context_Contact_NegativeAction],
						  [NSNumber numberWithInteger:Context_Contact_Additions], nil];
	}
	
    return [adium.menuController contextualMenuWithLocations:locationsArray
												 forListObject:listObject
														inChat:[self.delegate chat]];
}

#pragma mark Cell setup
- (AIContactListWindowStyle)windowStyle
{
	return AIContactListWindowStyleGroupChat;
}

- (void)updateCellRelatedThemePreferencesFromDict:(NSDictionary *)prefDict
{
	[super updateCellRelatedThemePreferencesFromDict:prefDict];

	AIChat *chat = (AIChat *)contactList;
	
	[contentCell setExtendedStatusVisible:!chat.hideUserIconAndStatus];
	[contentCell setUserIconVisible:!chat.hideUserIconAndStatus];
	[(AIListContactGroupChatCell *)contentCell setChat:chat];
}

@end
