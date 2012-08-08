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
#import <Adium/AIContentTopic.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIContactHidingController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AISortController.h>

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#import "AIMessageWindowController.h"
#import "AIMessageWindow.h"
#import "AIInterfaceControllerProtocol.h"
#import "AIWebKitMessageViewController.h"
#import "AILoggerPlugin.h"


@interface AIChat ()
- (id)initForAccount:(AIAccount *)inAccount;
- (void)contentObjectAdded:(NSNotification *)notification;

- (void)clearUniqueChatID;
- (void)clearListObjectStatuses;

- (AIListContact *)visibleObjectAtIndex:(NSUInteger)idx;
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
		participatingContacts = [[NSMutableArray alloc] init];
		participatingContactsFlags = [[NSMutableDictionary alloc] init];
		participatingContactsAliases = [[NSMutableDictionary alloc] init];
		dateOpened = [[NSDate date] retain];
		uniqueChatID = nil;
		ignoredListContacts = nil;
		isOpen = NO;
		isGroupChat = NO;
		expanded = YES;
		customEmoticons = nil;
		hasSentOrReceivedContent = NO;
		showJoinLeave = YES;
		pendingOutgoingContentObjects = [[NSMutableArray alloc] init];

		AILog(@"[AIChat: %x initForAccount]",self);
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(contentObjectAdded:) 
													 name:Content_ContentObjectAdded 
												   object:self];
	}

    return self;
}

- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentMessage *content = [[notification userInfo] objectForKey:@"AIContentObject"];
	
	self.lastMessageDate = [content date];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	AILog(@"[%@ dealloc]",self);

	[account release];
	[self removeAllParticipatingContactsSilently];
	[participatingContacts release];
	[participatingContactsFlags release];
	[participatingContactsAliases release];
	[dateOpened release];
	[ignoredListContacts release];
	[pendingOutgoingContentObjects release];
	[uniqueChatID release]; uniqueChatID = nil;
	[customEmoticons release]; customEmoticons = nil;
	[topic release]; [topicSetter release];
	
	[tabStateIcon release]; tabStateIcon = nil;
    [chatCreationInfo release]; chatCreationInfo = nil;
    [enteredTextTimer release]; enteredTextTimer = nil;
    [securityDetails release]; securityDetails = nil;
	[lastMessageDate release]; lastMessageDate = nil;
	
	[super dealloc];
}

//Big image
- (NSImage *)chatImage
{
	AIListContact 	*listObject = nil;
	NSImage			*image = nil;

	if (self.isGroupChat) {
		listObject = (AIListContact *)[adium.contactController existingBookmarkForChat:self];
	} else {
		listObject = self.listObject;
	}

	if (listObject) {
		image = listObject.parentContact.userIcon;
		if (!image) image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconNormal];
	} else {
		image = [AIServiceIcons serviceIconForObject:self.account type:AIServiceIconLarge direction:AIIconNormal];
	}

	return image;
}

//lil image
- (NSImage *)chatMenuImage
{
	AIListObject 	*listObject = nil;
	NSImage			*chatMenuImage = nil;
	
	if (self.isGroupChat) {
		listObject = (AIListContact *)[adium.contactController existingBookmarkForChat:self];
	} else {
		listObject = self.listObject;
	}

	if (listObject) {
		chatMenuImage = [AIUserIcons menuUserIconForObject:listObject];
	} else {
		chatMenuImage = [AIServiceIcons serviceIconForObject:account
														type:AIServiceIconSmall
												   direction:AIIconNormal];
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
		[[NSNotificationCenter defaultCenter] postNotificationName:Chat_SourceChanged object:self]; //Notify
	}
}

/*@brief: holds information passed upon the creation of the chat:
 * handle, server, etc.
 */
- (NSDictionary *)chatCreationDictionary
{
	return chatCreationInfo;
}

- (void)setChatCreationDictionary:(NSDictionary *)inDict
{
	[self setValue:inDict
				   forProperty:@"chatCreationInfo"
				   notify:NotifyNever];
}

@synthesize hasSentOrReceivedContent, isOpen, dateOpened;

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (void)didModifyProperties:(NSSet *)keys silent:(BOOL)silent
{
	[adium.chatController chatStatusChanged:self
						   modifiedStatusKeys:keys
									   silent:silent];	
}

- (void)object:(id)inObject didChangeValueForProperty:(NSString *)key notify:(NotifyTiming)notify
{
	//If our unviewed content changes or typing status changes, and we have a single list object, 
	//apply the change to that object as well so it can be cleanly reflected in the contact list.
	if ([key isEqualToString:KEY_UNVIEWED_CONTENT] ||
		[key isEqualToString:KEY_TYPING]) {
		AIListObject	*listObject = nil;
		
		if (self.isGroupChat) {
			listObject = (AIListContact *)[adium.contactController existingBookmarkForChat:self];
		} else {
			listObject = self.listObject;
		}
		
		if (listObject) [listObject setValue:[self valueForProperty:key] forProperty:key notify:notify];
	}
	
	[super object:inObject didChangeValueForProperty:key notify:notify];
}

- (void)clearListObjectStatuses
{
	AIListObject	*listObject = self.listObject;
	
	if (listObject) {
		[listObject setValue:nil forProperty:KEY_UNVIEWED_CONTENT notify:NotifyLater];
		[listObject setValue:nil forProperty:KEY_TYPING notify:NotifyLater];
	
		[listObject notifyOfChangedPropertiesSilently:NO];
	}
	
}
//Secure chatting ------------------------------------------------------------------------------------------------------
- (void)setSecurityDetails:(NSDictionary *)inSecurityDetails
{
	[self setValue:inSecurityDetails
				   forProperty:@"securityDetails"
				   notify:NotifyNow];
}
- (NSDictionary *)securityDetails
{
	return securityDetails;
}

- (BOOL)isSecure
{	
	return self.encryptionStatus != EncryptionStatus_None;
}

- (AIEncryptionStatus)encryptionStatus
{
	AIEncryptionStatus	encryptionStatus = EncryptionStatus_None;
	
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
	return [account allowSecureMessagingTogglingForChat:self];
}

//Name  ----------------------------------------------------------------------------------------------------------------
#pragma mark Name

@synthesize name;

/*!
 * @brief An identifier which can be used to look up this chat later
 *
 * Use uniqueChatID as a unique identifier for a contact-service combination.
 * Only an account which created a chat should specify the identifier; it has no useful meaning outside that context.
 */
@synthesize identifier;

- (NSString *)displayName
{
    NSString	*outName = [self displayArrayObjectForKey:@"Display Name"];
    return outName ? outName : (name ? name : self.listObject.displayName);
}

- (void)setDisplayName:(NSString *)inDisplayName
{
	[[self displayArrayForKey:@"Display Name"] setObject:inDisplayName
											   withOwner:[NSValue valueWithNonretainedObject:self] /* Don't want a retain loop */
										   priorityLevel:Highest_Priority];

	//The display array doesn't cause an attribute update; fake it.
	[adium.chatController chatStatusChanged:self
						 modifiedStatusKeys:[NSSet setWithObject:@"Display Name"]
									 silent:NO];
}

//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects

/*!
 * @brief The display name for the contact in this chat.
 *
 * @param contact The AIListObject whose display name should be created
 *
 * If the user has an alias set, the alias is used, otherwise the display name.
 *
 * @returns Display name
 */
- (NSString *)displayNameForContact:(AIListObject *)contact
{
	return [self aliasForContact:contact] ?: contact.displayName;
}

/*!
 * @brief The flags for a given contact.
 */
- (AIGroupChatFlags)flagsForContact:(AIListObject *)contact
{
	return [(NSNumber *)[participatingContactsFlags objectForKey:contact.UID] intValue];
}

/*!
 * @brief The alias for a given contact
 */
- (NSString *)aliasForContact:(AIListObject *)contact
{
	NSString *alias = [participatingContactsAliases objectForKey:contact.UID];
	
	if (!alias && self.isGroupChat) {
		alias = [self.account fallbackAliasForContact:(AIListContact *)contact inChat:self];
	}
	
	return alias;
}

/*!
 * @brief Set the flags for a contact
 *
 * Note that this doesn't set the bitwise or; this directly sets the value passed.
 */
- (void)setFlags:(AIGroupChatFlags)flags forContact:(AIListObject *)contact
{
	[participatingContactsFlags setObject:[NSNumber numberWithInteger:flags]
								   forKey:contact.UID];
}

/*!
 * @brief Set the alias for a contact.
 */
- (void)setAlias:(NSString *)alias forContact:(AIListObject *)contact
{
	[participatingContactsAliases setObject:alias
									 forKey:contact.UID];
}

AIGroupChatFlags highestFlag(AIGroupChatFlags flags)
{
	if ((flags & AIGroupChatFounder) == AIGroupChatFounder)
		return AIGroupChatFounder;
	
	if ((flags & AIGroupChatOp) == AIGroupChatOp)
		return AIGroupChatOp;
	
	if ((flags & AIGroupChatHalfOp) == AIGroupChatHalfOp)
		return AIGroupChatHalfOp;
	
	if ((flags & AIGroupChatVoice) == AIGroupChatVoice)
		return AIGroupChatVoice;
	
	return AIGroupChatNone;
}

/*!
 * @brief Resorts our participants
 *
 * This is called when our list objects change.
 */
- (void)resortParticipants
{
	[participatingContacts sortUsingComparator:^(id objectA, id objectB){
		AIGroupChatFlags flagA = highestFlag([self flagsForContact:objectA]), flagB = highestFlag([self flagsForContact:objectB]);
		
		if(flagA > flagB) {
			return (NSComparisonResult)NSOrderedAscending;
		} else if (flagA < flagB) {
			return (NSComparisonResult)NSOrderedDescending;
		} else {
			return [[self displayNameForContact:objectA] localizedCaseInsensitiveCompare:[self displayNameForContact:objectB]];
		}
	}];
}

/*!
 * @brief Remove the saved values for a contact
 *
 * Removes any values which are dependent upon the contact, such as
 * its flags or alias.
*/
- (void)removeSavedValuesForContactUID:(NSString *)contactUID
{
	[participatingContactsFlags removeObjectForKey:contactUID];
	[participatingContactsAliases removeObjectForKey:contactUID];
}

- (void)addParticipatingListObject:(AIListContact *)inObject notify:(BOOL)notify
{
	[self addParticipatingListObjects:[NSArray arrayWithObject:inObject] notify:notify];
}

- (void)addParticipatingListObjects:(NSArray *)inObjects notify:(BOOL)notify
{
	NSMutableArray *contacts = [inObjects mutableCopy];

	for (AIListObject *obj in inObjects) {
		if ([self containsObject:obj] || ![self canContainObject:obj])
			[contacts removeObject:obj];
	}
	
	[participatingContacts addObjectsFromArray:contacts];
	[adium.chatController chat:self addedListContacts:contacts notify:notify];
	[contacts release];
}

- (BOOL)addObject:(AIListObject *)inObject
{
	NSParameterAssert([inObject isKindOfClass:[AIListContact class]]);

	[self addParticipatingListObject:(AIListContact *)inObject notify:YES];
	return YES;
}

// Invite a list object to join the chat. Returns YES if the chat joins, NO otherwise
- (BOOL)inviteListContact:(AIListContact *)inContact withMessage:(NSString *)inviteMessage
{
	return ([self.account inviteContact:inContact toChat:self withMessage:inviteMessage]);
}

@synthesize preferredListObject = preferredContact;

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListContact *)listObject
{
	if (self.countOfContainedObjects == 1 && !self.isGroupChat) {
		return (AIListContact *)[self visibleObjectAtIndex:0];
	}

	return nil;
}

- (void)setListObject:(AIListContact *)inListObject
{
	if (inListObject != self.listObject) {
		if (self.countOfContainedObjects) {
			[participatingContacts removeObjectAtIndex:0];
		}
		[self addParticipatingListObject:inListObject notify:YES];

		//Clear any local caches relying on the list object
		[self clearListObjectStatuses];
		[self clearUniqueChatID];

		//Notify once the destination has been changed
		[[NSNotificationCenter defaultCenter] postNotificationName:Chat_DestinationChanged object:self];
	}
}

- (NSString *)uniqueChatID
{
	if (!uniqueChatID) {
		if (self.isGroupChat) {
			uniqueChatID = [[NSString alloc] initWithFormat:@"%@.%i", self.name, nextChatNumber++];
		} else {			
			uniqueChatID = [self.listObject.internalObjectID retain];
		}

		if (!uniqueChatID) {
			uniqueChatID = [[NSString alloc] initWithFormat:@"UnknownChat.%i", nextChatNumber++];
			NSLog(@"Warning: Unknown chat %p",self);
		}
	}

	return uniqueChatID;
}

- (void)clearUniqueChatID
{
	[uniqueChatID release]; uniqueChatID = nil;
}

- (NSString *)internalObjectID
{
	return self.uniqueChatID;
}


//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content

@synthesize lastMessageDate;

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
	NSInteger	currentIndex = [pendingOutgoingContentObjects indexOfObjectIdenticalTo:inObject];

	//Don't add the object twice when we are called from -[AIChat finishedSendingContentObject]
	if (currentIndex == NSNotFound) {
		[pendingOutgoingContentObjects addObject:inObject];		
	}

	return pendingOutgoingContentObjects.count == 1 || currentIndex == 0;
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
	
	if (pendingOutgoingContentObjects.count) {
		[adium.contentController sendContentObject:[pendingOutgoingContentObjects objectAtIndex:0]];
	}
}

- (AIChatSendingAbilityType)messageSendingAbility
{
	AIChatSendingAbilityType sendingAbilityType;

	if (self.isGroupChat) {
		if (self.account.online) {
			//XXX Liar!
			sendingAbilityType = AIChatCanSendMessageNow;
		} else {
			sendingAbilityType = AIChatCanNotSendMessage;
		}

	} else {
		if (self.account.online) {
			AIListContact *listObject = self.listObject;
			
			if (listObject.online || listObject.isStranger) {
				sendingAbilityType = AIChatCanSendMessageNow;
			} else if ([self.account canSendOfflineMessageToContact:listObject]) {
				sendingAbilityType = AIChatCanSendViaServersideOfflineMessage;				
			} else if ([self.account maySendMessageToInvisibleContact:listObject]) {
				sendingAbilityType = AIChatMayNotBeAbleToSendMessage;	
			} else {
				sendingAbilityType = AIChatCanNotSendMessage;
			}

		} else {
			sendingAbilityType = AIChatCanNotSendMessage;
		}		
	}
	
	return sendingAbilityType;
}

- (BOOL)canSendImages
{
	return [self.account canSendImagesForChat:self];
}

- (NSUInteger)unviewedContentCount
{
	return [self integerValueForProperty:KEY_UNVIEWED_CONTENT];
}

- (NSUInteger)unviewedMentionCount
{
	return [self integerValueForProperty:KEY_UNVIEWED_MENTION];
}

- (void)incrementUnviewedContentCount
{
	NSInteger currentUnviewed = [self integerValueForProperty:KEY_UNVIEWED_CONTENT];
	[self setValue:[NSNumber numberWithInteger:(currentUnviewed+1)]
					 forProperty:KEY_UNVIEWED_CONTENT
					 notify:NotifyNow];
}

- (void)incrementUnviewedMentionCount
{
	NSInteger currentUnviewed = [self integerValueForProperty:KEY_UNVIEWED_MENTION];
	[self setValue:[NSNumber numberWithInteger:(currentUnviewed+1)]
	   forProperty:KEY_UNVIEWED_MENTION
			notify:NotifyNow];
}

- (void)clearUnviewedContentCount
{
	// We also want to clear mention for the same situations we clear normal content.
	[self setValue:nil forProperty:KEY_UNVIEWED_MENTION notify:NotifyNow];
	[self setValue:nil forProperty:KEY_UNVIEWED_CONTENT notify:NotifyNow];
}

#pragma mark Logging

- (BOOL)shouldLog
{
	BOOL shouldLog = [self.account shouldLogChat:self];
	
	if(shouldLog && self.isSecure) {
		shouldLog = [[adium.preferenceController preferenceForKey:KEY_LOGGER_SECURE_CHATS
															group:PREF_GROUP_LOGGING] boolValue];
	}
	
	return shouldLog;
}

#pragma mark AIContainingObject protocol
- (NSArray *)visibleContainedObjects
{
	return self.containedObjects;
}
- (NSArray *)containedObjects
{
	return participatingContacts;
}
- (NSUInteger)countOfContainedObjects
{
	return [participatingContacts count];
}

- (BOOL)containsObject:(AIListObject *)inObject
{
	return [participatingContacts containsObjectIdenticalTo:inObject];
}

- (AIListContact *)visibleObjectAtIndex:(NSUInteger)idx
{
	return [participatingContacts objectAtIndex:idx];
}

- (NSUInteger)visibleIndexOfObject:(AIListObject *)obj
{
	if(![[AIContactHidingController sharedController] visibilityOfListObject:obj inContainer:self])
		return NSNotFound;
	return [participatingContacts indexOfObject:obj];
}

//Retrieve a specific object by service and UID
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	for (AIListContact *object in self) {
		if ([inUID isEqualToString:object.UID] && object.service == inService)
			return object;
	}
	
	return nil;
}

- (NSArray *)uniqueContainedObjects
{
	return self.containedObjects;
}

- (void)removeObject:(AIListObject *)inObject
{
	if ([self containsObject:inObject]) {
		AIListContact *contact = (AIListContact *)inObject; //if we contain it, it has to be an AIListContact
		
		//make sure removing it from the array doesn't deallocate it immediately, since we need it for -chat:removedListContact:
		[inObject retain];
		
		[participatingContacts removeObject:inObject];
		
		[self removeSavedValuesForContactUID:inObject.UID];

		[adium.chatController chat:self removedListContact:contact];

		if (contact.isStranger &&
			![adium.chatController allGroupChatsContainingContact:contact.parentContact].count &&
			![adium.chatController existingChatWithContact:contact.parentContact]) {
			
			[[AIContactObserverManager sharedManager] delayListObjectNotifications];
			[adium.contactController accountDidStopTrackingContact:contact];
			[[AIContactObserverManager sharedManager] endListObjectNotificationsDelaysImmediately];
		}
		
		[inObject release];
	}
}

- (void)removeObjectAfterAccountStopsTracking:(AIListObject *)object
{
	[self removeObject:object]; //does nothing if we've already removed it
}

- (void)removeAllParticipatingContactsSilently
{
	/* Note that allGroupChatsContainingContact won't count this chat if it's already marked as not open */
	for (AIListContact *listContact in self) {
		if (listContact.isStranger &&
			![adium.chatController existingChatWithContact:listContact.parentContact] &&
			([adium.chatController allGroupChatsContainingContact:listContact.parentContact].count == 0)) {
			[adium.contactController accountDidStopTrackingContact:listContact];
		}
	}

	[participatingContacts removeAllObjects];
	[participatingContactsFlags removeAllObjects];
	[participatingContactsAliases removeAllObjects];

	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
											  object:self];
}

@synthesize expanded;

- (BOOL)isExpandable
{
	return NO;
}

- (NSUInteger)visibleCount
{
	return self.countOfContainedObjects;
}

- (NSString *)contentsBasedIdentifier
{
	return [NSString stringWithFormat:@"%@-%@.%@",self.name, self.account.service.serviceID, self.account.UID];
}

//Not used
- (float)smallestOrder { return 0; }
- (float)largestOrder { return 1E10f; }
- (float)orderIndexForObject:(AIListObject *)listObject { return 0; }
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex {};


#pragma mark Ignoring
/*!
 * @brief Set the ignored state of a contact
 *
 * @param inContact The contact whose state is to be changed
 * @param isIgnored YES to ignore the contact; NO to not ignore the contact
 */
- (void)setListContact:(AIListContact *)inContact isIgnored:(BOOL)isIgnored
{
	if (self.account.accountManagesGroupChatIgnore) {
		[self.account setContact:inContact ignored:isIgnored inChat:self];
	} else {
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
}

/*!
 * @brief Is the passed object ignored?
 *
 * @param inContact The contact to check
 * @result YES if the contact is ignored; NO if it is not
 */
- (BOOL)isListContactIgnored:(AIListObject *)inContact
{
	if (self.account.accountManagesGroupChatIgnore) {
		return [self.account contact:(AIListContact *)inContact isIgnoredInChat:self];
	} else {
		return [ignoredListContacts containsObject:inContact];
	}
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

#pragma mark Group Chats

@synthesize isGroupChat, showJoinLeave, hideUserIconAndStatus;

/*!
 * @brief Does this chat support topics?
 */
- (BOOL)supportsTopic
{
	return account.groupChatsSupportTopic;
}

/*!
 * @brief Update the topic.
 */
- (void)updateTopic:(NSString *)inTopic withSource:(AIListContact *)contact
{
	[self setValue:inTopic forProperty:KEY_TOPIC notify:NotifyNow];
	
	[self setValue:contact forProperty:KEY_TOPIC_SETTER notify:NotifyNow];
	
	// Apply the new topic to the message view
	AIContentTopic *contentTopic = [AIContentTopic topicInChat:self
													withSource:contact
												   destination:nil
														  date:[NSDate date]
													   message:[NSAttributedString stringWithString:[self valueForProperty:KEY_TOPIC] ?: @""]];
	
	// The content controller has huge problems with blank messages being let through.
	if (![[self valueForProperty:KEY_TOPIC] length]) {
		contentTopic.message = CONTENT_TOPIC_MESSAGE_ACTUALLY_EMPTY;
		contentTopic.actuallyBlank = YES;
	}
	
	[adium.contentController receiveContentObject:contentTopic];
}

/*!
 * @brief Set the chat's topic, telling the account to update it.
 */
- (void)setTopic:(NSString *)inTopic
{
	if (self.supportsTopic) {
		// We mess with the topic, replacing nbsp with spaces; make sure we're not setting an identical one other than this.
		NSString *tempTopic = [[self valueForProperty:KEY_TOPIC] stringByReplacingOccurrencesOfString:@"\u00A0" withString:@" "];
		if ([tempTopic isEqualToString:inTopic]) {
			AILogWithSignature(@"Not setting topic for %@, already the same.", self);
		} else {
			AILogWithSignature(@"Setting %@ topic to: %@", self, [self valueForProperty:KEY_TOPIC]);
			[account setTopic:inTopic forChat:self];
		}
	} else {
		AILogWithSignature(@"Attempt to set %@ topic when account doesn't support it.");
	}
}

#pragma mark Custom emoticons

- (void)addCustomEmoticon:(AIEmoticon *)inEmoticon
{
	if (!customEmoticons) customEmoticons = [[NSMutableSet alloc] init];
	[customEmoticons addObject:inEmoticon];
}

@synthesize customEmoticons;

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
	return [self.account actionMenuForChat:self];
}
- (void)setActionMenu:(NSMenu *)inMenu {};

#pragma mark Applescript

- (NSScriptObjectSpecifier *)objectSpecifier
{
	AIMessageWindowController *windowController = self.chatContainer.windowController;	
	NSScriptClassDescription *containerClassDesc;
	NSScriptObjectSpecifier *containerRef = nil;
	if (windowController) {
		containerRef = [[windowController window] objectSpecifier];
		containerClassDesc = [containerRef keyClassDescription];
	} else {
		containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	}
	
	return [[[NSUniqueIDSpecifier allocWithZone:[self zone]]
		initWithContainerClassDescription:containerClassDesc
		containerSpecifier:containerRef key:@"chats" uniqueID:[self uniqueChatID]] autorelease];
}

- (unsigned int)index
{
	//what we're going to do is find this tab in the tab view's hierarchy, so as to get its index
	AIMessageWindowController *windowController = self.chatContainer.windowController;

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
	AIMessageWindowController *windowController = self.chatContainer.windowController;
	NSArray *chats = [windowController containedChats];
	NSAssert (index-1 < [chats count], @"Don't let index be bigger than the count!");
	NSLog(@"Trying to move %@ in %@ to %u",messageTab,window,index-1);
	[windowController moveTabViewItem:messageTab toIndex:index-1]; //This is bad bad bad. Why?
	
}*/

- (NSString *)scriptingName
{
	NSString *aName = self.name;
	if (!aName)
		aName = self.listObject.UID;
	return aName;
}

- (id <AIChatContainer>)chatContainer
{
	return [self valueForProperty:@"messageTabViewItem"];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)closeCommand
{
	[adium.interfaceController closeChat:self];
	return nil;
}

- (void)setUniqueChatID:(NSString *)str
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
}

- (AIAccount *)scriptingAccount
{
	return self.account;
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
											  withSource:self.account
											 destination:self.listObject
													date:nil
												 message:attributedMessage
											   autoreply:NO];
		
		[adium.contentController sendContentObject:messageContent];
	}
	
	//Send any file we were told to send to every participating list object (anyone remember the AOL mass mailing zareW scene?)
	if (fileURL && fileURL.path.length) {
		
		for (AIListContact *listContact in self) {
			AIListContact   *targetFileTransferContact;
			
			//Make sure we know where we are sending the file by finding the best contact for
			//sending CONTENT_FILE_TRANSFER_TYPE.
			if ((targetFileTransferContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																						forListContact:listContact])) {
				[adium.fileTransferController sendFile:[fileURL path]
										   toListContact:targetFileTransferContact];
			} else {
				AILogWithSignature(@"No contact available to receive files to %@", listContact);
				NSBeep();
			}
		}
	}
	
	return nil;
}

/*!
 * @brief Applescript command to make this chat active
 */
- (id)goActiveScriptCommand:(NSScriptCommand *)command 
{
	[adium.interfaceController setActiveChat:self];
	return nil;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [self.containedObjects countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (BOOL) canContainObject:(id)obj
{
	return [obj isKindOfClass:[AIListContact class]];
}

@end
