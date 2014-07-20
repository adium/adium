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

#import "AITabStatusIconsPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatusIcons.h>

@interface AITabStatusIconsPlugin ()
- (void)statusIconSetDidChange:(NSNotification *)aNotification;
@end


/*!
 * @class AITabStatusIconsPlugin
 * @brief Tab status icons component
 *
 * This component is effectively glue to AIStatusIcons to provide status and typing/unviewed content icons
 * for chats.
 */
@implementation AITabStatusIconsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Observe list object changes
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	
	//Observe chat changes
	[adium.chatController registerChatObserver:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(statusIconSetDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief The status icon set changed; update our objects and chats.
 */
- (void)statusIconSetDidChange:(NSNotification *)aNotification
{
	[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
	[adium.chatController updateAllChatsForObserver:self];
}

/*!
 * @brief Apply the correct tab icon according to status
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;
	
	if (inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"isOnline"] ||
	   [inModifiedKeys containsObject:@"listObjectStatusName"] ||
	   [inModifiedKeys containsObject:@"listObjectStatusType"] ||
	   [inModifiedKeys containsObject:@"isIdle"] ||
	   [inModifiedKeys containsObject:@"notAStranger"] ||
	   [inModifiedKeys containsObject:KEY_IS_BLOCKED] ||
	   [inModifiedKeys containsObject:@"isMobile"]) {
		
		/* Tab: Note in the modifiedAttributes that it would have changed. Other code
		 * can use AIStatusIcons to get the actual icon.
		 */

		//List
		NSImage *icon = [AIStatusIcons statusIconForListObject:inObject
														  type:AIStatusIconList
													 direction:AIIconNormal];
		[inObject setValue:icon
			   forProperty:@"listStatusIcon"
					notify:NotifyNever];

		modifiedAttributes = [NSSet setWithObjects:@"tabStatusIcon", @"listStatusIcon", nil];
	}
	
	return modifiedAttributes;
}

/*!
 * @brief Update a chat for typing and unviewed content icons
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;
	
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_TYPING] ||
		[inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		AIListContact	*listContact;
		NSImage			*tabStateIcon;
		
		//Apply the state icon to our chat
		tabStateIcon = [AIStatusIcons statusIconForChat:inChat
												   type:AIStatusIconTab
											  direction:AIIconNormal];
		[inChat setValue:tabStateIcon
			 forProperty:@"tabStateIcon"
				  notify:NotifyNever];
		modifiedAttributes = [NSSet setWithObject:@"tabStateIcon"];

		
		if (inChat.isGroupChat) {
			// If this is a group chat, and we have an AIListBookmark for it, apply the icon to it.
			listContact = (AIListContact *)[adium.contactController existingBookmarkForChat:inChat];
		} else {
			// If this is a one-on-one chat, apply the icon to its target.
			listContact = [[inChat listObject] parentContact];
		}
		
		//Also apply the state icon to our contact if this is a one-on-one chat
		if (listContact) {
			NSImage	*listStateIcon;
			
			listStateIcon = [AIStatusIcons statusIconForChat:inChat
														type:AIStatusIconList
												   direction:AIIconNormal];
			[listContact setValue:listStateIcon
					  forProperty:@"listStateIcon"
						   notify:NotifyNever];
			[[AIContactObserverManager sharedManager] listObjectAttributesChanged:listContact
													  modifiedKeys:[NSSet setWithObject:@"listStateIcon"]];
		}		
	}
	
	return modifiedAttributes;
}

@end
