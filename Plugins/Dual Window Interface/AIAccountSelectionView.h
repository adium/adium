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

#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>

@class AIChat;

#define AIViewFrameDidChangeNotification	@"AIViewFrameDidChangeNotification"

/*!	@brief	View for selecting the account and contact of a chat.
 *
 *	@par	This view contains two pop-up menus: One for accounts, and the other for contacts. It appears at the top of the chat window when the user double-clicks on a contact row in the contact list, and when the chat receives content from a different contact in the same metacontact as the existing current contact.
 */

@interface AIAccountSelectionView : NSView <AIAccountMenuDelegate, AIContactMenuDelegate> {
	NSPopUpButton		*popUp_accounts;
	NSView				*box_accounts;

	NSPopUpButton   	*popUp_contacts;
	NSView				*box_contacts;
	
	AIAccountMenu		*accountMenu;	
	AIContactMenu		*contactMenu;	
	AIChat				*chat;
	
	NSColor *leftColor;
	NSColor *rightColor;
}

- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithFrame:(NSRect)frameRect;
- (void)setChat:(AIChat *)inChat;

- (void)setLeftColor:(NSColor *)inLeftColor rightColor:(NSColor *)inRightColor;

@end
