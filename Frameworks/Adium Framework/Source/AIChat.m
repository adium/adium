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
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>

#import "AIMessageWindowController.h"
#import "AIMessageWindow.h"
#import "AIInterfaceControllerProtocol.h"
#import "AIWebKitMessageViewController.h"


@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount;
- (void)clearUniqueChatID;
- (void)clearListObjectStatuses;
@end

@implementation AIChat

static int nextChatNumber = 0;

+ (id)chatForAccount:(AIAccount *)inAccount
{
    return [[[self alloc] initForAccount:inAccount] autorelease];
}

- (id)initForAccount:(AIAccount *)inAccount
{
    if ((self = [super init])) {
		name = nil;
		account = [inAccount retain];
		participatingListObjects = [[NSMutableArray alloc] init];
		dateOpened = [[NSDate date] retain];
		uniqueChatID = nil;
		ignoredListContacts = nil;
		isOpen = NO;
		isGroupChat = NO;
		expanded = YES;
		customEmoticons = nil;
		hasSentOrReceivedContent = NO;
		pendingOutgoingContentObjects = [[NSMutableArray alloc] init];

		AILog(@"[AIChat: %x initForAccount]",self);
	}

    return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	AILog(@"[%@ dealloc]",self);

	[account release];
	[participatingListObjects release];
	[dateOpened release];
	[ignoredListContacts release];
	[pendingOutgoingContentObjects release];
	[uniqueChatID release]; uniqueChatID = nil;
	[customEmoticons release]; customEmoticons = nil;

	[super dealloc];
}

//Big image
- (NSImage *)chatImage
{
	AIListContact 	*listObject = [self listObject];
	NSImage			*image = nil;

	if (listObject) {
		image = [[listObject parentContact] userIcon];
		if (!image) image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconNormal];
	} else {
		image = [AIServiceIcons serviceIconForObject:[self account] type:AIServiceIconLarge direction:AIIconNormal];
	}

	return image;
}

//lil image
- (NSImage *)chatMenuImage
{
	AIListObject 	*listObject;
	NSImage			*chatMenuImage = nil;
	
	if ((listObject = [self listObject])) {
		chatMenuImage = [AIUserIcons menuUserIconForObject:listObject];
	}

	return chatMenuImage;
}


//Associated Account ---------------------------------------------------------------------------------------------------
#pragma mark Associated Account
- (AIAccount *)account
{
    return account;
}

- (void)setAccount:(AIAccount *)inAccount
{
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
		
		//The uniqueChatID may depend upon the account, so clear it
		[self clearUniqueChatID];
		[[adium notificationCenter] postNotificationName:Chat_SourceChanged object:self]; //Notify
	}
}

/*@brief: holds information passed upon the creation of the chat:
 * handle, server, etc.
 */
- (NSDictionary *)chatCreationDictionary
{
	return [self valueForProperty:@"ChatCreationInfo"];
}

- (void)setChatCreationDictionary:(NSDictionary *)inDict
{
	[self setValue:inDict
				   forProperty:@"ChatCreationInfo"
				   notify:NotifyNever];
}

- (void)accountDidJoinChat
{
	[self willChangeValueForKey:@"actionMenu"];
	[self didChangeValueForKey:@"actionMenu"];
}

//Date Opened
#pragma mark Date Opened
- (NSDate *)dateOpened
{
	return dateOpened;
}

- (BOOL)isOpen
{
	return isOpen;
}
- (void)setIsOpen:(BOOL)flag
{
	isOpen = flag;
}

- (BOOL)hasSentOrReceivedContent
{
	return hasSentOrReceivedContent;
}
- (void)setHasSentOrReceivedContent:(BOOL)flag
{
	hasSentOrReceivedContent = flag;
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (void)didModifyProperties:(NSSet *)keys silent:(BOOL)silent
{
	[[adium chatController] chatStatusChanged:self
						   modifiedStatusKeys:keys
									   silent:silent];	
}

- (void)object:(id)inObject didChangeValueForProperty:(NSString *)key notify:(NotifyTiming)notify
{
	//If our unviewed content changes or typing status changes, and we have a single list object, 
	//apply the change to that object as well so it can be cleanly reflected in the contact list.
	if ([key isEqualToString:KEY_UNVIEWED_CONTENT] ||
		[key isEqualToString:KEY_TYPING]) {
		AIListObject	*listObject = [self listObject];
		
		if (listObject) [listObject setValue:[self valueForProperty:key] forProperty:key notify:notify];
	}
	
	[super object:inObject didChangeValueForProperty:key notify:notify];
}

- (void)clearListObjectStatuses
{
	AIListObject	*listObject = [self listObject];
	
	if (listObject) {
		[listObject setValue:nil forProperty:KEY_UNVIEWED_CONTENT notify:NotifyLater];
		[listObject setValue:nil forProperty:KEY_TYPING notify:NotifyLater];
	
		[listObject notifyOfChangedPropertiesSilently:NO];
	}
	
}
//Secure chatting ------------------------------------------------------------------------------------------------------
- (void)setSecurityDetails:(NSDictionary *)securityDetails
{
	[self setValue:securityDetails
				   forProperty:@"SecurityDetails"
				   notify:NotifyNow];
}
- (NSDictionary *)securityDetails
{
	return [self valueForProperty:@"SecurityDetails"];
}

- (BOOL)isSecure
{
	AIEncryptionStatus encryptionStatus = [self encryptionStatus];
	
	return (encryptionStatus != EncryptionStatus_None);
}

- (AIEncryptionStatus)encryptionStatus
{
	AIEncryptionStatus	encryptionStatus = EncryptionStatus_None;

	NSDictionary		*securityDetails = [self securityDetails];
	if (securityDetails) {
		NSNumber *detailsStatus;
		if ((detailsStatus = [securityDetails objectForKey:@"EncryptionStatus"])) {
			encryptionStatus = [detailsStatus intValue];
			
		} else {
			/* If we don't have a specific encryption status, but do have security details, assume
			 * encrypted and verified.
			 */
			encryptionStatus = EncryptionStatus_Verified;
		}
	}

	return encryptionStatus;
}

- (BOOL)supportsSecureMessagingToggling
{
	return (BOOL)[account allowSecureMessagingTogglingForChat:self];
}

//Name  ----------------------------------------------------------------------------------------------------------------
#pragma mark Name
- (NSString *)name
{
	return name;
}
- (void)setName:(NSString *)inName
{
	if (name != inName) {
		[name release]; name = [inName retain]; 
	}
}

/*!
 * @brief Return an identifier which can be used to look up this chat later
 *
 * Use setIdentifier to specify an arbitrary identifier for this chat.
 *
 * Use uniqueChatID as a unique identifier for a contact-service combination.
 */
- (id)identifier
{
	return identifier;
}

/*!
 * @brief Set an identifier for this chat
 *
 * Only an account which created a chat should specify the identifier; it has no useful menaing outside that context.
 */
- (void)setIdentifier:(id)inIdentifier
{
	if (identifier != inIdentifier) {
		[identifier release];
		identifier = [inIdentifier retain];
	}
}

- (NSString *)displayName
{
    NSString	*outName = [self displayArrayObjectForKey:@"Display Name"];
    return outName ? outName : (name ? name : [[self listObject] displayName]);
}

- (void)setDisplayName:(NSString *)inDisplayName
{
	[[self displayArrayForKey:@"Display Name"] setObject:inDisplayName
											   withOwner:self];
}

//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects

- (void)addParticipatingListObject:(AIListContact *)inObject notify:(BOOL)notify
{
	if (![participatingListObjects containsObjectIdenticalTo:inObject]) {
		//Add
		[participatingListObjects addObject:inObject];

		[[adium chatController] chat:self addedListContact:inObject notify:notify];
	}
}

// Invite a list object to join the chat. Returns YES if the chat joins, NO otherwise
- (BOOL)inviteListContact:(AIListContact *)inContact withMessage:(NSString *)inviteMessage
{
	return ([[self account] inviteContact:inContact toChat:self withMessage:inviteMessage]);
}

- (void)setPreferredListObject:(AIListContact *)inObject
{
	preferredListObject = inObject;
}

- (AIListContact *)preferredListObject
{
	return preferredListObject;
}

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListContact *)listObject
{
    if (([participatingListObjects count] == 1) && ![self isGroupChat]) {
        return [participatingListObjects objectAtIndex:0];
    } else {
        return nil;
    }
}
- (void)setListObject:(AIListContact *)inListObject
{
	if (inListObject != [self listObject]) {
		if ([participatingListObjects count]) {
			[participatingListObjects removeObjectAtIndex:0];
		}
		[self addObject:inListObject];

		//Clear any local caches relying on the list object
		[self clearListObjectStatuses];
		[self clearUniqueChatID];

		//Notify once the destination has been changed
		[[adium notificationCenter] postNotificationName:Chat_DestinationChanged object:self];
	}
}

- (NSString *)uniqueChatID
{
	if (!uniqueChatID) {
		if ([self isGroupChat]) {
			uniqueChatID = [[NSString alloc] initWithFormat:@"%@.%i",[self name],nextChatNumber++];
		} else {			
			uniqueChatID = [[[self listObject] internalObjectID] retain];
		}

		if (!uniqueChatID) {
			uniqueChatID = [[NSString alloc] initWithFormat:@"UnknownChat.%i",nextChatNumber++];
			NSLog(@"Warning: Unknown chat %p",self);
		}
	}

	return uniqueChatID;
}

- (void)clearUniqueChatID
{
	[uniqueChatID release]; uniqueChatID = nil;
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content

/*!
 * @brief Informs the chat that the core and the account are ready to begin filtering and sending a content object
 *
 * If there is only one object in pendingOutgoingContentObjects after adding inObject, we should send immedaitely.
 * However, if other objects are in it, we should wait for them to be removed, as they are chronologically first.
 * If we are asked if we should begin sending the earliest object in pendingOutgoingContentObjects, the answer is YES.
 *
 * @param inObject The object being sent
 * @result YES if the object should be sent immediately; NO if another object is in process so we should wait
 */
- (BOOL)shouldBeginSendingContentObject:(AIContentObject *)inObject
{
	int	currentIndex = [pendingOutgoingContentObjects indexOfObjectIdenticalTo:inObject];

	//Don't add the object twice when we are called from -[AIChat finishedSendingContentObject]
	if (currentIndex == NSNotFound) {
		[pendingOutgoingContentObjects addObject:inObject];		
	}

	return (([pendingOutgoingContentObjects count] == 1) ||
			(currentIndex == 0));
}

/*!
 * @brief Informs the chat that an outgoing content object was sent and dispalyed.
 *
 * It is no longer pending, so we remove it from that array.
 * If there are more pending objects, trigger sending the next.
 *
 * @param inObject The object with which we are finished
 */
- (void)finishedSendingContentObject:(AIContentObject *)inObject
{
	[pendingOutgoingContentObjects removeObjectIdenticalTo:inObject];
	
	if ([pendingOutgoingContentObjects count]) {
		[[adium contentController] sendContentObject:[pendingOutgoingContentObjects objectAtIndex:0]];
	}
}

- (AIChatSendingAbilityType)messageSendingAbility
{
	AIChatSendingAbilityType sendingAbilityType;

	if ([self isGroupChat]) {
		if ([[self account] online]) {
			//XXX Liar!
			sendingAbilityType = AIChatCanSendMessageNow;
		} else {
			sendingAbilityType = AIChatCanNotSendMessage;
		}

	} else {
		if ([[self account] online]) {
			AIListContact *listObject = [self listObject];
			
			if ([listObject online] || [listObject isStranger]) {
				sendingAbilityType = AIChatCanSendMessageNow;
			} else if ([[self account] canSendOfflineMessageToContact:listObject]) {
				sendingAbilityType = AIChatCanSendViaServersideOfflineMessage;				
			} else {
				sendingAbilityType = AIChatMayNotBeAbleToSendMessage;	
			}

		} else {
			sendingAbilityType = AIChatCanNotSendMessage;
		}		
	}
	
	return sendingAbilityType;
}

- (BOOL)canSendImages
{
	return [[self account] canSendImagesForChat:self];
}

- (int)unviewedContentCount
{
	return [self integerValueForProperty:KEY_UNVIEWED_CONTENT];
}

- (void)incrementUnviewedContentCount
{
	int currentUnviewed = [self integerValueForProperty:KEY_UNVIEWED_CONTENT];
	[self setValue:[NSNumber numberWithInt:(currentUnviewed+1)]
					 forProperty:KEY_UNVIEWED_CONTENT
					 notify:NotifyNow];
}

- (void)clearUnviewedContentCount
{
	[self setValue:nil forProperty:KEY_UNVIEWED_CONTENT notify:NotifyNow];
}

#pragma mark AIContainingObject protocol
//AIContainingObject protocol
- (NSArray *)containedObjects
{
	return participatingListObjects;
}

- (unsigned)containedObjectsCount
{
	return [[self containedObjects] count];
}

- (BOOL)containsObject:(AIListObject *)inObject
{
	return [[self containedObjects] containsObjectIdenticalTo:inObject];
}

- (id)objectAtIndex:(unsigned)index
{
	return [[self containedObjects] objectAtIndex:index];
}

- (int)indexOfObject:(AIListObject *)inObject
{
    return [[self containedObjects] indexOfObject:inObject];
}

//Retrieve a specific object by service and UID
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject	*object;
	
	while ((object = [enumerator nextObject])) {
		if ([inUID isEqualToString:[object UID]] && [object service] == inService) break;
	}
	
	return object;
}

- (NSArray *)listContacts
{
	return [self containedObjects];
}

- (BOOL)addObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		[self addParticipatingListObject:(AIListContact *)inObject notify:YES];
		
		return YES;
	} else {
		return NO;
	}
}

- (void)removeObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]] && [participatingListObjects containsObjectIdenticalTo:inObject]) {
		[participatingListObjects removeObject:inObject];

		[[adium chatController] chat:self removedListContact:(AIListContact *)inObject];

		if ([inObject isStranger] &&
			![[adium chatController] existingChatWithContact:[(AIListContact *)inObject parentContact]]) {
			[[adium contactController] account:[(AIListContact *)inObject account]
						didStopTrackingContact:(AIListContact *)inObject];
		}		
	}
}

- (void)removeAllObjects 
{
	while([self containedObjectsCount] > 0)
		[self removeObject:[self objectAtIndex:0]];
}

- (void)removeAllParticipatingContactsSilently
{
	NSEnumerator *enumerator = [participatingListObjects objectEnumerator];
	AIListContact *listContact;
	while ((listContact = [enumerator nextObject])) {
		if ([listContact isStranger] &&
			![[adium chatController] existingChatWithContact:[(AIListContact *)listContact parentContact]]) {
			[[adium contactController] account:[listContact account]
						didStopTrackingContact:listContact];
		}
	}

	[participatingListObjects removeAllObjects];

	[[adium notificationCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:self];
}

- (void)setExpanded:(BOOL)inExpanded
{
	expanded = inExpanded;
}
- (BOOL)isExpanded
{
	return expanded;
}
- (BOOL)isExpandable
{
	return NO;
}

- (unsigned)visibleCount
{
	return [self containedObjectsCount];
}

- (NSString *)contentsBasedIdentifier
{
	return [NSString stringWithFormat:@"%@-%@.%@",[self name], [[self account] serviceID], [[self account] UID]];

}

//Not used
- (float)smallestOrder { return 0; }
- (float)largestOrder { return 1E10; }
- (float)orderIndexForObject:(AIListObject *)listObject { return 0; }
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex {};


#pragma mark	
/*!
 * @brief Set the ignored state of a contact
 *
 * @param inContact The contact whose state is to be changed
 * @param isIgnored YES to ignore the contact; NO to not ignore the contact
 */
- (void)setListContact:(AIListContact *)inContact isIgnored:(BOOL)isIgnored
{
	//Create ignoredListContacts if needed
	if (isIgnored && !ignoredListContacts) {
		ignoredListContacts = [[NSMutableSet alloc] init];	
	}

	if (isIgnored) {
		[ignoredListContacts addObject:inContact];
	} else {
		[ignoredListContacts removeObject:inContact];		
	}	
}

/*!
 * @brief Is the passed object ignored?
 *
 * @param inContact The contact to check
 * @result YES if the contact is ignored; NO if it is not
 */
- (BOOL)isListContactIgnored:(AIListObject *)inContact
{
	return [ignoredListContacts containsObject:inContact];
}

#pragma mark Comparison
- (BOOL)isEqual:(id)inChat
{
	return (inChat == self);
}

#pragma mark Debugging
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@:%@",
		[super description],
		(uniqueChatID ? uniqueChatID : @"<new>")];
}

#pragma mark Group Chat

- (void)setIsGroupChat:(BOOL)flag
{
	isGroupChat = flag;
}

- (BOOL)isGroupChat
{
	return isGroupChat;
}

#pragma mark Custom emoticons

- (void)addCustomEmoticon:(AIEmoticon *)inEmoticon
{
	if (!customEmoticons) customEmoticons = [[NSMutableSet alloc] init];
	[customEmoticons addObject:inEmoticon];
}

- (NSSet *)customEmoticons;
{
	return customEmoticons;
}

#pragma mark Errors

/*!
 * @brief Inform the chat that an error occurred
 *
 * @param type An NSNumber containing an AIChatErrorType
 */
- (void)receivedError:(NSNumber *)type
{
	//Notify observers
	[self setValue:type forProperty:KEY_CHAT_ERROR notify:NotifyNow];

	//No need to continue to store the NSNumber
	[self setValue:nil forProperty:KEY_CHAT_ERROR notify:NotifyNever];
}

#pragma mark Room commands
- (NSMenu *)actionMenu
{	
	return [[self account] actionsForChat:self];
}
- (void)setActionMenu:(NSMenu *)inMenu {};

#pragma mark Applescript

- (NSScriptObjectSpecifier *)objectSpecifier
{
	//the chat may not be in a window! Just reference it from the application...
	//get my window
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[[NSUniqueIDSpecifier allocWithZone:[self zone]]
		initWithContainerClassDescription:containerClassDesc
		containerSpecifier:nil key:@"chats" uniqueID:[self uniqueChatID]] autorelease];
}

- (unsigned int)index
{
	//what we're going to do is find this tab in the tab view's hierarchy, so as to get its index
	id<AIChatWindowController> windowController = [[self chatContainer] windowController];

	NSArray *chats = [windowController containedChats];
	for (unsigned int i=0;i<[chats count];i++) {
		if ([chats objectAtIndex:i] == self)
			return i+1; //one based
	}
	NSAssert(NO, @"This chat is weird.");
	return 0;
}
/*- (void)setIndex:(unsigned int)index
{
	id<AIChatWindowController> windowController = [[self chatContainer] windowController];
	NSArray *chats = [windowController containedChats];
	NSAssert (index-1 < [chats count], @"Don't let index be bigger than the count!");
	NSLog(@"Trying to move %@ in %@ to %u",messageTab,window,index-1);
	[windowController moveTabViewItem:messageTab toIndex:index-1]; //This is bad bad bad. Why?
	
}*/

- (NSString *)scriptingName
{
	NSString *aName = [self name];
	if (!aName)
		aName = [[self listObject] UID];
	return aName;
}

- (id <AIChatContainer>)chatContainer
{
	return [self valueForProperty:@"MessageTabViewItem"];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)closeCommand
{
	[[adium interfaceController] closeChat:self];
	return nil;
}

- (void)setUniqueChatID:(NSString *)str
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
}

- (AIAccount *)scriptingAccount
{
	return [self account];
}

- (void)setScriptingAccount:(AIAccount *)a
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't set the account of a chat."];
}

- (NSString *)content
{
	/*AITranscriptLogEnumerator *e = [[[AITranscriptLogReader alloc] initWithChat:self] autorelease];
	AIContentMessage *m;
	NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
	while ((m = [e nextObject])) {
		[result appendFormat:@"%@\n",[m messageString]];
	}
	return result;*/
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Still unsupported."];
	return nil;
}

/*!
 * @brief Applescript command to send a message in this chat
 */
- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	NSURL			*fileURL = [evaluatedArguments objectForKey:@"withFile"];
	
	//Send any message we were told to send
	if (message && [message length]) {
		//Take the string and turn it into an attributed string (in case we were passed HTML)
		NSAttributedString  *attributedMessage = [AIHTMLDecoder decodeHTML:message];
		AIContentMessage	*messageContent;
		messageContent = [AIContentMessage messageInChat:self
											  withSource:[self account]
											 destination:[self listObject]
													date:nil
												 message:attributedMessage
											   autoreply:NO];
		
		[[adium contentController] sendContentObject:messageContent];
	}
	
	//Send any file we were told to send to every participating list object (anyone remember the AOL mass mailing zareW scene?)
	if (fileURL && [[fileURL path] length]) {
		NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
		AIListContact	*listContact;
		
		while ((listContact = [enumerator nextObject])) {
			AIListContact   *targetFileTransferContact;
			
			//Make sure we know where we are sending the file by finding the best contact for
			//sending CONTENT_FILE_TRANSFER_TYPE.
			if ((targetFileTransferContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																						forListContact:listContact])) {
				[[adium fileTransferController] sendFile:[fileURL path]
										   toListContact:targetFileTransferContact];
			} else {
				AILogWithSignature(@"No contact available to receive files to %@", listContact);
				NSBeep();
			}
		}
	}
	
	return nil;
}

@end
