/*
 * Project:     Adium Bonjour Plugin
 * File:        AWBonjourAccount.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004-2005 Andrew Wellington.
 * All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AWBonjourAccount.h"
#import "AWEzv.h"
#import "AWEzvContact.h"
#import "EKEzvFileTransfer.h"
#import "EKEzvOutgoingFileTransfer.h"
#import "AWEzvDefines.h"
#import "AWBonjourPlugin.h"
#import "AWEzvSupportRoutines.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentTyping.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <Adium/AIFileTransferControllerProtocol.h>

@interface AWBonjourAccount ()
- (NSString *)UIDForContact:(AWEzvContact *)contact;

- (void)setAccountIdleTo:(NSDate *)idle;
- (void)setStatus:(AWEzvStatus)status withMessage:(NSAttributedString *)message;
@end

@implementation AWBonjourAccount
- (void)initAccount
{
	[super initAccount];

	libezvContacts = [[NSMutableSet alloc] init];
	libezv = [(AWEzv *)[AWEzv alloc] initWithClient:self];	
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	/* Releasing libezv leads to the libezvContacts set being accessed;
	 * if it has been released but not set to nil, this results in a crash.
	 */
	[libezvContacts release]; libezvContacts = nil;
	[libezv release];

	[super dealloc];
}

- (BOOL)disconnectOnFastUserSwitch
{
	return YES;
}

//Bonjour should just ignore network reachability
- (BOOL)connectivityBasedOnNetworkReachability
{
	return NO;
}

- (void)connect
{
	[super connect];

	NSString *displayName = self.displayName;
	[libezv setName:displayName];
	AILog(@"%@: Logging in using libezvThreadProxy %@",self, libezv);
	[libezv login];
}

- (void)disconnect
{
	//As per AIAccount's documentation, call super's implementation
	[super disconnect];

	// Say we're disconnecting...
	[self setValue:[NSNumber numberWithBool:YES] forProperty:@"isDisconnecting" notify:YES];

	[libezv logout];
}

- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
{

}

#pragma mark Libezv Callbacks

/*!
 * @brief libezv: we logged in
 *
 * Sent on the libezv thread
 */
- (void)reportLoggedIn
{
	AILog(@"%@: reportLoggedIn",self);
	[self didConnect];
	[self setLastDisconnectionError:nil];
	
	//Silence updates
	[self silenceAllContactUpdatesForInterval:18.0];
	[[AIContactObserverManager sharedManager] delayListObjectNotificationsUntilInactivity];
	
	//We need to set our user icon after connecting
	[self updateStatusForKey:KEY_USER_ICON];	
}

/*!
 * @brief libezv: we logged out
 *
 * Sent on the libezv thread
 */
- (void)reportLoggedOut 
{
	AILog(@"%@: reportLoggedOut",self);
	[libezvContacts removeAllObjects];

	[self didDisconnect];
}

/*!
 * @brief libezv: A contact was updated 
 *
 * Sent on the libezv thread
 */
- (void)userChangedState:(AWEzvContact *)contact
{	
	AIListContact *listContact = [adium.contactController contactWithService:service
				   account:self
				   UID:[self UIDForContact:contact]];  
	if ([contact status] == AWEzvUndefined) {
		AILogWithSignature(@"Warning: Received a status update for a contact with an undefined status. This shouldn't happen.");
		for (NSString *groupName in listContact.remoteGroupNames)
			[listContact removeRemoteGroupName:groupName];
		[listContact setOnline:NO notify:NotifyLater silently:silentAndDelayed];
		
	} else {
		if (listContact.countOfRemoteGroupNames == 0) {
			[listContact addRemoteGroupName:@"Bonjour"];
		}
		
		//We only get state change updates on Online contacts
		[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
	}
	
	[listContact setStatusWithName:nil
	                    statusType:(([contact status] == AWEzvAway) ? AIAwayStatusType : AIAvailableStatusType)
	                        notify:NotifyLater];
	
	NSString *contactStatusMessage = contact.statusMessage;
	[listContact setStatusMessage:(contactStatusMessage ? [[[NSAttributedString alloc] initWithString:contactStatusMessage] autorelease] : nil)
	                       notify:NotifyLater];
	
	NSDate *idleSinceDate = [contact idleSinceDate];
	[listContact setIdle:(idleSinceDate != nil)
	           sinceDate:idleSinceDate
	              notify:NotifyLater];
	
	//Use the contact alias as the serverside display name
	NSString *contactName = contact.name;
	
	if (![[listContact valueForProperty:@"serverDisplayName"] isEqualToString:contactName]) {
		[listContact setServersideAlias:contactName
		                       silently:silentAndDelayed];
	}
	
	//Apply any changes
	[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];	

	//Adding an existing object to a set has no effect, so just ensure it is added
	[libezvContacts addObject:contact];
}
		 
- (void)userChangedImage:(AWEzvContact *)contact
{
	AIListContact *listContact = [adium.contactController contactWithService:service
								  account:self
								  UID:[self UIDForContact:contact]];  
	
	[listContact setServersideIconData:[contact contactImageData] notify:NotifyNow];
}

- (void)userLoggedOut:(AWEzvContact *)contact
{	
	AIListContact *listContact = [adium.contactController existingContactWithService:service
				   account:self 
				   UID:contact.uniqueID];
	
	for (NSString *groupName in listContact.remoteGroupNames)
		[listContact removeRemoteGroupName:groupName];
	[listContact setOnline:NO notify:NotifyNow silently:silentAndDelayed];

	[libezvContacts removeObject:contact];
}

//We received a message from an AWEzvContact
- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html
{
	AIListContact       *listContact;
	AIContentMessage    *msgObj;
	AIChat              *chat;
	NSAttributedString  *attributedMessage;
	
	listContact = [adium.contactController existingContactWithService:service
				   account:self
				   UID:contact.uniqueID];
	chat = [adium.chatController chatWithContact:listContact];
	
	if (html)
		attributedMessage = [adium.contentController decodedIncomingMessage:html
							 fromContact:listContact
							 onAccount:self
							 tryDecrypt:YES];
	else
		attributedMessage = [[[NSAttributedString alloc] initWithString:
							  [adium.contentController decryptedIncomingMessage:message
							   fromContact:listContact
							   onAccount:self]] autorelease];
	
	msgObj = [AIContentMessage messageInChat:chat
	                              withSource:listContact
	                             destination:self
	                                    date:nil
	                                 message:attributedMessage
	                               autoreply:NO];
	
	[adium.contentController receiveContentObject:msgObj];
	
	//Clear the typing flag
	[chat setValue:nil
	   forProperty:KEY_TYPING
			notify:YES];	
}

- (void)user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus
{
	AIListContact *listContact = [adium.contactController existingContactWithService:service
				   account:self
				   UID:contact.uniqueID];
	AIChat *chat = [adium.chatController existingChatWithContact:listContact];
	
	[chat setValue:((typingStatus == AWEzvIsTyping) ? [NSNumber numberWithInt:AITyping] : nil)
	   forProperty:KEY_TYPING
			notify:YES];	
}

- (void)user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
/* unimplemented in libezv at this stage */
}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity
{
	if (severity == AWEzvConnectionError) {
		[self setLastDisconnectionError:error];
		[self disconnect];
	}
	NSLog(@"Bonjour Error (%i): %@", severity, error);
	AILog(@"Bonjour Error (%i): %@", severity, error);
}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contactUniqueID
{
	if ([error isEqualToString:@"Could Not Send"]) {
		
		AIListContact *listContact = [adium.contactController existingContactWithService:service
					   account:self
					   UID:contactUniqueID];
		AIChat *chat = [adium.chatController existingChatWithContact:listContact];
		
		[chat setValue:[NSNumber numberWithInt:AIChatMessageSendingUserNotAvailable]
		   forProperty:KEY_CHAT_ERROR
				notify:NotifyNow];
		[chat setValue:nil
		   forProperty:KEY_CHAT_ERROR
				notify:NotifyNever];
	} else {
		NSLog(@"Bonjour Error (%i): %@", severity, error);
		AILog(@"Bonjour Error (%i): %@", severity, error);
	}
}

#pragma mark AIAccount Messaging
// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (void)sendTypingObject:(AIContentTyping *)inContentTyping
{
	AIChat           *chat = inContentTyping.chat;
	AIListObject     *listObject = chat.listObject;
	NSString         *to = listObject.UID;

	[libezv sendTypingNotification:(inContentTyping.typingState == AITyping ? AWEzvIsTyping : AWEzvNotTyping)
	                                              to:to];
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	[libezv sendMessage:inContentMessage.messageString
					 to:inContentMessage.destination.UID
			   withHtml:inContentMessage.encodedMessage];
	
	return YES;
}

/*!
 * @brief Return the string encoded for sending to a remote contact
 *
 * We return nil if the string turns out to have been a / command.
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	AIHTMLDecoder *XHTMLDecoder;
	XHTMLDecoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
	                                             fontTags:YES
	                                        closeFontTags:YES
	                                            colorTags:YES
	                                            styleTags:YES
	                                       encodeNonASCII:YES
	                                         encodeSpaces:NO
	                                    attachmentsAsText:YES
	                            onlyIncludeOutgoingImages:NO
	                                       simpleTagsOnly:NO
	                                       bodyBackground:NO
									  allowJavascriptURLs:YES];

	[XHTMLDecoder setGeneratesStrictXHTML:YES];
	[XHTMLDecoder setClosesFontTags:YES];
	NSString *encodedMessage = [XHTMLDecoder encodeHTML:inContentMessage.message imagesPath:nil];
	[XHTMLDecoder release];
	return encodedMessage;
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	return YES;
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
	return YES;
}

#pragma mark Account Status
//Respond to account status changes
- (void)updateStatusForKey:(NSString *)key
{
	[super updateStatusForKey:key];
	BOOL areOnline = [self boolValueForProperty:@"isOnline"];

	//Now look at keys which only make sense while online
	if (areOnline) {
		if ([key isEqualToString:@"idleSince"]) {
			NSDate	*idleSince = [self preferenceForKey:@"idleSince" group:GROUP_ACCOUNT_STATUS];
			[libezv setStatus:AWEzvIdle
			                        withMessage:[self.statusMessage string]];
			[self setAccountIdleTo:idleSince];
		}
	}
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)inStatusMessage
{
	if (statusState.statusType == AIOfflineStatusType) {
		[self disconnect];
	} else {
		if (self.online) {
			AIStatusType	statusType = statusState.statusType;
			switch(statusType) {
				case AIAvailableStatusType:
					[self setStatus:AWEzvOnline withMessage:inStatusMessage];
					break;
				case AIAwayStatusType:
					[self setStatus:AWEzvAway withMessage:inStatusMessage];
					break;
				case AIInvisibleStatusType:
					[self setStatus:AWEzvAway withMessage:inStatusMessage];
					break;
				default:
					break;
			}
		} else {
			[self connect];
		}
	}
}
- (void)setStatus:(AWEzvStatus)status withMessage:(NSAttributedString *)message
{
	[libezv setStatus:status withMessage:[message string]];

	[self setValue:message forProperty:@"listObjectStatusMessage" notify:YES];
	[self setValue:[NSNumber numberWithBool:(status == AWEzvAway)] forProperty:@"Away" notify:YES];
}
- (void)setAccountIdleTo:(NSDate *)idle
{
	[libezv setIdleTime:idle];

	//We are now idle
	[self setValue:idle forProperty:@"idleSince" notify:YES];
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image.
 */
- (void)setAccountUserImage:(NSImage *)image withData:(NSData *)originalData
{
	const static NSSize MAX_BONJOUR_IMAGE_SIZE = {96, 96};
	const static int MAX_BONJOUR_IMAGE_BYTES = 65535;

	NSImage *bonjourImage = [image imageByScalingToSize:MAX_BONJOUR_IMAGE_SIZE];
	NSData	*bonjourImageData = [bonjourImage JPEGRepresentationWithMaximumByteSize:MAX_BONJOUR_IMAGE_BYTES];

	[libezv setContactImageData:bonjourImageData];	

	[super setAccountUserImage:image withData:originalData];
}

//Properties this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;

	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"isOnline",
			@"Offline",
			@"idleSince",
			@"IdleManuallySet",
			@"Away",
			@"AwayMessage",
			nil];

		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}

	return supportedPropertyKeys;
}

- (NSString *)UIDForContact:(AWEzvContact *)contact
{
	return contact.uniqueID;
}

/*****************************************************/
/* File transfer / AIAccount_Files inherited methods */
/*****************************************************/
#pragma mark File Transfer

//can the account send entire folders on its own?
- (BOOL)canSendFolders
{
	return YES;
}

- (void)updateProgressForFileTransfer:(EKEzvFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	[[ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]] setPercentDone:[percent floatValue] bytesSent:[bytesSent unsignedLongLongValue]];
}

- (void)remoteCanceledFileTransfer:(EKEzvFileTransfer *)fileTransfer
{
	ESFileTransfer *transfer = [ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]];
	[libezv transferCancelled:fileTransfer];
	if (!transfer.isStopped) {
		[transfer setStatus:Cancelled_Remote_FileTransfer];
	}
}

//Instructs the account to cancel a file ransfer in progress
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	AWEzvLog(@"Cancel file transfer %@",fileTransfer);

	EKEzvFileTransfer *transfer = [fileTransfer accountData];
	[libezv transferCancelled:transfer];

	if (!fileTransfer.isStopped) {
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}
}

//Instructs the account to cancel a file ransfer in progress
- (void)transferFailed:(EKEzvFileTransfer *)fileTransfer
{
	ESFileTransfer *transfer = [ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]];
	[transfer cancel];
	if (!transfer.isStopped) {
		[fileTransfer setStatus:Failed_FileTransfer];
	}
}
#pragma mark Incoming File Transfer 

- (void)user:(AWEzvContact *)contact sentFile:(EKEzvFileTransfer *)file
{
	AIListContact *listContact = [adium.contactController existingContactWithService:service account:self UID:contact.uniqueID];
	/* Set up the file transfer */
	ESFileTransfer *fileTransfer = [adium.fileTransferController newFileTransferWithContact:listContact forAccount:self type:Incoming_FileTransfer];
	[fileTransfer setRemoteFilename: [file remoteFilename]];
	[fileTransfer setAccountData: file];
	[fileTransfer setSizeWithNumber:[NSNumber numberWithUnsignedLongLong:[file size]]];
	if ([file type] == EKEzvDirectory_Transfer){
		[fileTransfer setIsDirectory: YES];
	}
	[self requestReceiveOfFileTransfer: fileTransfer];
}

- (void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"File transfer request received: %@",fileTransfer);
	[adium.fileTransferController receiveRequestForFileTransfer:fileTransfer];
}


//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
	AWEzvLog(@"Accepted file transfer %@",fileTransfer);
	EKEzvFileTransfer *transfer = [fileTransfer accountData];
	[transfer setUniqueID: [fileTransfer uniqueID]];
	[fileTransfer setStatus:Accepted_FileTransfer];

	[libezv transferAccepted:transfer withFileName:[fileTransfer localFilename]];    
}

//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	AWEzvLog(@"Reject file transfer %@",fileTransfer);
}

#pragma mark Outgoing File Transfer

//Instructs the account to initiate sending of a file
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[fileTransfer setFileTransferType: Outgoing_FileTransfer];
	/*Let's create the EKEzvFileTransfer */
	EKEzvOutgoingFileTransfer *ezvFileTransfer = [[EKEzvOutgoingFileTransfer alloc] init];
	[ezvFileTransfer setLocalFilename:[fileTransfer localFilename]];
	[ezvFileTransfer setSize:[[fileTransfer sizeNumber] unsignedLongLongValue]];
	[ezvFileTransfer setContactUID:[[fileTransfer contact] UID]];
	[ezvFileTransfer setUniqueID:[fileTransfer uniqueID]];
	[ezvFileTransfer setDirection:EKEzvOutgoingTransfer];
	
	/* Now store the EKEzvOutgoingFileTransfer in the ESFileTransfer */
	[fileTransfer setAccountData:ezvFileTransfer];
	
	[libezv startOutgoingFileTransfer:ezvFileTransfer];
	[fileTransfer setStatus:Waiting_on_Remote_User_FileTransfer];
	[ezvFileTransfer release];
}

#pragma  mark Outgoing file transfer status updates

- (void)remoteUserBeganDownload:(EKEzvOutgoingFileTransfer *)transfer
{
	[[ESFileTransfer existingFileTransferWithID:[transfer uniqueID]] setStatus:Accepted_FileTransfer];
}

- (void)remoteUserFinishedDownload:(EKEzvOutgoingFileTransfer *)transfer
{
	[[ESFileTransfer existingFileTransferWithID:[transfer uniqueID]] setStatus:Complete_FileTransfer];
}

#pragma mark Contact list management
- (void)moveListObjects:(NSArray *)objects fromGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups
{	
	//Move the objects to it
	for (AIListContact *contact in objects) {
		if (![contact.remoteGroups intersectsSet:oldGroups] && oldGroups.count) {
			continue;
		}
		
		/* 
		for (AIListGroup *group in oldGroups) {
			[contact removeRemoteGroupName:group.UID];
		}
		
		for (AIListGroup *group in groups) {
			[contact addRemoteGroupName:group.UID];
		}
		 */
	}		
}

@end
