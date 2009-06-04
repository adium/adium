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
#import <Adium/AIContactMenu.h>

@class AIService, AIChat, AIListContact;

@interface DCInviteToChatWindowController : AIWindowController <AIContactMenuDelegate> {	
	IBOutlet	NSPopUpButton   *menu_contacts;
	IBOutlet	NSTextField		*textField_message;
	IBOutlet	NSTextField		*textField_chatName;

	IBOutlet	NSTextField		*label_inviteContact;
	IBOutlet	NSTextField		*label_chatName;
	IBOutlet	NSTextField		*label_message;
	IBOutlet	NSButton		*button_invite;
	IBOutlet	NSButton		*button_cancel;
	
	AIListContact				*contact;
	AIService					*service;
	AIChat						*chat;
	AIContactMenu				*contactMenu;
}

+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListContact *)inContact;
+ (void)closeSharedInstance;

- (IBAction)invite:(id)sender;
- (IBAction)cancel:(id)sender;

-(void)inviteToChat:(AIListContact*)contact;
- (id)initWithWindowNibName:(NSString *)windowNibName;
@end
