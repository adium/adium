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

#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/DCJoinChatViewController.h>
#import <AIUtilities/AIStringAdditions.h>

@interface DCJoinChatViewController ()
- (NSString *)impliedCompletion:(NSString *)aString;
- (void)inviteUsers:(NSTimer *)inTimer;
@end

@implementation DCJoinChatViewController

//Create a new join chat view
+ (DCJoinChatViewController *)joinChatView
{
	return [[self alloc] init];
}

//Init
- (id)init
{
    if ((self = [super init]))
	{
		chat = nil;
		delegate = nil;
		
		NSString	*nibName = [self nibName];
		if (nibName)
		{
			[NSBundle loadNibNamed:nibName owner:self];
		}
	}
	
    return self;
}

@synthesize view;

//Stubs for subclasses
- (NSString *)nibName {
	return nil;
};

- (void)joinChatWithAccount:(AIAccount *)inAccount
{
	
};

- (void)configureForAccount:(AIAccount *)inAccount
{ 
	if (inAccount != account) {
		account = inAccount; 
	}
}

- (NSString *)impliedCompletion:(NSString *)aString
{
	return aString;
}


/*!
 * @brief Join a group chat with given information
 *
 * @param inName The name of the chat
 * @param inAccount The account on which to join
 * @param inInfo Account-specific information which can be used by the account while joining or creating the chat
 * @param contactsToInvite An array of AIListContacts which will be invited to the chat once Chat_DidOpen is posted for it (once it is open)
 * @param invitationMessage A message sent to contactsToInvite. Ignored if contactsToInvite is nil.
 */
- (void)doJoinChatWithName:(NSString *)inName
				 onAccount:(AIAccount *)inAccount
		  chatCreationInfo:(NSDictionary *)inInfo 
		  invitingContacts:(NSArray *)contactsToInvite
	 withInvitationMessage:(NSString *)invitationMessage
{
	
	AILog(@"Creating chatWithName:%@ onAccount:%@ chatCreationInfo:%@",inName,inAccount,inInfo);
	
	
	chat = [adium.chatController chatWithName:inName
									 identifier:nil
									  onAccount:inAccount
							   chatCreationInfo:inInfo];

	if ([contactsToInvite count]) {
		[chat setValue:contactsToInvite forProperty:@"ContactsToInvite" notify:NotifyNever];
		
		if ([invitationMessage length]) {
			[chat setValue:invitationMessage forProperty:@"InitialInivitationMessage" notify:NotifyNever];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidOpen:) name:Chat_DidOpen object:chat];
	}
	
}


//When the chat opens, we are ready to send out our invitations to join it
- (void)chatDidOpen:(NSNotification *)notification
{
	NSArray *contacts = [chat valueForProperty:@"ContactsToInvite"];
	
	if (contacts && [contacts count]) {
		NSMutableDictionary	*inviteUsersDict;
		NSString			*initialInvitationMessage = [chat valueForProperty:@"InitialInivitationMessage"];
		
		inviteUsersDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[contacts mutableCopy],@"ContactsToInvite",nil];
		if (initialInvitationMessage) {
			[inviteUsersDict setObject:initialInvitationMessage
								forKey:@"InitialInivitationMessage"];
		}
		AILog(@"scheduling invitation of %@",inviteUsersDict);
		[NSTimer scheduledTimerWithTimeInterval:0.01
										 target:self
									   selector:@selector(inviteUsers:)
									   userInfo:inviteUsersDict
										repeats:YES];
	}
	
	//The dictionary will retain the ContactsToInvite and InitialInivitationMessage objects;
	//The timer will retain the dictionary until it is invalidated.
	[chat setValue:nil forProperty:@"ContactsToInvite" notify:NotifyNever];
	[chat setValue:nil forProperty:@"InitialInivitationMessage" notify:NotifyNever];
	
	//We are no longer concerned with the opening of this chat.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_DidOpen object:chat];
}

/*!
 * @brief Timer method to invite contacts to a chat
 * 
 * This is called repeatedly by the scheduled timer until all users have been invited to the chat.
 * This is done incrementally to prevent beachballing if the process is slow and a large number of users are invited.
 */
- (void)inviteUsers:(NSTimer *)inTimer
{
	NSMutableDictionary *userInfo = [inTimer userInfo];
	NSMutableArray		*contactArray = [userInfo objectForKey:@"ContactsToInvite"];

	if ([contactArray count]) {
		AIListContact *listContact = [contactArray objectAtIndex:0];
		[contactArray removeObjectAtIndex:0];
		AILog(@"Inviting %@ to %@", listContact, chat);

		[(AIGroupChat *)chat inviteListContact:listContact
					withMessage:[userInfo objectForKey:@"InitialInivitationMessage"]];

	} else {
		[inTimer invalidate];
	}
}

/*!
 * @brief Generate an array of AIListContacts given a string and an account
 * 
 * @param namesSeparatedByCommas A string in the form @"Contact1,Another Contact,A Third Contact"
 * @param inAccount The account on which the contacts should be created
 */
- (NSArray *)contactsFromNamesSeparatedByCommas:(NSString *)namesSeparatedByCommas onAccount:(AIAccount *)inAccount;
{
	NSMutableArray	*contactsArray = nil;
	NSArray			*contactNames;
	AILog(@"contactsFromNamesSeparatedByCommas:%@ onAccount:%@",namesSeparatedByCommas,inAccount);
	if ([namesSeparatedByCommas length]) {

		contactNames = [namesSeparatedByCommas componentsSeparatedByString:@","];
		
		if ([contactNames count]) {
			NSString		*aContactName, *UID;
			AIListContact	*listContact;
			
			contactsArray = [NSMutableArray array];
			
			for (aContactName in contactNames) {
								
				UID = [inAccount.service normalizeUID:[self impliedCompletion:aContactName] removeIgnoredCharacters:YES];
				
				//If the service is not case sensitive, compact the string before proceeding so our UID will be correct
				if (![inAccount.service caseSensitive]) {
					UID = [UID compactedString];
				}
				
				if ((listContact = [adium.contactController contactWithService:inAccount.service 
																	   account:inAccount 
																		   UID:UID])) {
					[contactsArray addObject:listContact];
				}
			}
		}
	}

	AILog(@"contactsArray is %@",contactsArray);
	return contactsArray;
}

#pragma mark Drag delegate convenience

/*!
 * @brief Find an online contact with the specified service from a unique ID
 *
 * @result An online AIListContact on service, or nil.
 */
- (AIListContact *)validContact:(NSString *)uniqueID withService:(AIService *)service
{
	AIListContact *listContact = nil;
	AIListObject *listObject = [adium.contactController existingListObjectWithUniqueID:uniqueID];
	
	if ( listObject ) {
		if ( [listObject isKindOfClass:[AIMetaContact class]] ) {
			listContact = [(AIMetaContact *)listObject preferredContactWithCompatibleService:service];
		} else if ( [listObject isKindOfClass:[AIListContact class]] ) {
			if ([listObject.service isEqualTo:service]) {
				listContact = (AIListContact *)listObject;
			}
		}				
		
		if ( listContact && listContact.online ) {
			return listContact;
		}
	}
	
	return nil;
}

// Tests if dragged objects are valid for this account
// Must be called by explicitly the subclass
- (NSDragOperation)doDraggingEntered:(id <NSDraggingInfo>)sender
{	
	// Test whether this drag item is acceptable
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// Are there list objects being dragged?
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]]) {
		
		// If so, get the ID's
		if ([[pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs;
			NSString		*uniqueID;
			
			dragItemsUniqueIDs = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
			
			for (uniqueID in dragItemsUniqueIDs) {
				
				// Is there a contact with our service?
				if ( [self validContact:uniqueID withService:account.service] ) {
					return NSDragOperationGeneric;
				}
			}
		}
	}
	
	//if we reach this point, no valid contacts were dragged
	return NSDragOperationNone;
}

// Accepts list contacts being dragged over theField and adds their ID's to the field in a nice manner
// Note: subclasses must call this explicitly
- (BOOL)doPerformDragOperation:(id <NSDraggingInfo>)sender toField:(NSTextField *)theField
{	
	NSPasteboard *pboard = [sender draggingPasteboard];
	
	// Were ListObjects dragged?
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]]) {
		
		// If so, get the unique ID's
		if ([[pboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs;
			NSString		*uniqueID;
			AIListContact	*listContact;
			
			dragItemsUniqueIDs = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
			
			for (uniqueID in dragItemsUniqueIDs) {
				NSString *oldValue = [theField stringValue];
				
				// Get contacts with our service
				// (May not be necessary, as we reject ungood contacts in the dragging entered phase)
				if ((listContact = [self validContact:uniqueID withService:account.service])) {
					
					// Add a comma for prettiness if need be
					if ( [oldValue length] && ![[oldValue substringFromIndex:([oldValue length]-1)] isEqualToString:@","] ) {
						oldValue = [oldValue stringByAppendingString:@", "];
						[theField setStringValue:oldValue];
					}
					[theField setStringValue:[oldValue stringByAppendingString:listContact.displayName]];
				}
			}
		}
	}
	return YES;
}

@synthesize delegate;

@synthesize sharedChatInstance;

@end
