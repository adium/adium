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

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import "DCInviteToChatWindowController.h"
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>

#define INVITE_NIB_NAME		@"InviteToChatWindow"

@interface DCInviteToChatWindowController ()
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact;
- (void)setContact:(AIListContact *)inContact;
- (void)localize;
@end 
@implementation DCInviteToChatWindowController

static DCInviteToChatWindowController *sharedInviteToChatInstance = nil;

//Create a new invite to chat window
+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListContact *)inContact
{
    if (!sharedInviteToChatInstance) {
        sharedInviteToChatInstance = [[self alloc] initWithWindowNibName:INVITE_NIB_NAME];
    }

	[sharedInviteToChatInstance setChat:inChat contact:inContact];
    [[sharedInviteToChatInstance window] makeKeyAndOrderFront:nil];
}

+ (void)closeSharedInstance
{
    if (sharedInviteToChatInstance) {
        [sharedInviteToChatInstance closeWindow:nil];
    }
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{	
	if ((self = [super initWithWindowNibName:windowNibName])) {
		contact = nil;
		service = nil;
		chat = nil;
	}
	
    return self;
}


//Dealloc
- (void)dealloc
{    
	contact = nil;
	service = nil;
	chat = nil;

}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //Center the window
    [[self window] center];
	
	[self localize];
}

- (IBAction)invite:(id)sender
{	
	// Sanity check: is there really a list object and a chat?
	if (contact && [contact isKindOfClass:[AIListContact class]] && chat) {
		
		// Sanity check: is it a group chat?
		if (chat.isGroupChat) {
			NSString *message = [textField_message stringValue];
			if (!message || ![message length]) {
				message = [adium.chatController defaultInvitationMessageForRoom:chat.name account:chat.account];
			}
			[chat inviteListContact:(AIListContact *)contact withMessage:message];
		}
	}	
	
	[self closeWindow:nil];}

- (void)configureForChatAndContact
{
	//Ensure the window is loaded
	[self window];
		
	//Configure the contact menu (primarily for handling metacontacts)
    contactMenu = [AIContactMenu contactMenuWithDelegate:self forContactsInObject:contact];

	if ([contact isKindOfClass:[AIMetaContact class]]) {
		[menu_contacts selectItemWithRepresentedObject:[(AIMetaContact *)contact preferredContactWithCompatibleService:service]];
	} else {
		[menu_contacts selectItemAtIndex:0];
	}

	//Update to know that we are working with this contact
	[self setContact:[[menu_contacts selectedItem] representedObject]];
	
	// Set the chat's name in the window
	[textField_chatName setStringValue:chat.name];	
}

//Setting methods
#pragma mark Setting methods
- (void)setChat:(AIChat *)inChat contact:(AIListContact *)inContact
{
	[self setContact:inContact];
	
	if (chat != inChat) {
		chat = inChat;
		service = chat.account.service;
	}
	
	[self configureForChatAndContact];
}

- (void)setContact:(AIListContact *)inContact
{	
	if (contact != inContact) {
		contact = inContact;
	}
}

//Window behavior and closing
#pragma mark Window behavior and closing
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	sharedInviteToChatInstance = nil;
}

//Close this window
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

/*!
 * @brief Contact menu delegate
 */
- (void)contactMenuDidRebuild:(AIContactMenu *)inContactMenu {
	[menu_contacts setMenu:[inContactMenu menu]];
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact {
	[self setContact:inContact];
}

- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact {
	return ([inContact.service.serviceClass isEqualToString:service.serviceClass] &&
			(!contact.online || inContact.online));
}

-(void)inviteToChat:(AIListContact*)inContact
{
	// Sanity check: is there really a list object and a chat?
	if (inContact && [inContact isKindOfClass:[AIListContact class]] && chat) {
		
		// Sanity check: is it a group chat?
		if (chat.isGroupChat) {
			NSString *message = [textField_message stringValue];
			if (!message || ![message length]) {
				message = [adium.chatController defaultInvitationMessageForRoom:chat.name account:chat.account];
			}
			[chat inviteListContact:inContact withMessage:message];
		}
	}	
	
	[self closeWindow:nil];
}

- (void)localize
{
	[[self window] setTitle:AILocalizedString(@"Invite to Chat", "Invite to Chat window title")];
	[label_inviteContact setLocalizedString:AILocalizedString(@"Invite Contact:", nil)];
	[label_chatName setLocalizedString:AILocalizedString(@"To Chat:", nil)];
	[label_message setLocalizedString:AILocalizedString(@"With Message:", nil)];

	[button_invite setLocalizedString:AILocalizedStringFromTable(@"Invite", @"Buttons", nil)];
	[button_cancel setLocalizedString:AILocalizedStringFromTable(@"Cancel", @"Buttons", nil)];
}

@end
