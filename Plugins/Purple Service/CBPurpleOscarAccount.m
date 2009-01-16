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

#import "CBPurpleOscarAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIStatus.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIStringAdditions.h>


#define DELAYED_UPDATE_INTERVAL			2.0

static BOOL				createdEncoders = NO;
static AIHTMLDecoder	*encoderCloseFontTagsAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderCloseFontTags = nil;
static AIHTMLDecoder	*encoderAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderGroupChat = nil;

@interface CBPurpleOscarAccount ()
- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString forContactWithUID:(const char *)who;
@end

@implementation CBPurpleOscarAccount

- (const char*)protocolPlugin
{
	NSLog(@"WARNING: Subclass must override");
    return "";
}

- (void)initAccount
{
	if (!createdEncoders) {
		encoderCloseFontTagsAttachmentsAsText = [[AIHTMLDecoder alloc] init];
		[encoderCloseFontTagsAttachmentsAsText setIncludesHeaders:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesFontTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setClosesFontTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesStyleTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesColorTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setEncodesNonASCII:NO];
		[encoderCloseFontTagsAttachmentsAsText setPreservesAllSpaces:NO];
		[encoderCloseFontTagsAttachmentsAsText setUsesAttachmentTextEquivalents:YES];
		[encoderCloseFontTagsAttachmentsAsText setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderCloseFontTagsAttachmentsAsText setOnlyUsesSimpleTags:NO];
		[encoderCloseFontTagsAttachmentsAsText setAllowAIMsubprofileLinks:YES];
		[encoderCloseFontTagsAttachmentsAsText setAllowJavascriptURLs:YES];
		
		encoderCloseFontTags = [[AIHTMLDecoder alloc] init];
		[encoderCloseFontTags setIncludesHeaders:YES];
		[encoderCloseFontTags setIncludesFontTags:YES];
		[encoderCloseFontTags setClosesFontTags:YES];
		[encoderCloseFontTags setIncludesStyleTags:YES];
		[encoderCloseFontTags setIncludesColorTags:YES];
		[encoderCloseFontTags setEncodesNonASCII:NO];
		[encoderCloseFontTags setPreservesAllSpaces:NO];
		[encoderCloseFontTags setUsesAttachmentTextEquivalents:NO];
		[encoderCloseFontTags setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderCloseFontTags setOnlyUsesSimpleTags:NO];
		[encoderCloseFontTags setAllowAIMsubprofileLinks:YES];
		[encoderCloseFontTags setAllowJavascriptURLs:YES];
		
		encoderAttachmentsAsText = [[AIHTMLDecoder alloc] init];
		[encoderAttachmentsAsText setIncludesHeaders:YES];
		[encoderAttachmentsAsText setIncludesFontTags:YES];
		[encoderAttachmentsAsText setClosesFontTags:NO];
		[encoderAttachmentsAsText setIncludesStyleTags:YES];
		[encoderAttachmentsAsText setIncludesColorTags:YES];
		[encoderAttachmentsAsText setEncodesNonASCII:NO];
		[encoderAttachmentsAsText setPreservesAllSpaces:NO];
		[encoderAttachmentsAsText setUsesAttachmentTextEquivalents:YES];
		[encoderAttachmentsAsText setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderAttachmentsAsText setOnlyUsesSimpleTags:NO];
		[encoderAttachmentsAsText setAllowAIMsubprofileLinks:YES];
		[encoderAttachmentsAsText setAllowJavascriptURLs:YES];
		
		encoderGroupChat = [[AIHTMLDecoder alloc] init];
		[encoderGroupChat setIncludesHeaders:NO];
		[encoderGroupChat setIncludesFontTags:YES];
		[encoderGroupChat setClosesFontTags:NO];
		[encoderGroupChat setIncludesStyleTags:YES];
		[encoderGroupChat setIncludesColorTags:YES];
		[encoderGroupChat setEncodesNonASCII:NO];
		[encoderGroupChat setPreservesAllSpaces:NO];
		[encoderGroupChat setUsesAttachmentTextEquivalents:YES];
		[encoderGroupChat setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderGroupChat setOnlyUsesSimpleTags:YES];
		[encoderGroupChat setAllowAIMsubprofileLinks:YES];
		[encoderGroupChat setAllowJavascriptURLs:YES];
		
		createdEncoders = YES;
	}	

	[super initAccount];
}

#pragma mark AIListContact and AIService special cases for OSCAR
//Override contactWithUID to mark mobile and ICQ users as such via the displayServiceID
- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	if (!namesAreCaseSensitive) {
		sourceUID = [sourceUID compactedString];
	}
	
	contact = [adium.contactController existingContactWithService:service
															account:self
																UID:sourceUID];
	if (!contact) {		
		contact = [adium.contactController contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return contact;
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;
	
	const char	firstCharacter = ([contactUID length] ? [contactUID characterAtIndex:0] : '\0');

	//Determine service based on UID
	if ([contactUID hasSuffix:@"@mac.com"]) {
		contactServiceID = @"libpurple-oscar-Mac";
	} else if ([contactUID hasSuffix:@"@me.com"]) {
		contactServiceID = @"libpurple-oscar-MobileMe";
	} else if (firstCharacter && (firstCharacter >= '0' && firstCharacter <= '9')) {
		contactServiceID = @"libpurple-oscar-ICQ";
	} else {
		contactServiceID = @"libpurple-oscar-AIM";
	}

	contactService = [adium.accountController serviceWithUniqueID:contactServiceID];

	return contactService;
}
	
#pragma mark Account Connection

- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType shouldAttemptReconnect = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];

	if ([self lastDisconnectionReason] == PURPLE_CONNECTION_ERROR_INVALID_USERNAME) {
			shouldAttemptReconnect = AIReconnectNever;
			*disconnectionError = AILocalizedString(@"The screen name you entered is not registered. Check to ensure you typed it correctly. If it is a new name, you must register it at www.aim.com before you can use it.", "Invalid name on AIM");
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Screen name sent",nil);
			break;
		case 2:
			return AILocalizedString(@"Password sent",nil);
			break;			
		case 3:
			return AILocalizedString(@"Received authorization",nil);
			break;
		case 4:
			return AILocalizedString(@"Connection established",nil);
			break;
		case 5:
			return AILocalizedString(@"Finalizing connection",nil);
			break;
	}

	return nil;
}

#pragma mark Account status
- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	char	*statusID = NULL;

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
			statusID = OSCAR_STATUS_ID_AVAILABLE;
			break;
		case AIAwayStatusType:
			statusID = OSCAR_STATUS_ID_AWAY;
			break;

		case AIInvisibleStatusType:
			statusID = OSCAR_STATUS_ID_INVISIBLE;
			break;
			
		case AIOfflineStatusType:
			statusID = OSCAR_STATUS_ID_OFFLINE;
			break;
	}
	
	return statusID;
}

- (BOOL)shouldSetITMSLinkForNowPlayingStatus
{
	return YES;
}

#pragma mark Contact notes
-(NSString *)serversideCommentForContact:(AIListContact *)theContact
{	
	NSString *serversideComment = nil;
	
	if (purple_account_is_connected(account)) {
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		PurpleBuddy   *buddy;
		
		if ((buddy = purple_find_buddy(account, uidUTF8String))) {
			PurpleGroup   *g;
			char		*comment;
			OscarData   *od;

			if ((g = purple_buddy_get_group(buddy)) &&
				(od = purple_account_get_connection(account)->proto_data) &&
				(comment = aim_ssi_getcomment(od->ssi.local, purple_group_get_name(g), purple_buddy_get_name(buddy)))) {
				gchar		*comment_utf8;
				
				comment_utf8 = purple_utf8_try_convert(comment);
				serversideComment = [NSString stringWithUTF8String:comment_utf8];
				g_free(comment_utf8);
				
				free(comment);
			}
		}
	}
	
	return serversideComment;
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	if ([group isEqualToString:PREF_GROUP_NOTES]) {
		//If the notification object is a listContact belonging to this account, update the serverside information
		if (account &&
			[object isKindOfClass:[AIListContact class]] && 
			[(AIListContact *)object account] == self) {
			
			if ([key isEqualToString:@"Notes"]) {
				NSString  *comment = [object preferenceForKey:@"Notes" 
														group:PREF_GROUP_NOTES
										ignoreInheritedValues:YES];
				
				[[super purpleAdapter] OSCAREditComment:comment forUID:[object UID] onAccount:self];
			}			
		}
	}
}


#pragma mark Delayed updates

- (void)_performDelayedUpdates:(NSTimer *)timer
{
	if ([arrayOfContactsForDelayedUpdates count]) {
		AIListContact *theContact = [arrayOfContactsForDelayedUpdates objectAtIndex:0];
		
		[theContact setValue:[self serversideCommentForContact:theContact]
							 forProperty:@"Notes"
							 notify:YES];

		//Request ICQ contacts' info to get the nickname
		const char *contactUIDUTF8String = [[theContact UID] UTF8String];
		if (aim_snvalid_icq(contactUIDUTF8String)) {
			OscarData			*od;

			if ((purple_account_is_connected(account)) &&
				(od = purple_account_get_connection(account)->proto_data)) {
				aim_icq_getalias(od, contactUIDUTF8String);
			}
		}

		[arrayOfContactsForDelayedUpdates removeObjectAtIndex:0];
		
	} else {
		[arrayOfContactsForDelayedUpdates release]; arrayOfContactsForDelayedUpdates = nil;
		[delayedSignonUpdateTimer invalidate]; [delayedSignonUpdateTimer release]; delayedSignonUpdateTimer = nil;
	}
}

- (void)gotGroupForContact:(AIListContact *)theContact
{
	if (theContact) {
		if (!arrayOfContactsForDelayedUpdates) arrayOfContactsForDelayedUpdates = [[NSMutableArray alloc] init];
		[arrayOfContactsForDelayedUpdates addObject:theContact];
		
		if (!delayedSignonUpdateTimer) {
			delayedSignonUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:DELAYED_UPDATE_INTERVAL 
																		 target:self
																	   selector:@selector(_performDelayedUpdates:) 
																	   userInfo:nil 
																		repeats:YES] retain];
		}
	}
}

- (void)removeContacts:(NSArray *)objects
{
	//Stop any pending delayed updates for these objects
	[arrayOfContactsForDelayedUpdates removeObjectsInArray:objects];

	[super removeContacts:objects];
}

#pragma mark File transfer

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

- (BOOL)canSendFolders
{
	return [super canSendFolders];
}

#pragma mark Messaging
/*!
 * @brief Can we send images for this chat?
 */
- (BOOL)canSendImagesForChat:(AIChat *)inChat
{	
	if ([inChat isGroupChat]) return NO;
	
	OscarData *od = ((account && purple_account_get_connection(account)) ? purple_account_get_connection(account)->proto_data : NULL);
	if (od) {
		AIListObject *listObject = [inChat listObject];
		const char *contactUID = [[listObject UID] UTF8String];
		aim_userinfo_t *userinfo = aim_locate_finduserinfo(od, contactUID);
		
		if (userinfo &&
			aim_sncmp(purple_account_get_username(account), contactUID) &&
			[listObject online]) {
			return ((userinfo->capabilities & OSCAR_CAPABILITY_DIRECTIM) != 0);
			
		} else {
			return NO;
		}
		
	} else {
		return NO;
	}
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{	
	return ([inAttributedString length] ? [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString imagesPath:nil] : nil);
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{		
	AIListObject		*inListObject = [inContentMessage destination];
	NSAttributedString	*inAttributedString = [inContentMessage message];
	NSString			*encodedString;
	
	if (inListObject) {
		if ([[inContentMessage chat] isSecure] &&
			aim_snvalid_icq([[[inContentMessage source] UID] UTF8String]) &&
			aim_snvalid_icq([[inListObject UID] UTF8String])) {
			/* If we're an ICQ account and they're an ICQ account, we need to strip HTML now since the 
			 * encrypted message won't be able to be processed by libpurple */
			encodedString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];

		} else if ([self canSendImagesForChat:[inContentMessage chat]]) {
			//Encode to HTML and look for outgoing images if the chat supports it
			encodedString = [encoderCloseFontTags encodeHTML:inAttributedString
												  imagesPath:@"/tmp"];
			
			if ([encodedString rangeOfString:@"<IMG " options:NSCaseInsensitiveSearch].location != NSNotFound) {
				/* There's an image... we need to see about a Direct Connect, aborting the send attempt if none is established 
				 * and sending after it is if one is established.
				 *
				 * Note that an encrypted session won't ever be able to succeed with a DirectIM at present, because
				 * libpurple only sees the encrypted message :(
				 */
				
				//Check for a PeerConnection for a direct IM currently open
				PeerConnection	*conn;
				OscarData		*od = (OscarData *)purple_account_get_connection(account)->proto_data;
				const char		*who = [[inListObject UID] UTF8String];
				
				conn = peer_connection_find_by_type(od, who, OSCAR_CAPABILITY_DIRECTIM);
				
				encodedString = [self stringByProcessingImgTagsForDirectIM:encodedString forContactWithUID:who];
				
				if ((conn != NULL) && (conn->ready)) {
					//We have a connected dim already; simply continue, and we'll be told to send it in a moment
					
				} else {
					//Either no dim, or the dim we have is no longer conected (oscar_direct_im_initiate_immediately will reconnect it)						
					peer_connection_propose(od, OSCAR_CAPABILITY_DIRECTIM, who);
					
					//Add this content message to the sending queue for this contact to be sent once a connection is established
					if (!directIMQueue) directIMQueue = [[NSMutableDictionary alloc] init];
					
					NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[inListObject internalObjectID]];
					if (!thisContactQueue) {
						thisContactQueue = [NSMutableArray array];
						
						[directIMQueue setObject:thisContactQueue
										  forKey:[inListObject internalObjectID]];
					}
					
					[thisContactQueue addObject:inContentMessage];
				}
			}
		} else {
			encodedString = [self encodedAttributedString:inAttributedString forListObject:inListObject];
		}
		
	} else { //Send HTML when signed in as an AIM account and we don't know what sort of user we are sending to (most likely multiuser chat)
		AILog(@"Encoding %@ for no contact",inAttributedString);
		encodedString = [encoderGroupChat encodeHTML:inAttributedString
										  imagesPath:nil];
	}
	
	return encodedString;
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	if (directIMQueue) {
		NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[[inContentMessage destination] internalObjectID]];
		if ([thisContactQueue containsObject:inContentMessage]) {
			//This message is in our queue of messages to send...
			PeerConnection	*conn;
			OscarData		*od = (OscarData *)purple_account_get_connection(account)->proto_data;
			const char		*who = [[[inContentMessage destination] UID] UTF8String];
			
			conn = peer_connection_find_by_type(od, who, OSCAR_CAPABILITY_DIRECTIM);
			
			if ((conn != NULL) && (conn->ready)) {
				//We have a connected dim ready; send it!  We already displayed it, though, so don't do that.
				[inContentMessage setDisplayContent:NO];
				return [super sendMessageObject:inContentMessage];
			} else {
				//Don't send now, as we'll do the actual send when the dim is connected, in directIMConnected: above, and return here.
				return YES;				
			}
		}
	}
	
	BOOL success = [super sendMessageObject:inContentMessage];
	
	if (purpleImagesToUnref) {
		NSNumber	 *imgstoreNumber;
		for (imgstoreNumber in purpleImagesToUnref) {
			purple_imgstore_unref_by_id([imgstoreNumber intValue]);			
		}
		
		[purpleImagesToUnref release]; purpleImagesToUnref = nil;
	}

	return success;
}

- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return ![[message.message string] hasPrefix:@"[Offline IM sent"];
}


#pragma mark DirectIM (IM Image)
//We are now connected via DirectIM to theContact
- (void)directIMConnected:(AIListContact *)theContact
{
	AILog(@"Direct IM Connected: %@",[theContact UID]);
	
	[adium.contentController displayEvent:AILocalizedString(@"Direct IM connected","Direct IM is an AIM-specific phrase for transferring images in the message window")
									 ofType:@"directIMConnected"
									 inChat:[adium.chatController chatWithContact:theContact]];

	//Send any pending directIM messages for this contact
	NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[theContact internalObjectID]];
	if (thisContactQueue) {
		AIContentObject	*contentObject;
		
		for (contentObject in thisContactQueue) {
			[adium.contentController sendContentObject:contentObject];
		}
		
		[directIMQueue removeObjectForKey:[theContact internalObjectID]];
		
		if (![directIMQueue count]) {
			[directIMQueue release]; directIMQueue = nil;
		}
	}
}

- (void)directIMDisconnected:(AIListContact *)theContact
{
	AILog(@"Direct IM Disconnected: %@",[theContact UID]);	
	
	[adium.contentController displayEvent:AILocalizedString(@"Direct IM disconnected","Direct IM is an AIM-specific phrase for transferring images in the message window")
									 ofType:@"directIMDisconnected"
									 inChat:[adium.chatController chatWithContact:theContact]];	
}

- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString forContactWithUID:(const char *)who
{
	NSScanner			*scanner;
	
	static NSCharacterSet *elementEndCharacters = nil;
	if (!elementEndCharacters)
		elementEndCharacters = [[NSCharacterSet characterSetWithCharactersInString:@" >"] retain];
	static NSString		*tagStart = @"<", *tagEnd = @">";
	NSString			*chunkString;
	NSMutableString		*processedString;
	
    scanner = [NSScanner scannerWithString:inString];
	[scanner setCaseSensitive:NO];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	processedString = [[NSMutableString alloc] init];
	
    //Parse the HTML
    while (![scanner isAtEnd]) {
        //Find an HTML IMG tag
        if ([scanner scanUpToString:@"<img" intoString:&chunkString]) {
			//Append the text leading up the the IMG tag; a directIM may have image tags inline with message text
            [processedString appendString:chunkString];
        }
		
        //Look for the start of a tag
        if ([scanner scanString:tagStart intoString:nil]) {
			//Get the tag itself
			if ([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]) {
				if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
					if ([scanner scanUpToString:tagEnd intoString:&chunkString]) {
						
						//Load the src image
						NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];
						NSString		*source = [imgArguments objectForKey:@"src"];
						NSString		*alt = [imgArguments objectForKey:@"alt"];
						NSString		*filename;
						NSData			*imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:source]];
						NSString		*extension;
						BOOL			requiresConversionToJPEG = NO;
						
						//Store the src image's data purpleside
						filename = (alt ? alt : [source lastPathComponent]);
						
						extension = [filename pathExtension];
						if (![extension length])
							extension = [NSImage extensionForBitmapImageFileType:[NSImage fileTypeOfData:imageData]];
						
						if (([extension caseInsensitiveCompare:@"jpg"] != NSOrderedSame) &&
							([extension caseInsensitiveCompare:@"jpeg"] != NSOrderedSame) &&
							([extension caseInsensitiveCompare:@"gif"] != NSOrderedSame)) {							
							//Old versions of AIM for Windows only supports JPEG and GIF images, so we need to pick a format it does support.
							OscarData			*od;
							aim_userinfo_t		*userinfo;
							
							if (purple_account_is_connected(account) &&
								(od = purple_account_get_connection(account)->proto_data) &&
								(userinfo = aim_locate_finduserinfo(od, who))) {
								/* There's no explicit AIM for Windows capability, but only AIM for Windows advertises AOL's AIM games.
								 * Not all AIM for Windows clients advertise those, though. OSCAR_CAPABILITY_ADDINS is only advertised
								 * by official AIM clients, so it's a good sensitive-but-not-specific test.
								 */
								if ((userinfo->capabilities & OSCAR_CAPABILITY_GAMES) ||
									(userinfo->capabilities & OSCAR_CAPABILITY_GAMES2) ||
									(userinfo->capabilities & OSCAR_CAPABILITY_ADDINS)) 
									requiresConversionToJPEG = YES;
							}
						}
						
						if (requiresConversionToJPEG) {
							NSImage				*image = [[NSImage alloc] initWithData:imageData];
							
							imageData = [[[image JPEGRepresentationWithCompressionFactor:1.0] retain] autorelease];
							extension = @"jpg";
							[image release];

						} else if (![extension length]) {
							//We don't know what we're working with. Try to produce a PNG so we know the format.
							NSImage				*image = [[NSImage alloc] initWithData:imageData];
							
							imageData = [[[image PNGRepresentation] retain] autorelease];
							extension = @"png";
							[image release];							
						}

						//Delete any existing wrong extension
						if ([[filename pathExtension] caseInsensitiveCompare:extension] != NSOrderedSame) 
							filename = [filename stringByDeletingPathExtension];
	
						//Add the right extension if needed
						if (![[filename pathExtension] length])
							filename = [filename stringByAppendingPathExtension:extension];

						unsigned imgBytesLength = [imageData length];
						gpointer imgBytes = malloc(imgBytesLength);
						[imageData getBytes:imgBytes];
						/* purple_imgstore_add_with_id() will take ownership of imgBytes and free it when done*/
						int	imgstore = purple_imgstore_add_with_id(imgBytes, imgBytesLength, [filename UTF8String]);
						
						AILog(@"Adding image id %i with name %s", imgstore, (filename ? [filename UTF8String] : "(null)"));
						
						NSString		*newTag = [NSString stringWithFormat:@"<IMG ID=\"%i\" CLASS=\"scaledToFitImage\">",imgstore];
						[processedString appendString:newTag];
						
						if (!purpleImagesToUnref) purpleImagesToUnref = [[NSMutableSet alloc] init];
						[purpleImagesToUnref addObject:[NSNumber numberWithInt:imgstore]];
					}
				}
				
				if (![scanner isAtEnd]) {
					[scanner setScanLocation:[scanner scanLocation]+1];
				}
			}
		}
	}
	
	return ([processedString autorelease]);
}


#pragma mark Contacts
/*!
 * @brief Should set aliases serverside?
 *
 * AIM and ICQ support serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}

/*!
* @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact 
				  toStatusType:(NSNumber *)statusTypeNumber
					statusName:(NSString *)statusName
				 statusMessage:(NSAttributedString *)statusMessage
					  isMobile:(BOOL)isMobile
{
	/* XXX - Giant hack!
	 * Libpurple, as of 2.0.0 but not before so far as we've seen, sometimes feeds us truncated AIM away messages.
	 * The full message will then follow... followed by the truncated one... and so on. This makes the message
	 * change in the buddy list and in the message window repeatedly.
	 * I'm not sure how long the truncted versions are - I've seen 40 to 70 characters.  We'll therefore ignore
	 * an incoming message which is the same as the first 40 characters of the existing one.  I wonder how long
	 * before someone will notice this "odd" behavior and file a bug report... -evands
	 */
	 
	if (([theContact statusType] == [statusTypeNumber intValue]) &&
		((statusName && ![theContact statusName]) || [[theContact statusName] isEqualToString:statusName])) {
		//Type and name match...
		NSString *currentStatusMessage = [theContact statusMessageString];
		if (currentStatusMessage &&
			([currentStatusMessage length] > [statusMessage length]) &&
			([statusMessage length] >= 40) &&
			([currentStatusMessage rangeOfString:[statusMessage string] options:NSAnchoredSearch].location == 0)) {
			/* New message is shorter but at least 40 characters, and it matches the start of the current one.
			 * Do nothing.
			 */
			return;
		}
	}
	
	[super updateStatusForContact:theContact toStatusType:statusTypeNumber statusName:statusName statusMessage:statusMessage isMobile:isMobile];
}

/*!
 * @brief Is a contact on the contact list intentionally listed?
 *
 * This is used by AIListContact to determine if the prescence of itself on the list is indicative of a degree
 * of trust, for preferences such as "automatically accept files from contacts on my contact list".
 */
- (BOOL)isContactIntentionallyListed:(AIListContact *)contact
{
	return [contact remoteGroupName] && ![[contact remoteGroupName] isEqualToString:@"Recent Buddies"];
}

- (NSString *)localizedDateAndTimeFromString:(NSString *)inDateAndTime includeTimeWithDay:(BOOL)includeTimeWithDay
{
	NSString		*replacementString = nil;
	NSDateFormatter	*dayFormatter = [NSDateFormatter localizedDateFormatter];
	NSDateFormatter *timeFormatter = [NSDateFormatter localizedDateFormatterShowingSeconds:NO showingAMorPM:YES];
	struct tm tm;

	if (inDateAndTime && (strptime([inDateAndTime UTF8String], "%c", &tm) != NULL)) {
		NSString	*valueDay, *valueTime, *replacementString;
		NSDate		*date;
		/* Not set by strptime(); tells mktime()
		 * to determine whether daylight saving time
		 * is in effect */
		tm.tm_isdst = -1;

		date = [NSDate dateWithTimeIntervalSince1970:mktime(&tm)];

		//Get day & time strings
		valueDay = [dayFormatter stringForObjectValue:date];
		valueTime = [timeFormatter stringForObjectValue:date];

		if (valueDay && valueTime) {
			if ([[dayFormatter stringForObjectValue:[NSDate date]] isEqualToString:valueDay])
				//Show time
				replacementString = valueTime;
			else
				replacementString = (includeTimeWithDay ? [NSString stringWithFormat:@"%@, %@", valueDay, valueTime] : valueDay);
		}
	}

	return replacementString;
}

- (NSMutableArray *)arrayOfDictionariesFromPurpleNotifyUserInfo:(PurpleNotifyUserInfo *)user_info forContact:(AIListContact *)contact
{
	NSMutableArray *array = [super arrayOfDictionariesFromPurpleNotifyUserInfo:user_info forContact:contact];
	NSString *onlineSinceKey = [NSString stringWithUTF8String:_("Online Since")];
	NSString *memberSinceKey = [NSString stringWithUTF8String:_("Member Since")];

	int i;
	unsigned int count = [array count];
	for (i = 0; i < count; i++) {
		NSDictionary *dict = [array objectAtIndex:i];
		NSString *key = [dict objectForKey:KEY_KEY];
		if ([key isEqualToString:onlineSinceKey]) {
			NSString *replacementString = [self localizedDateAndTimeFromString:[dict objectForKey:KEY_VALUE]
															includeTimeWithDay:YES];
			if (replacementString) {
				NSMutableDictionary *replacementDict = [dict mutableCopy];
				[replacementDict setObject:replacementString forKey:KEY_VALUE];
				[array replaceObjectAtIndex:i withObject:replacementDict];
				[replacementDict release];
			}
		} else if ([key isEqualToString:memberSinceKey]) {
			[array removeObjectAtIndex:i];
			
			//Decrement i so we look at the next item rather than skipping it
			i--;
			count--;
		}
	}

	return array;
}


#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, _("Edit Buddy Comment")) == 0) {
		return nil;

	} else if (strcmp(label, _("Re-request Authorization")) == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]];
		
	} else 	if (strcmp(label, _("Get AIM Info")) == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Get AIM information for %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, _("Direct IM")) == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Direct IM with %@",nil),[inContact formattedUID]];
	}

	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (strcmp(label, _("Set User Info...")) == 0) {
		//Handled via Get Info
		return nil;
		
	} else if (strcmp(label, _("Edit Buddy Comment")) == 0) {
		//Handled via Get Info
		return nil;
	} else if (strcmp(label, _("Show Buddies Awaiting Authorization")) == 0) {
		return AILocalizedString(@"Show Contacts Awaiting Authorization", "Account action menu item to show a list of contacts for whom this account is awaiting authorization to be able to show them in the contact list");

	} else if (strcmp(label, _("Configure IM Forwarding (URL)")) == 0) {
		return [AILocalizedString(@"Configure IM Forwarding", nil) stringByAppendingEllipsis];

	} else if (strcmp(label, _("Change Password (URL)")) == 0) {
		//There's no reason to have the URL version available - we have Change Password for in-app changing.
		return nil;
		
	} else if (strcmp(label, _("Display Currently Registered E-Mail Address")) == 0) {
		return AILocalizedString(@"Display Currently Registered Email Address", nil);
		
	} else if (strcmp(label, _("Change Currently Registered E-Mail Address...")) == 0) {
		return [AILocalizedString(@"Change Currently Registered Email Address", nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, _("Search for Buddy by E-Mail Address...")) == 0) {
		return [AILocalizedString(@"Search for Contact By Email Address", nil) stringByAppendingEllipsis];		

	} else if (strcmp(label, _("Set User Info (URL)...")) == 0) {
		return [AILocalizedString(@"Set User Info", nil) stringByAppendingEllipsis];

	} else if (strcmp(label, _("Set Privacy Options...")) == 0) {
		return [AILocalizedString(@"Set Privacy Options", nil) stringByAppendingEllipsis];
	}
	

	return [super titleForAccountActionMenuLabel:label];
}

#pragma mark Buddy status
- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	NSString		*statusName = nil;
	
	if (aim_snvalid_icq(purple_buddy_get_name(buddy))) {
		PurplePresence	*presence = purple_buddy_get_presence(buddy);
		PurpleStatus *status = purple_presence_get_active_status(presence);
		const char *purpleStatusID = purple_status_get_id(status);

		if (!strcmp(purpleStatusID, OSCAR_STATUS_ID_INVISIBLE)) {
			statusName = STATUS_NAME_INVISIBLE;

		} else if (!strcmp(purpleStatusID, OSCAR_STATUS_ID_OCCUPIED)) {
			statusName = STATUS_NAME_OCCUPIED;

		} else if (!strcmp(purpleStatusID, OSCAR_STATUS_ID_NA)) {
			statusName = STATUS_NAME_NOT_AVAILABLE;

		} else if (!strcmp(purpleStatusID, OSCAR_STATUS_ID_DND)) {
			statusName = STATUS_NAME_DND;

		} else if (!strcmp(purpleStatusID, OSCAR_STATUS_ID_FREE4CHAT)) {
			statusName = STATUS_NAME_FREE_FOR_CHAT;

		}
	}

	return statusName;
}

@end
