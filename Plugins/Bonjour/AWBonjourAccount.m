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
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIFileTransferControllerProtocol.h>

static	NSConditionLock     *threadPreparednessLock = nil;
static	NDRunLoopMessenger  *bonjourThreadMessenger = nil;
static	AWEzv               *_libezvThreadProxy = nil;

typedef enum {
	AIThreadPreparing = 0,
	AIThreadReady
};

#define	AUTORELEASE_POOL_REFRESH	5.0

@interface AWBonjourAccount (PRIVATE)
- (NSString *)UIDForContact:(AWEzvContact *)contact;

- (void)setAccountIdleTo:(NSDate *)idle;
- (void)setAccountUserImage:(NSImage *)image;
- (void)setStatus:(AWEzvStatus)status withMessage:(NSAttributedString *)message;
@end

@implementation AWBonjourAccount
- (void)initAccount
{
	[super initAccount];

	libezvContacts = [[NSMutableSet alloc] init];
	libezv = [[AWEzv alloc] initWithClient:self];	
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

- (AWEzv *)libezvThreadProxy
{
	if (!_libezvThreadProxy) {
		//Obtain the lock
		threadPreparednessLock = [[NSConditionLock alloc] initWithCondition:AIThreadPreparing];

		//Detach the thread, which will unlock threadPreparednessLock when it is ready
		[NSThread detachNewThreadSelector:@selector(prepareBonjourThread)
		                         toTarget:self
		                       withObject:nil];

		//Obtain the lock - this will spinlock until the thread is ready
		[threadPreparednessLock lockWhenCondition:AIThreadReady];
		[threadPreparednessLock unlock];
		[threadPreparednessLock release]; threadPreparednessLock = nil;
	}

	return _libezvThreadProxy;
}
- (void)connect
{
	[super connect];

	[[self libezvThreadProxy] setName:[self displayName]];
	AILog(@"%@: Logging in using libezvThreadProxy %@",self, [self libezvThreadProxy]);
	[[self libezvThreadProxy] login];
}

- (void)disconnect
{
	//As per AIAccount's documentation, call super's implementation
	[super disconnect];

	// Say we're disconnecting...
	[self setValue:[NSNumber numberWithBool:YES] forProperty:@"Disconnecting" notify:YES];

	[[self libezvThreadProxy] logout];
}

- (void)removeContacts:(NSArray *)objects
{

}

#pragma mark Libezv Callbacks
/*!
 * @brief Logged in, called on the main thread
 */
- (void)mainThreadReportLoggedIn
{
	[self didConnect];
	[self setLastDisconnectionError:nil];

	//Silence updates
	[self silenceAllContactUpdatesForInterval:18.0];
	[[adium contactController] delayListObjectNotificationsUntilInactivity];

	//We need to set our user icon after connecting
	[self updateStatusForKey:KEY_USER_ICON];	
}

/*!
 * @brief libezv: we logged in
 *
 * Sent on the libezv thread
 */
- (void)reportLoggedIn
{
	AILog(@"%@: reportLoggedIn",self);
	[self mainPerformSelector:@selector(mainThreadReportLoggedIn)];
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

	[self mainPerformSelector:@selector(didDisconnect)];
}

- (void)mainThreadUserChangedState:(AWEzvContact *)contact
{
	AIListContact   *listContact;
	NSString        *contactName, *statusMessage;
	NSDate          *idleSinceDate;
	NSImage         *contactImage;
	
	listContact = [[adium contactController] contactWithService:service
	                                                    account:self
	                                                        UID:[self UIDForContact:contact]];  
	if ([contact status] == AWEzvUndefined) {
		AILogWithSignature(@"Warning: Received a status update for a contact with an undefined status. This shouldn't happen.");
		[listContact setRemoteGroupName:nil];
		[listContact setOnline:NO notify:NotifyLater silently:silentAndDelayed];

	} else {
		if (![listContact remoteGroupName]) {
			[listContact setRemoteGroupName:@"Bonjour"];
		}

		//We only get state change updates on Online contacts
		[listContact setOnline:YES notify:NotifyLater silently:silentAndDelayed];
	}

	[listContact setStatusWithName:nil
	                    statusType:(([contact status] == AWEzvAway) ? AIAwayStatusType : AIAvailableStatusType)
	                        notify:NotifyLater];

	statusMessage = [contact statusMessage];
	[listContact setStatusMessage:(statusMessage ? [[[NSAttributedString alloc] initWithString:statusMessage] autorelease] : nil)
	                       notify:NotifyLater];
	
	idleSinceDate = [contact idleSinceDate];
	[listContact setIdle:(idleSinceDate != nil)
	           sinceDate:idleSinceDate
	              notify:NotifyLater];

	//Use the contact alias as the serverside display name
	contactName = [contact name];

	if (![[listContact valueForProperty:@"Server Display Name"] isEqualToString:contactName]) {
		[listContact setServersideAlias:contactName
		                       silently:silentAndDelayed];
	}

	//Apply any changes
	[listContact notifyOfChangedPropertiesSilently:silentAndDelayed];	
}

/*!
 * @brief libezv: A contact was updated 
 *
 * Sent on the libezv thread
 */
- (void)userChangedState:(AWEzvContact *)contact
{
	[self mainPerformSelector:@selector(mainThreadUserChangedState:)
	               withObject:contact];

	//Adding an existing object to a set has no effect, so just ensure it is added
	[libezvContacts addObject:contact];
}

- (void)mainThreadUserChangedImage:(AWEzvContact *)contact
{
	AIListContact *listContact = [[adium contactController] contactWithService:service
																	   account:self
																		   UID:[self UIDForContact:contact]];  

	[listContact setServersideIconData:[contact contactImageData] notify:NotifyNow];
}
		 
- (void)userChangedImage:(AWEzvContact *)contact
{
	[self mainPerformSelector:@selector(mainThreadUserChangedImage:)
				   withObject:contact];
}

- (void)mainThreadUserWithUIDLoggedOut:(NSString *)inUID
{
	AIListContact *listContact;

	listContact = [[adium contactController] existingContactWithService:service
	                                                            account:self 
	                                                                UID:inUID];

	[listContact setRemoteGroupName:nil];
	[listContact setOnline:NO notify:NotifyNow silently:silentAndDelayed];
}

- (void)userLoggedOut:(AWEzvContact *)contact
{
	[self mainPerformSelector:@selector(mainThreadUserWithUIDLoggedOut:)
	               withObject:[contact uniqueID]];

	[libezvContacts removeObject:contact];
}

- (void)mainThreadUserWithUID:(NSString *)inUID sentMessage:(NSString *)message withHtml:(NSString *)html
{
	AIListContact       *listContact;
	AIContentMessage    *msgObj;
	AIChat              *chat;
	NSAttributedString  *attributedMessage;

	listContact = [[adium contactController] existingContactWithService:service
	                                                            account:self
	                                                               UID:inUID];
	chat = [[adium chatController] chatWithContact:listContact];
	
	if (html)
		attributedMessage = [[adium contentController] decodedIncomingMessage:html
		                                                          fromContact:listContact
		                                                            onAccount:self];
	else
		attributedMessage = [[[NSAttributedString alloc] initWithString:
		    [[adium contentController] decryptedIncomingMessage:message
		                                            fromContact:listContact
		                                              onAccount:self]] autorelease];

	msgObj = [AIContentMessage messageInChat:chat
	                              withSource:listContact
	                             destination:self
	                                    date:nil
	                                 message:attributedMessage
	                               autoreply:NO];

	[[adium contentController] receiveContentObject:msgObj];

	//Clear the typing flag
	[chat setValue:nil
	               forProperty:KEY_TYPING
	               notify:YES];	
}

//We received a message from an AWEzvContact
- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html
{
	[self mainPerformSelector:@selector(mainThreadUserWithUID:sentMessage:withHtml:)
	               withObject:[contact uniqueID]
	               withObject:message
	               withObject:html];
}

- (void)mainThreadUserWithUID:(NSString *)inUID typingNotificationNumber:(NSNumber *)typingNumber
{
	AIListContact   *listContact;
	AIChat          *chat;
	listContact = [[adium contactController] existingContactWithService:service
	                                                            account:self
	                                                                UID:inUID];
	chat = [[adium chatController] existingChatWithContact:listContact];

	[chat setValue:typingNumber
	               forProperty:KEY_TYPING
	               notify:YES];	
}

- (void)user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus
{
	[self mainPerformSelector:@selector(mainThreadUserWithUID:typingNotificationNumber:)
	               withObject:[contact uniqueID]
	               withObject:((typingStatus == AWEzvIsTyping) ? [NSNumber numberWithInt:AITyping] : nil)];
}

/*!
 * @brief A message could not be sent
 *
 * @param inContactUniqueID Unique ID of the contact to whom the message could not be sent
 */
- (void)mainThreadCouldNotSendToUserWithUID:(NSString *)inContactUniqueID
{
	AIListContact   *listContact;
	AIChat          *chat;

	listContact = [[adium contactController] existingContactWithService:service
	                                                            account:self
	                                                                UID:inContactUniqueID];
	chat = [[adium chatController] existingChatWithContact:listContact];

	[chat setValue:[NSNumber numberWithInt:AIChatMessageSendingUserNotAvailable]
	               forProperty:KEY_CHAT_ERROR
	               notify:NotifyNow];
	[chat setValue:nil
	               forProperty:KEY_CHAT_ERROR
	               notify:NotifyNever];
}

- (void)user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
/* unimplemented in libezv at this stage */
}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity
{
	if (severity == AWEzvConnectionError) {
		[self mainPerformSelector:@selector(setLastDisconnectionError:)
					   withObject:error];
	}
	NSLog(@"Bonjour Error (%i): %@", severity, error);
	AILog(@"Bonjour Error (%i): %@", severity, error);
}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contactUniqueID
{
	if ([error isEqualToString:@"Could Not Send"]) {
		[self mainPerformSelector:@selector(mainThreadCouldNotSendToUserWithUID:)
		               withObject:contactUniqueID];

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
	AIChat           *chat = [inContentTyping chat];
	AIListObject     *listObject = [chat listObject];
	NSString         *to = [listObject UID];

	[[self libezvThreadProxy] sendTypingNotification:(([inContentTyping typingState] == AITyping) ? AWEzvIsTyping : AWEzvNotTyping)
	                                              to:to];
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	[[self libezvThreadProxy] sendMessage:[inContentMessage messageString] 
	                                   to:[[inContentMessage destination] UID]
	                             withHtml:[inContentMessage encodedMessage]];

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
	NSString *encodedMessage = [XHTMLDecoder encodeHTML:[inContentMessage message] imagesPath:nil];
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
	BOOL areOnline = [[self valueForProperty:@"Online"] boolValue];

	//Now look at keys which only make sense while online
	if (areOnline) {
		if ([key isEqualToString:@"IdleSince"]) {
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[[self libezvThreadProxy] setStatus:AWEzvIdle
			                        withMessage:[[self statusMessage] string]];
			[self setAccountIdleTo:idleSince];
		} else if ([key isEqualToString:KEY_USER_ICON]) {
			NSData  *data = [self userIconData];
			[self setAccountUserImage:data];
		}
	}
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if ([statusState statusType] == AIOfflineStatusType) {
		[self disconnect];
	} else {
		if ([self online]) {
			AIStatusType	statusType = [statusState statusType];
			switch(statusType) {
				case AIAvailableStatusType:
					[self setStatus:AWEzvOnline withMessage:statusMessage];
					break;
				case AIAwayStatusType:
					[self setStatus:AWEzvAway withMessage:statusMessage];
					break;
				case AIInvisibleStatusType:
					[self setStatus:AWEzvAway withMessage:statusMessage];
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
	[[self libezvThreadProxy] setStatus:status withMessage:[message string]];

	[self setValue:message forProperty:@"StatusMessage" notify:YES];
	[self setValue:[NSNumber numberWithBool:(status == AWEzvAway)] forProperty:@"Away" notify:YES];
}
- (void)setAccountIdleTo:(NSDate *)idle
{
	[[self libezvThreadProxy] setIdleTime:idle];

	//We are now idle
	[self setValue:idle forProperty:@"IdleSince" notify:YES];
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image.
 */
- (void)setAccountUserImage:(NSData *)image
{	
	NSImage *newImage = (image ? [[[NSImage alloc] initWithData:image] autorelease] : nil);
	[[self libezvThreadProxy] setContactImageData:[newImage JPEGRepresentation]];	

	//We now have an icon
	[self setValue:newImage forProperty:KEY_USER_ICON notify:YES];
}

//Properties this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;

	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"Online",
			@"Offline",
			@"IdleSince",
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
	return [contact uniqueID];
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

- (void)mainThreadUpdateProgressForFileTransfer:(ESFileTransfer *)transfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	[transfer setPercentDone:percent bytes:bytesSent];
}

- (void)updateProgressForFileTransfer:(EKEzvFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent
{
	/* Lookup ESFileTransfer */
	ESFileTransfer *transfer = [ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]];
	[self mainPerformSelector:@selector(mainThreadUpdateProgressForFileTransfer:percent:bytesSent:)
	               withObject:transfer
	               withObject:percent
	               withObject:bytesSent];
}

- (void)mainThreadCancelFileTransferRemotely:(ESFileTransfer *)transfer
{
	if (![transfer isStopped]) {
		[transfer setStatus:Cancelled_Remote_FileTransfer];
	}
}

- (void)remoteCanceledFileTransfer:(EKEzvFileTransfer *)fileTransfer
{
	ESFileTransfer *transfer = [ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]];
	[[self libezvThreadProxy] transferCancelled:transfer];
	[self mainPerformSelector:@selector(mainThreadCancelFileTransferRemotely:)
	               withObject:transfer];
}

- (void)mainThreadLocalCanceledFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}
}
//Instructs the account to cancel a file ransfer in progress
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	AWEzvLog(@"Cancel file transfer %@",fileTransfer);

	EKEzvFileTransfer *transfer = [fileTransfer accountData];
	[[self libezvThreadProxy] transferCancelled:transfer];

	[self mainPerformSelector:@selector(mainThreadLocalCanceledFileTransfer:)
	               withObject:fileTransfer];
}

- (void)mainThreadTransferFailed:(ESFileTransfer *)fileTransfer
{
	if (![fileTransfer isStopped]) {
		[fileTransfer setStatus:Failed_FileTransfer];
	}
}
//Instructs the account to cancel a file ransfer in progress
- (void)transferFailed:(EKEzvFileTransfer *)fileTransfer
{
	ESFileTransfer *transfer = [ESFileTransfer existingFileTransferWithID: [fileTransfer uniqueID]];
	[transfer cancel];
	[self mainPerformSelector:@selector(mainThreadTransferFailed:)
	               withObject:transfer];
	
}
#pragma mark Incoming File Transfer 

- (void)mainThreadUserWithUID:(NSString *)inUID sentFile:(EKEzvFileTransfer *)file
{
	AIListContact   *listContact;

	listContact = [[adium contactController] existingContactWithService:service account:self UID:inUID];
	/* Set up the file transfer */
	ESFileTransfer *fileTransfer = [[adium fileTransferController] newFileTransferWithContact:listContact forAccount:self type:Incoming_FileTransfer];
	[fileTransfer setRemoteFilename: [file remoteFilename]];
	[fileTransfer setAccountData: file];
	[fileTransfer setSizeWithNumber:[NSNumber numberWithUnsignedLongLong:[file size]]];
	if ([file type] == EKEzvDirectory_Transfer){
		[fileTransfer setIsDirectory: YES];
	}
	[self requestReceiveOfFileTransfer: fileTransfer];
}

- (void)user:(AWEzvContact *)contact sentFile:(EKEzvFileTransfer *)fileTransfer
{
	[self mainPerformSelector:@selector(mainThreadUserWithUID:sentFile:)
	               withObject:[contact uniqueID]
	               withObject:fileTransfer];
}

- (void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	AILog(@"File transfer request received: %@",fileTransfer);
	[[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}


//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
	AWEzvLog(@"Accepted file transfer %@",fileTransfer);
	EKEzvFileTransfer *transfer = [fileTransfer accountData];
	[transfer setUniqueID: [fileTransfer uniqueID]];
	[fileTransfer setStatus:Accepted_FileTransfer];

	[[self libezvThreadProxy] transferAccepted:transfer withFileName:[fileTransfer localFilename]];    
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
	
	[[self libezvThreadProxy] startOutgoingFileTransfer:ezvFileTransfer];
	[fileTransfer setStatus:Waiting_on_Remote_User_FileTransfer];
	[ezvFileTransfer release];
}

#pragma  mark Outgoing file transfer status updates
- (void)mainThreadRemoteUserBeganDownload:(EKEzvOutgoingFileTransfer *)transfer
{
	[[ESFileTransfer existingFileTransferWithID:[transfer uniqueID]] setStatus:Accepted_FileTransfer];
}
- (void)remoteUserBeganDownload:(EKEzvOutgoingFileTransfer *)fileTransfer
{
	[self mainPerformSelector:@selector(mainThreadRemoteUserBeganDownload:) withObject:fileTransfer];
}

- (void)mainThreadRemoteUserFinishedDownload:(EKEzvOutgoingFileTransfer *)transfer
{
	[[ESFileTransfer existingFileTransferWithID:[transfer uniqueID]] setStatus:Complete_FileTransfer];
}
- (void)remoteUserFinishedDownload:(EKEzvOutgoingFileTransfer *)fileTransfer
{
	[self mainPerformSelector:@selector(mainThreadRemoteUserFinishedDownload:) withObject:fileTransfer];
}

#pragma mark Bonjour Thread

- (void)clearBonjourThreadInfo
{
	[_libezvThreadProxy release]; _libezvThreadProxy = nil;
	[bonjourThreadMessenger release]; bonjourThreadMessenger = nil;
}

- (void)prepareBonjourThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[threadPreparednessLock lock];

	bonjourThreadMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];
	_libezvThreadProxy = [[bonjourThreadMessenger target:libezv] retain];

	[[NSNotificationCenter defaultCenter] addObserver:self 
	                                         selector:@selector(threadWillExit:) 
	                                             name:NSThreadWillExitNotification
	                                           object:[NSThread currentThread]];

	//We're good to go; release that lock
	[threadPreparednessLock unlockWithCondition:AIThreadReady];
	
	while(true) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:AUTORELEASE_POOL_REFRESH]];
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
	}

	[self clearBonjourThreadInfo];
	[pool release];
}

/*!
 * @brief The bonjour thread is about to exit for some reason...
 *
 * I have no idea why the thread might exit, but it does.  Messaging the libezvThreadProxy after it exits throws an
 * NDRunLoopMessengerConnectionNoLongerExistsException exception.  If we clear out our data, perhaps we can recover fairly gracefully.
 *
 * It will be recreated when next needed.
 */
- (void)threadWillExit:(NSNotification *)inNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                            selector:@selector(threadWillExit:) 
	                                              object:[inNotification object]];

	[self clearBonjourThreadInfo];
}

@end