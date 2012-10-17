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


#import "AIContentController.h"

#import "AdiumTyping.h"
#import "AdiumFormatting.h"
#import "AdiumMessageEvents.h"
#import "AdiumContentFiltering.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIFileTransferControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AITextAttachmentExtension.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITextAttachmentAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIImageAdditions.h>

@interface AIContentController ()
- (void)finishReceiveContentObject:(AIContentObject *)inObject;
- (void)finishSendContentObject:(AIContentObject *)inObject;
- (void)finishDisplayContentObject:(AIContentObject *)inObject;

- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately;

- (BOOL)processAndSendContentObject:(AIContentObject *)inContentObject;

- (void)didFilterAttributedString:(NSAttributedString *)filteredMessage receivingContext:(AIContentObject *)inObject;
- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentSendingContext:(AIContentObject *)inObject;
- (void)didFilterAttributedString:(NSAttributedString *)filteredString autoreplySendingContext:(AIContentObject *)inObject;
- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentFilterDisplayContext:(AIContentObject *)inObject;
- (void)didFilterAttributedString:(NSAttributedString *)filteredString displayContext:(AIContentObject *)inObject;
@end

/*!
 * @class AIContentController
 * @brief Controller to manage incoming and outgoing content and chats.
 *
 * This controller handles default formatting and text entry filters, which can respond as text is entered in a message
 * window.  It the center for content filtering, including registering/unregistering of content filters.
 * It handles sending and receiving of content objects.  It manages chat observers, which are objects notified as
 * properties are set and removed on AIChat objects.  It manages chats themselves, tracking open ones, closing
 * them when needed, etc.  Finally, it provides Events related to sending and receiving content, such as Message Received.
 */
@implementation AIContentController

/*!
 * @brief Initialize the controller
 */
- (id)init
{
	if ((self = [super init])) {
		adiumTyping = [[AdiumTyping alloc] init];
		adiumFormatting = [[AdiumFormatting alloc] init];
		adiumContentFiltering = [[AdiumContentFiltering alloc] init];
		adiumMessageEvents = [[AdiumMessageEvents alloc] init];

		objectsBeingReceived = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (void)controllerDidLoad
{
	[adiumFormatting controllerDidLoad];
	[adiumMessageEvents controllerDidLoad];
}

/*!
 * @brief Close the controller
 */
- (void)controllerWillClose
{

}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[objectsBeingReceived release]; objectsBeingReceived = nil;
	[adiumTyping release]; adiumTyping = nil;
	[adiumFormatting release]; adiumFormatting = nil;
	[adiumContentFiltering release]; adiumContentFiltering = nil;
	[adiumEncryptor release];

    [super dealloc];
}

/*!
 * @brief Set the encryptor
 *
 * NB: We must _always_ have an encryptor.
 */
- (void)setEncryptor:(id<AdiumMessageEncryptor>)inEncryptor
{
	NSParameterAssert([inEncryptor conformsToProtocol:@protocol(AdiumMessageEncryptor)]);

	[adiumEncryptor release];
	adiumEncryptor = [inEncryptor retain];
}


#pragma mark Typing
/*!
 * @brief User is currently changing the content in a chat
 *
 * This should  be called by a text entry control like an NSTextView.
 *
 * @param chat The chat
 * @param hasEnteredText YES if there are one or more characters typed into the text entry area
 */
- (void)userIsTypingContentForChat:(AIChat *)chat hasEnteredText:(BOOL)hasEnteredText {
	[adiumTyping userIsTypingContentForChat:chat hasEnteredText:hasEnteredText];
}

#pragma mark Formatting
- (NSDictionary *)defaultFormattingAttributes {
	return [adiumFormatting defaultFormattingAttributes];
}

#pragma mark Content Filtering
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction {
	[adiumContentFiltering registerContentFilter:inFilter ofType:type direction:direction];
}
- (void)registerDelayedContentFilter:(id <AIDelayedContentFilter>)inFilter
							  ofType:(AIFilterType)type
						   direction:(AIFilterDirection)direction {
	[adiumContentFiltering registerDelayedContentFilter:inFilter ofType:type direction:direction];
}
- (void)registerHTMLContentFilter:(id <AIHTMLContentFilter>)inFilter
						direction:(AIFilterDirection)direction {
	[adiumContentFiltering registerHTMLContentFilter:inFilter
										   direction:direction];
}
- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter {
	[adiumContentFiltering unregisterContentFilter:inFilter];
}
- (void)unregisterDelayedContentFilter:(id <AIDelayedContentFilter>)inFilter {
	[adiumContentFiltering unregisterDelayedContentFilter:inFilter];
}
- (void)unregisterHTMLContentFilter:(id <AIHTMLContentFilter>)inFilter {
	[adiumContentFiltering unregisterHTMLContentFilter:inFilter];
}
- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString {
	[adiumContentFiltering registerFilterStringWhichRequiresPolling:inPollString];
}
- (BOOL)shouldPollToUpdateString:(NSString *)inString {
	return [adiumContentFiltering shouldPollToUpdateString:inString];
}
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)context {
	return [adiumContentFiltering filterAttributedString:attributedString
										 usingFilterType:type
											   direction:direction
												 context:context];
}
- (void)filterAttributedString:(NSAttributedString *)attributedString
			   usingFilterType:(AIFilterType)type
					 direction:(AIFilterDirection)direction
				 filterContext:(id)filterContext
			   notifyingTarget:(id)target
					  selector:(SEL)selector
					   context:(id)context {
	[adiumContentFiltering filterAttributedString:attributedString
								  usingFilterType:type
										direction:direction
									filterContext:filterContext
								  notifyingTarget:target
										 selector:selector
										  context:context];
}
- (NSString *)filterHTMLString:(NSString *)htmlString
					 direction:(AIFilterDirection)direction
					   content:(AIContentObject *)content
{
	return [adiumContentFiltering filterHTMLString:htmlString
										 direction:direction
										   content:(AIContentObject*)content];
}
- (void)delayedFilterDidFinish:(NSAttributedString *)attributedString uniqueID:(unsigned long long)uniqueID
{
	[adiumContentFiltering delayedFilterDidFinish:attributedString
										 uniqueID:uniqueID];
}

//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
//Receiving step 1: Add an incoming content object - entry point
- (void)receiveContentObject:(AIContentObject *)inObject
{
	if (inObject) {
		AIChat			*chat = inObject.chat;

		//Only proceed if the contact is not ignored or blocked
		if (!inObject.source || (![chat isListContactIgnored:[inObject source]] && ![[inObject source] isBlocked])) {
			//Notify: Will Receive Content
			if ([inObject trackContent]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:Content_WillReceiveContent
														  object:chat
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
			}

			//Run the object through our incoming content filters
			if ([inObject filterContent]) {
				//Track that we are in the process of receiving this object
				[objectsBeingReceived addObject:inObject];

				[self filterAttributedString:[inObject message]
							 usingFilterType:AIFilterContent
								   direction:AIFilterIncoming
							   filterContext:inObject
							 notifyingTarget:self
									selector:@selector(didFilterAttributedString:receivingContext:)
									 context:inObject];
				
			} else {
				[self finishReceiveContentObject:inObject];
			}
		} else {
			AILogWithSignature(@"%@ Message from blocked/ignored message: %@ %@", inObject.destination, inObject.source, inObject.message);
		}
    }
}

//Receiving step 2: filtering callback
- (void)didFilterAttributedString:(NSAttributedString *)filteredMessage receivingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredMessage];
	
	[self finishReceiveContentObject:inObject];
}

//Receiving step 3: Display the content
- (void)finishReceiveContentObject:(AIContentObject *)inContent
{	   
	//Display the content
	[self displayContentObject:inContent immediately:NO];
}

//Sending step 1: Entry point for any method in Adium which sends content
/*!
 * @brief Send a content object
 *
 * Sending step 1: Public method to send a content object.
 *
 * This method checks to be sure that messages are sent by accounts in the order they are sent by the user;
 * this can only be problematic when a delayedFilter is involved, leading to the user sending more messages before
 * the first finished sending.
 */
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
	//Only proceed if the chat allows it; if it doesn't, it will handle calling this method again when it is ready
	if ([inObject.chat shouldBeginSendingContentObject:inObject]) {

		//Run the object through our outgoing content filters
		if ([inObject filterContent]) {
			//Track that we are in the process of send this object
			[objectsBeingReceived addObject:inObject];

			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:AIFilterOutgoing
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:contentSendingContext:)
								 context:inObject];
			
		} else {
			[self finishSendContentObject:inObject];
		}
	}

	// XXX
	return YES;
}

//Sending step 2: Sending filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString contentSendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	//Special outgoing content filter for AIM away message bouncing.  Used to filter %n,%t,...
	if ([inObject isKindOfClass:[AIContentMessage class]] && [(AIContentMessage *)inObject isAutoreply]) {
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterAutoReplyContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:autoreplySendingContext:)
							 context:inObject];
	} else {		
		[self finishSendContentObject:inObject];
	}
}

//Sending step 3, applicable only when sending an autreply: Filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString autoreplySendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	[self finishSendContentObject:inObject];
}

//Sending step 4: Post notifications and ask the account to actually send the content.
- (void)finishSendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = inObject.chat;
	
	//Notify: Will Send Content
    if ([inObject trackContent]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }
	
	//Send the object
	if ([self processAndSendContentObject:inObject]) {
		if ([inObject displayContent]) {
			//Add the object
			[self displayContentObject:inObject immediately:NO];

		} else {
			//We are no longer in the process of receiving this object
			[objectsBeingReceived removeObject:inObject];
		}
		
		if ([inObject trackContent]) {
			AIListObject *listObject = chat.listObject;
			
			if(chat.isGroupChat) {
				listObject = (AIListObject *)[adium.contactController existingBookmarkForChat:chat];
			}
			
			//Did send content
			[adium.contactAlertsController generateEvent:[chat isGroupChat] ? CONTENT_MESSAGE_SENT_GROUP : CONTENT_MESSAGE_SENT
											 forListObject:listObject
												  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:chat,@"AIChat",inObject,@"AIContentObject",nil]
							  previouslyPerformedActionIDs:nil];
			
			[chat setHasSentOrReceivedContent:YES];
		}

	} else {
		//We are no longer in the process of receiving this object
		[objectsBeingReceived removeObject:inObject];
		
		NSString *message = [NSString stringWithFormat:AILocalizedString(@"Could not send from %@ to %@",nil),
			[[inObject source] formattedUID],[[inObject destination] formattedUID]];

		[self displayEvent:message
					ofType:@"chat-error"
					inChat:chat];			
	}
	
	//Let the chat know we finished sending
	[chat finishedSendingContentObject:inObject];
}

/*!
 * @brief Display content, optionally using content filters
 *
 * This should only be used for content which is not being sent or received but only displayed, such as message history. If you
 *
 * The ability to force filtering to be completed immediately exists for message history, which needs to put its display
 * in before the first message; otherwise, the use of delayed filtering would mean that message history showed up after the first message.
 * 
 * @param inObject The object to display
 * @param useContentFilters Should filters be used?
 * @param immediately If YES, only immediate filters will be used, and inObject will have its message set before we return.
 *					  If NO, immediate and delayed filters will be used, and inObject will be filtered over the course of some number of future run loops.
 */
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters immediately:(BOOL)immediately
{
	if (useContentFilters) {
		if (immediately) {
			//Filter in the main thread, set the message, and continue
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:AIFilterContent
													direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
													  context:inObject]];
			[self displayContentObject:inObject immediately:YES];
			
			
		} else {
			//Filter in the filter thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:contentFilterDisplayContext:)
								 context:inObject];
		}
	} else {
		//Just continue
		[self displayContentObject:inObject immediately:immediately];
	}
}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentFilterDisplayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	//Continue
	[self displayContentObject:inObject immediately:NO];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately
{
    //Filter the content object
    if ([inObject filterContent]) {
		BOOL				message = ([inObject isKindOfClass:[AIContentMessage class]] && ![(AIContentMessage *)inObject isAutoreply]);
		AIFilterType		filterType = (message ? AIFilterMessageDisplay : AIFilterDisplay);
		AIFilterDirection	direction = ([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming);
		
		if (immediately) {
			//Set it after filtering in the main thread, then display it
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:filterType
													direction:direction
													  context:inObject]];
			[self finishDisplayContentObject:inObject];		
			
		} else {
			//Filter in the filtering thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:filterType
							   direction:direction
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:displayContext:)
								 context:inObject];
		}
		
    } else {
		[self finishDisplayContentObject:inObject];
	}

}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString displayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	[self finishDisplayContentObject:inObject];
}

- (void)finishDisplayContentObject:(AIContentObject *)inObject
{
    //Check if the object should display
    if ([inObject displayContent] && ([[inObject message] length] > 0)) {
		AIChat			*chat = inObject.chat;
		NSDictionary	*userInfo;
		BOOL			contentReceived, shouldPostContentReceivedEvents;

		//If the chat of the content object has been cleared, we can't do anything with it, so simply return
		if (!chat) return;
		
		contentReceived = (([inObject isMemberOfClass:[AIContentMessage class]]) &&
						   (![inObject isOutgoing]));
		shouldPostContentReceivedEvents = contentReceived && [inObject trackContent];
		
		if (![chat isOpen]) {
			/* Tell the interface to open the chat
			 * For incoming messages, we don't open the chat until we're sure that new content is being received.
			 */
			[adium.interfaceController openChat:chat];
		}

		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:chat, @"AIChat", inObject, @"AIContentObject", nil];

		//Notify: Content Object Added
		[[NSNotificationCenter defaultCenter] postNotificationName:Content_ContentObjectAdded
												  object:chat
												userInfo:userInfo];		
		
		if (shouldPostContentReceivedEvents) {
			NSSet			*previouslyPerformedActionIDs = nil;
			AIListObject	*listObject = chat.listObject;
			
			if(chat.isGroupChat) {
				listObject = (AIListObject *)[adium.contactController existingBookmarkForChat:chat];
				
				if ([inObject.displayClasses containsObject:@"mention"]) {
					previouslyPerformedActionIDs = [adium.contactAlertsController generateEvent:CONTENT_GROUP_CHAT_MENTION
																				  forListObject:listObject
																					   userInfo:userInfo
																   previouslyPerformedActionIDs:previouslyPerformedActionIDs];

				}
			}
			
			if (![chat hasSentOrReceivedContent]) {
				//If the chat wasn't open before, generate CONTENT_MESSAGE_RECEIVED_FIRST
				if (!chat.isGroupChat) {
					previouslyPerformedActionIDs = [adium.contactAlertsController generateEvent:CONTENT_MESSAGE_RECEIVED_FIRST
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:previouslyPerformedActionIDs];
				}
				[chat setHasSentOrReceivedContent:YES];
			}

			if ([chat.account.statusState statusType] != AIAvailableStatusType) {
				//If the account is not available, generate CONTENT_MESSAGE_RECEIVED_AWAY
				previouslyPerformedActionIDs = [adium.contactAlertsController generateEvent:(chat.isGroupChat ? CONTENT_MESSAGE_RECEIVED_AWAY_GROUP : CONTENT_MESSAGE_RECEIVED_AWAY)
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:previouslyPerformedActionIDs];					
			}
			
			if (chat != adium.interfaceController.activeChat) {
				//If the chat is not currently active, generate CONTENT_MESSAGE_RECEIVED_BACKGROUND
				previouslyPerformedActionIDs = [adium.contactAlertsController generateEvent:(chat.isGroupChat ? CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP : CONTENT_MESSAGE_RECEIVED_BACKGROUND)
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:previouslyPerformedActionIDs];					
			}
			
			[adium.contactAlertsController generateEvent:(chat.isGroupChat ? CONTENT_MESSAGE_RECEIVED_GROUP : CONTENT_MESSAGE_RECEIVED)
											 forListObject:listObject
												  userInfo:userInfo
							  previouslyPerformedActionIDs:previouslyPerformedActionIDs];				
		}		
    }

	//We are no longer in the process of receiving this object
	[objectsBeingReceived removeObject:inObject];
	
	if (![inObject displayContent] && ![inObject.chat isOpen]) {
		// chat wasn't open, so close it so it doesn't leak
		[adium.interfaceController closeChat:inObject.chat];
	}
}

#pragma mark -

/*!
 * @brief Send any NSTextAttachments embedded in inContentMessage's message
 *
 * This method will remove such attachments after requesting their files being sent.
 *
 * If the account supports sending images on this message's chat and a file is an image it will be left in the
 * attributed string for processing later by AIHTMLDecoder.
 */
- (void)handleFileSendsForContentMessage:(AIContentMessage *)inContentMessage
{
	if (!inContentMessage.destination ||
		![inContentMessage.destination isKindOfClass:[AIListContact class]] ||
		![inContentMessage.chat.account availableForSendingContentType:CONTENT_FILE_TRANSFER_TYPE
															 toContact:(AIListContact *)inContentMessage.destination]) {
		//Simply return if we can't do anything about file sends for this message.
		return;
	}
	
	NSMutableAttributedString	*newAttributedString = nil;
	NSAttributedString			*attributedMessage = inContentMessage.message;
	NSUInteger					length = attributedMessage.length;

	if (length) {
		NSRange						searchRange = NSMakeRange(0,0);
		NSAttributedString			*currentAttributedString = attributedMessage;

		while (searchRange.location < length) {
			NSTextAttachment *textAttachment = [currentAttributedString attribute:NSAttachmentAttributeName
																		  atIndex:searchRange.location
																   effectiveRange:&searchRange];
			if (textAttachment) {
				BOOL shouldSendAttachmentAsFile;
				//Invariant within the loop, but most calls to handleFileSendsForContentMessage: don't get here at all
				BOOL canSendImages = [(AIAccount *)[inContentMessage source] canSendImagesForChat:inContentMessage.chat];

				if ([textAttachment isKindOfClass:[AITextAttachmentExtension class]]) {
					AITextAttachmentExtension *textAttachmentExtension = (AITextAttachmentExtension *)textAttachment;
					
					/* Send if:
					 *		This attachment isn't just for display (i.e. isn't an emoticon) AND
					 *		This chat can't send images, or it can but this attachment isn't an image
					 */
					shouldSendAttachmentAsFile = (![textAttachmentExtension shouldAlwaysSendAsText] &&
												  (!canSendImages || ![textAttachmentExtension attachesAnImage]));
					
				} else {
					shouldSendAttachmentAsFile = (!canSendImages || ![textAttachment wrapsImage]);
				}

				if (shouldSendAttachmentAsFile) {
					if (!newAttributedString) {
						newAttributedString = [[attributedMessage mutableCopy] autorelease];
						currentAttributedString = newAttributedString;
					}
					
					NSString	*path;
					if ([textAttachment isKindOfClass:[AITextAttachmentExtension class]]) {
						path = [(AITextAttachmentExtension *)textAttachment path];
						AILog(@"Sending text attachment %@ which has path %@",textAttachment,path);
					} else {
						//Write out the file so we can send it if we have a standard NSTextAttachment to send
						NSFileWrapper *fileWrapper = [textAttachment fileWrapper];
					
						//Desired folder: /private/tmp/$UID/`uuidgen`
						NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
						NSString *filename = [fileWrapper preferredFilename];
						if (!filename) filename = [NSString randomStringOfLength:5];
						
						path = [tmpDir stringByAppendingPathComponent:filename];

						if ([fileWrapper writeToFile:tmpDir atomically:YES updateFilenames:YES]) {
							AILog(@"Wrote out the file to %@ for sending",path);
						} else {
							NSLog(@"Failed to write out the file to %@ for sending", path);
							AILog(@"Failed to write out the file to %@ for sending", path);

							//The transfer is not going to happen so clear path
							path = nil;
						}
					}
					if (path) {
						[adium.fileTransferController sendFile:path
												   toListContact:(AIListContact *)inContentMessage.destination];
					} else {
						NSLog(@"-[AIContentController handleFileSendsForContentMessage:]: Warning: Failed to have a path for sending an inline file!");
						AILog(@"-[AIContentController handleFileSendsForContentMessage:]: Warning: Failed to have a path for sending an inline file for content message %@!",
							  inContentMessage);
					}

					//Now remove the attachment
					[newAttributedString removeAttribute:NSAttachmentAttributeName range:NSMakeRange(searchRange.location,
																									 searchRange.length)];
					[newAttributedString replaceCharactersInRange:searchRange withString:@""];
					//Decrease length by the number of characters we replaced
					length -= searchRange.length;
					
					//And don't increase our location in the searchRange.location += searchRange.length below
					searchRange.length = 0;
				}
			}
			
			//Onward and upward
			searchRange.location += searchRange.length;
		}
	}
	
	//If any  changes were made, update the AIContentMessage
	if (newAttributedString) {
		[inContentMessage setMessage:newAttributedString];
	}
}

/*!
 * @brief Handle sending a content object
 *
 * This method must return YES for the content to be displayed
 *
 * For a typing content object, the account is informed.
 * For a message content object, the account is told to send the message; any imbedded file transfers will also be sent.
 * For a file transfer content object, YES is always returned, as this is actually just for display purposes.
 */
- (BOOL)processAndSendContentObject:(AIContentObject *)inContentObject
{
	AIAccount	*sendingAccount = (AIAccount *)[inContentObject source];
	BOOL		success = YES;

	if ([inContentObject isKindOfClass:[AIContentTyping class]]) {
		/* Typing */
		[sendingAccount sendTypingObject:(AIContentTyping *)inContentObject];
	
	} else if ([inContentObject isKindOfClass:[AIContentMessage class]]) {
		/* Sending a message */
		AIContentMessage *contentMessage = (AIContentMessage *)inContentObject;
		NSString		 *encodedOutgoingMessage;

		//Before we send the message on to the account, we need to look for embedded files which should be sent as file transfers
		[self handleFileSendsForContentMessage:contentMessage];
		
		/* Let the account encode it as appropriate for sending. Note that we succeeded in sending if we have no length
		 * as that means that somewhere we meant to stop the send -- a file send, an encryption message, etc.
		 */
		if ([[contentMessage message] length]) {
			encodedOutgoingMessage = [sendingAccount encodedAttributedStringForSendingContentMessage:contentMessage];
			
			if (encodedOutgoingMessage && [encodedOutgoingMessage length]) {			
				[contentMessage setEncodedMessage:encodedOutgoingMessage];
				[adiumEncryptor willSendContentMessage:contentMessage];
				
				if (!contentMessage.sendContent)
					success = YES;
				else if ([contentMessage encodedMessage])
					success = [sendingAccount sendMessageObject:contentMessage];
			} else {
				//If the account returns nil when encoding the attributed string, we shouldn't display it on-screen.
				[contentMessage setDisplayContent:NO];
			}
		}

	} else if ([inContentObject isKindOfClass:[ESFileTransfer class]]) {
		success = YES;

	} else if ([inContentObject isKindOfClass:[AIContentNotification class]]) {
		success = [sendingAccount sendNotificationObject:(AIContentNotification *)inContentObject];
		
	} else {
		/* Eating a tasty sandwich */
		success = NO;
	}

	if (!success) AILog(@"Failed to send %@ (sendingAccount %@)",inContentObject,sendingAccount);

	return success;
}

/*!
 * @brief Send a message as-specified without going through any filters or notifications
 */
- (void)sendRawMessage:(NSString *)inString toContact:(AIListContact *)inContact
{
	AIAccount		 *account = inContact.account;
	AIChat			 *chat;
	AIContentMessage *contentMessage;

	if (!(chat = [adium.chatController existingChatWithContact:inContact])) {
		chat = [adium.chatController chatWithContact:inContact];
	}

	contentMessage = [AIContentMessage messageInChat:chat
										  withSource:account
										 destination:inContact
												date:nil
											 message:nil
										   autoreply:NO];
	[contentMessage setEncodedMessage:inString];

	[account sendMessageObject:contentMessage];
}

/*!
 * @brief Given an incoming message, decrypt it.  It is likely not yet ready for display when returned, as it may still include HTML.
 */
- (NSString *)decryptedIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	return [adiumEncryptor decryptIncomingMessage:inString fromContact:inListContact onAccount:inAccount];
}

/*!
 * @brief Given an incoming message, decrypt it if necessary then convert it to an NSAttributedString, processing HTML if possible
 */
- (NSAttributedString *)decodedIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	return [AIHTMLDecoder decodeHTML:[self decryptedIncomingMessage:inString
														fromContact:inListContact
														  onAccount:inAccount]];
}

#pragma mark OTR
- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat
{
	[adiumEncryptor requestSecureOTRMessaging:inSecureMessaging inChat:inChat];
}

- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	[adiumEncryptor promptToVerifyEncryptionIdentityInChat:inChat];
}

- (void)questionVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	[adiumEncryptor questionVerifyEncryptionIdentityInChat:inChat];
}

- (void)sharedVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	[adiumEncryptor sharedVerifyEncryptionIdentityInChat:inChat];
}

#pragma mark -
/*!
 * @brief Is the passed chat currently receiving content?
 *
 * Note: This may be irrelevent if threaded filtering is removed.
 */
- (BOOL)chatIsReceivingContent:(AIChat *)inChat
{
	for (AIContentObject *contentObject in objectsBeingReceived) {
		NSLog(@"Content object: %@, contentObject.chat: %@", contentObject, contentObject.chat);
		if (contentObject.chat == inChat)
			return YES;
	}

	return NO;
}

- (void)displayEvent:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat
{
	AIContentEvent		*content;
	NSAttributedString	*attributedMessage;
	
	//Create our content object
	attributedMessage = [[AIHTMLDecoder decoder] decodeHTML:message withDefaultAttributes:[self defaultFormattingAttributes]];

	content = [AIContentEvent eventInChat:inChat
							   withSource:[inChat listObject]
							  destination:inChat.account
									 date:[NSDate date]
								  message:attributedMessage
								 withType:type];

	//Add the object
	[self receiveContentObject:content];
}

/*! 
 * @brief Generate a menu of encryption preference choices
 */
- (NSMenu *)encryptionMenuNotifyingTarget:(id)target withDefault:(BOOL)withDefault
{
	NSMenu		*encryptionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem	*menuItem;

	[encryptionMenu setTitle:ENCRYPTION_MENU_TITLE];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Disable chat encryption",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Never];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats as requested",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Manually];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats automatically",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Automatically];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Force encryption and refuse plaintext",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_RejectUnencryptedMessages];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	if (withDefault) {
		[encryptionMenu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *defaultMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Default",nil)
														  target:target
														  action:@selector(selectedEncryptionPreference:)
												   keyEquivalent:@""];
		
		[defaultMenuItem setTag:EncryptedChat_Default];
		[encryptionMenu addItem:defaultMenuItem];
		[defaultMenuItem release];
	}
	
	return [encryptionMenu autorelease];
}

@end
