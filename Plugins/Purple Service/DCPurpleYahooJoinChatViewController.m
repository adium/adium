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
#import "DCPurpleYahooJoinChatViewController.h"
#import "DCJoinChatWindowController.h"
#import <AIUtilities/AICompletingTextField.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>

@interface DCPurpleYahooJoinChatViewController ()
- (void)validateEnteredText;
- (void)_configureTextField;
@end

@implementation DCPurpleYahooJoinChatViewController

- (id)init
{
	if ((self = [super init]))
	{
		[textField_inviteUsers setDragDelegate:self];
		[textField_inviteUsers registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs", nil]];
	}
	
	return self;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];

	[textField_inviteUsers setMinStringLength:2];
	[textField_inviteUsers setCompletesOnlyAfterSeparator:YES];
	[self _configureTextField];
	
	[self validateEnteredText];
	[[view window] makeFirstResponder:textField_roomName];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	
	/* Yahoo group chats always have a colon and then a number. If none is specified, add :1.  The server would do this for us
	 * automagically... but then we have a spare AIChat lying around, and that's no good.
	 */	
	if ([room rangeOfString:@":"].location == NSNotFound) {
		room = [room stringByAppendingString:@":1"];
	}

	NSDictionary *chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",nil];
	
	[self doJoinChatWithName:room
				   onAccount:inAccount
			chatCreationInfo:chatCreationInfo
			invitingContacts:[self contactsFromNamesSeparatedByCommas:[textField_inviteUsers stringValue] onAccount:inAccount]
	   withInvitationMessage:[textField_inviteMessage stringValue]];
	
}

- (NSString *)nibName
{
	return @"DCPurpleYahooJoinChatView";
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == textField_roomName) {
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	if (delegate)
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:[textField_roomName stringValue].length > 0];
}

- (NSString *)impliedCompletion:(NSString *)aString
{
	return [textField_inviteUsers impliedStringValueForString:aString];
}

- (void)_configureTextField
{
	//Clear the completing strings
	[textField_inviteUsers setCompletingStrings:nil];
	
	//Configure the auto-complete view to autocomplete for contacts matching the selected account's service
	for (AIListContact *contact in adium.contactController.allContacts) {
		if (contact.service == account.service) {
			NSString *UID = contact.UID;
			[textField_inviteUsers addCompletionString:contact.formattedUID withImpliedCompletion:UID];
			[textField_inviteUsers addCompletionString:contact.displayName withImpliedCompletion:UID];
			[textField_inviteUsers addCompletionString:UID];
		}
	}
}

#pragma mark Dragging Delegate

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [super doPerformDragOperation:sender toField:textField_inviteUsers];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [super doDraggingEntered:sender];
}

@end
