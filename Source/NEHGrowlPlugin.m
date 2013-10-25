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

#import "NEHGrowlPlugin.h"
#import "CBGrowlAlertDetailPane.h"
#import "AIWebKitMessageViewPlugin.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <Growl/Growl.h>

//#define GROWL_DEBUG 1

#define GROWL_ALERT							AILocalizedString(@"Display a notification",nil)
#define GROWL_STICKY_ALERT					AILocalizedString(@"Display a notification until dismissed",nil)
#define GROWL_STICKY_TIME_STAMP_ALERT       AILocalizedString(@"Display a notification with a time stamp until dismissed", nil)
#define GROWL_TIME_STAMP_ALERT              AILocalizedString(@"Display a notification with a time stamp", nil)

#define GROWL_TEXT_SIZE 11

#define GROWL_EVENT_ALERT_IDENTIFIER		@"Growl"

#define KEY_FILE_TRANSFER_ID	@"fileTransferUniqueID"
#define KEY_CHAT_ID				@"uniqueChatID"
#define KEY_LIST_OBJECT_ID		@"internalObjectID"

@interface NEHGrowlPlugin ()
- (NSString *)eventQueueKeyForEventID:(NSString *)eventID
							   inChat:(AIChat *)chat;

- (void)postSingleEventID:(NSString *)eventID
			forListObject:(AIListObject *)listObject
			  withDetails:(NSDictionary *)details
				 userInfo:(id)userInfo;

- (void)postMultipleEventID:(NSString *)eventID
					 sticky:(BOOL)sticky
				   priority:(signed int)priority
			  forListObject:(AIListObject *)listObject
					forChat:(AIChat *)chat
				  withCount:(NSUInteger)count;

- (void)adiumFinishedLaunching:(NSNotification *)notification;
- (void)beginGrowling;
- (void)clearQueue:(NSDictionary *)callDict;
@end
 
/*!
 * @class NEHGrowlPlugin
 * @brief Implements Growl functionality in Adium
 *
 * This class manages the Growl event type, and controls the display of Growl notifications that Adium generates.
 */
@implementation NEHGrowlPlugin

/*!
 * @brief Initialize the Growl plugin
 *
 * Waits for Adium to finish launching before we perform further actions so all events are registered.
 */
- (void)installPlugin
{
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
	
	queuedEvents = [[NSMutableDictionary alloc] init];
}

- (void)dealloc
{
	[queuedEvents release]; queuedEvents = nil;
	
	[super dealloc];
}

/*!
 * @brief Adium finished launching
 *
 * Delays one more run loop so any events which are registered on this notification are guaranteed to be complete
 * regardless of the order in which the observers are called.
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	[self performSelector:@selector(beginGrowling)
			   withObject:nil
			   afterDelay:0];

	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:AIApplicationDidFinishLoadingNotification
										object:nil];
}

/*!
 * @brief Begin accepting Growl events
 */
- (void)beginGrowling
{
	[GrowlApplicationBridge setGrowlDelegate:self];

	//Install our contact alert
	[adium.contactAlertsController registerActionID:GROWL_EVENT_ALERT_IDENTIFIER withHandler:self];
	
#ifdef GROWL_DEBUG
	[GrowlApplicationBridge notifyWithTitle:@"We have found a witch."
								description:@"May we burn her?"
						   notificationName:CONTENT_MESSAGE_RECEIVED
								   iconData:nil
								   priority:0
								   isSticky:YES
							   clickContext:[NSDictionary dictionaryWithObjectsAndKeys:
								   @"AIM.tekjew", @"internalObjectID",
								   CONTENT_MESSAGE_RECEIVED, @"eventID",
								   nil]];
#endif
}

#pragma mark AIActionHandler
/*!
 * @brief Returns a short description of Growl events
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return GROWL_ALERT;
}

/*!
 * @brief Returns a long description of Growl events
 *
 * The long description reflects the "sticky"-ness of the notification.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
    if (([[details objectForKey:KEY_GROWL_ALERT_TIME_STAMP] boolValue]) && ([[details objectForKey:KEY_GROWL_ALERT_STICKY] boolValue])) {
		return GROWL_STICKY_TIME_STAMP_ALERT;
	} else if ([[details objectForKey:KEY_GROWL_ALERT_STICKY] boolValue]) {
		return GROWL_STICKY_ALERT;
	} else if ([[details objectForKey:KEY_GROWL_ALERT_TIME_STAMP] boolValue]) {
		return GROWL_TIME_STAMP_ALERT;
    } else {
		return GROWL_ALERT;
	}
}

/*!
 * @brief Returns the image associated with the Growl event
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-notification" forClass:[self class]];
}

/*!
 * @brief Post a notification for Growl for display
 *
 * This method is called when by Adium when a Growl alert is activated. It passes this information on to Growl, which displays a notificaion.
 *
 * @param actionID The Action ID being performed, in this case the Growl plugin's Action ID.
 * @param listObject The list object the event is related to
 * @param details A dictionary containing additional information about the event
 * @param eventID The ID of the event (e.g. new message, contact went away, etc)
 * @param userInfo Any additional information
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	// Don't show growl notifications if we're silencing growl.
	if ([adium.statusController.activeStatusState silencesGrowl]) {
		return NO;
	}
	
	// Get the chat if it's appropriate.
	AIChat *chat = nil;
	
	if ([userInfo respondsToSelector:@selector(objectForKey:)]) {
		chat = [userInfo objectForKey:@"AIChat"];
		AIContentObject *contentObject = [userInfo objectForKey:@"AIContentObject"];
		if (contentObject.source) {
			listObject = contentObject.source;
		}
	}
	
	// Add this event to the queue.
	NSString *queueKey = [self eventQueueKeyForEventID:eventID inChat:chat];
	
	NSMutableArray *events = [queuedEvents objectForKey:queueKey];
	
	if (!events)
		events = [NSMutableArray array];
	
	NSMutableDictionary *eventDetails = [NSMutableDictionary dictionary];
	
	if (listObject)
		[eventDetails setValue:listObject forKey:@"AIListObject"];
	
	if (userInfo)
		[eventDetails setValue:userInfo forKey:@"UserInfo"];
	
	if (details)
		[eventDetails setValue:details forKey:@"Details"];
	
	[events addObject:eventDetails];
	
	[queuedEvents setValue:events forKey:queueKey];
	
	// wtb cancelPreviousPerformRequestsWithTarget:selector:object:object:
	// chat may be nil
	NSDictionary *queueCall = [NSDictionary dictionaryWithObjectsAndKeys:eventID, @"EventID", chat, @"AIChat", nil];
	
	// Trigger the queue to be cleared in GROWL_QUEUE_WAIT seconds.
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(clearQueue:)
											   object:queueCall];
	
	[self performSelector:@selector(clearQueue:)
			   withObject:queueCall
			   afterDelay:GROWL_QUEUE_WAIT];
	
	// If the queue has <GROWL_QUEUE_POST_COUNT entries already, post this one immediately.
	if (events.count < GROWL_QUEUE_POST_COUNT) {
		[self postSingleEventID:eventID
				  forListObject:listObject
					withDetails:details
					   userInfo:userInfo];
	}

	return YES;
}

/*!
 * @brief Returns our details pane, an instance of <tt>CBGrowlAlertDetailPane</tt>
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
    return [CBGrowlAlertDetailPane actionDetailsPane];
}

/*!
 * @brief Allow multiple actions?
 *
 * This action should not be performed multiple times for the same triggering event.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

#pragma mark Event Queue
- (NSString *)eventQueueKeyForEventID:(NSString *)eventID
							   inChat:(AIChat *)chat
{
	if (chat) {
		return [NSString stringWithFormat:@"%@-%@", eventID, chat.internalObjectID];
	} else {
		return eventID;
	}
}

- (void)clearQueue:(NSDictionary *)callDict
{
	// Grab our actual arguments.
	NSString *eventID = [callDict objectForKey:@"EventID"];
	AIChat *chat = [callDict objectForKey:@"AIChat"];
	
	// Look for events.
	NSString *queueKey = [self eventQueueKeyForEventID:eventID inChat:chat];
	NSMutableArray *events = [queuedEvents objectForKey:queueKey];
	
	// If for some reason we don't have any events, bail.
	if (!events.count) {
		AILogWithSignature(@"Called to clear queue with no events. EventID: %@ chat: %@", eventID, chat);
		return;
	}
	
	// Remove the first GROWL_QUEUE_POST_COUNT entries, since we've already posted about them.
	NSRange removeRange = NSMakeRange(0,
									  (events.count > GROWL_QUEUE_POST_COUNT ? GROWL_QUEUE_POST_COUNT : events.count));

	[events removeObjectsInRange:removeRange];
	
	if (events.count == 1) {
		// Seeing "1 message" is just silly!
		
		NSDictionary *event = [events objectAtIndex:0];
		
		[self postSingleEventID:eventID
				  forListObject:[event objectForKey:@"AIListObject"]
					withDetails:[event objectForKey:@"Details"]
					   userInfo:[event objectForKey:@"UserInfo"]];
		
	} else if(events.count) {		
		// We have a bunch of events; let's combine them.
		AIListObject *overallListObject = nil;

		// If all events are from the same listObject, let's use that one in the message.
		NSArray *listObjects = [events valueForKeyPath:@"@distinctUnionOfObjects.AIListObject"];
		
		if (listObjects.count == 1) {
			overallListObject = [listObjects objectAtIndex:0];
		}
		
		AILog(@"Posting multiple event - %@ %@ %@ %d", eventID, overallListObject, chat, events.count);
		
		// Use any random event for sticky.
		NSDictionary *anyEventDetails = [[events objectAtIndex:0] objectForKey:@"Details"];
		
		BOOL sticky = [[anyEventDetails objectForKey:KEY_GROWL_ALERT_STICKY] boolValue];
		unsigned priority = [[anyEventDetails objectForKey:KEY_GROWL_PRIORITY] unsignedIntValue];
		
		// Post the events combined. Use any random event to see if sticky.
		[self postMultipleEventID:eventID
						   sticky:sticky
						 priority:priority
					forListObject:overallListObject
						  forChat:chat
						withCount:events.count];
	}
	
	// Clear our queue; we're done.
	[queuedEvents setValue:nil forKey:queueKey];
}

- (void)postSingleEventID:(NSString *)eventID
			forListObject:(AIListObject *)listObject
			  withDetails:(NSDictionary *)details
				 userInfo:(id)userInfo
{
	NSString			*title, *description;
	AIChat				*chat = nil;
    AIContentObject     *contentObject = nil;
	NSData				*iconData = nil;
	NSMutableDictionary	*clickContext = [NSMutableDictionary dictionary];
	NSString			*identifier = nil;

	//For a message event, listObject should become whoever sent the message
	if ([adium.contactAlertsController isMessageEvent:eventID] &&
		[userInfo respondsToSelector:@selector(objectForKey:)] &&
		[userInfo objectForKey:@"AIContentObject"]) {
        AIListObject	*source = [contentObject source];
		contentObject = [userInfo objectForKey:@"AIContentObject"];
		chat = [userInfo objectForKey:@"AIChat"];
		
		if (source) listObject = source;
	}
	
	[clickContext setObject:eventID
					 forKey:@"eventID"];
	
	if (listObject) {
		if ([listObject isKindOfClass:[AIListContact class]]) {
			//Use the parent
			listObject = [(AIListContact *)listObject parentContact];
			title = [listObject longDisplayName];
		} else {
			title = listObject.displayName;
		}
		
		iconData = [listObject userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:listObject
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
		}
		
		if (chat) {
			[clickContext setObject:chat.uniqueChatID
							 forKey:KEY_CHAT_ID];
			
		if (chat && [chat isGroupChat]) {
			title = [NSString stringWithFormat:@"%@ (%@)", title, [chat displayName]];
		}
			
		} else {
			if ([userInfo isKindOfClass:[ESFileTransfer class]] &&
				[eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
				[clickContext setObject:[(ESFileTransfer *)userInfo uniqueID]
								 forKey:KEY_FILE_TRANSFER_ID];
				
			} else {
				[clickContext setObject:listObject.internalObjectID
								 forKey:KEY_LIST_OBJECT_ID];
			}
		}
		
	} else {
		if (chat) {
			title = chat.displayName;
			
			[clickContext setObject:chat.uniqueChatID
							 forKey:KEY_CHAT_ID];
			
			//If we have no listObject or we have a name, we are a group chat and
			//should use the account's service icon
			iconData = [[AIServiceIcons serviceIconForObject:chat.account
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
			
		} else {
			title = @"Adium";
		}
	}
    
	description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
                                                                             listObject:listObject
                                                                               userInfo:userInfo
                                                                         includeSubject:NO];
    
	// Append event time stamp if preference is set
	if ([[details objectForKey:KEY_GROWL_ALERT_TIME_STAMP] boolValue]) {
        NSDateFormatter *timeStampFormatter = [[NSDateFormatter alloc] init];
        [timeStampFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
		
        // Set the format to the user's system defined short style
		[timeStampFormatter setTimeStyle:NSDateFormatterShortStyle];

        // For a message event use the contentObject's date otherwise use the current date
		NSDate *dateStamp = (contentObject) ? [contentObject date] : [NSDate date];
		
        description = [NSString stringWithFormat:AILocalizedString(@"[%@] %@", "A Growl notification with a timestamp. The first %@ is the timestamp, the second is the main string"), [timeStampFormatter stringFromDate:dateStamp], description];
		
        [timeStampFormatter release];
	}
    
	
	if (([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES] ||
		 [eventID isEqualToString:CONTACT_STATUS_ONLINE_NO] ||
		 [eventID isEqualToString:CONTACT_STATUS_AWAY_YES] ||
		 [eventID isEqualToString:CONTACT_SEEN_ONLINE_YES] ||
		 [eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) && 
		[(AIListContact *)listObject contactListStatusMessage]) {
		NSString *statusMessage = [[adium.contentController filterAttributedString:[(AIListContact *)listObject contactListStatusMessage]
									usingFilterType:AIFilterContactList
									direction:AIFilterIncoming
									context:listObject] string];
		statusMessage = [[[statusMessage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy] autorelease];
		
		/* If the message contains line breaks, start it on a new line */
		description = [NSString stringWithFormat:@"%@:%@%@",
					   description,
					   (([statusMessage rangeOfLineBreakCharacter].location != NSNotFound) ? @"\n" : @" "),
					   statusMessage];
	}
	
	if (listObject && [adium.contactAlertsController isContactStatusEvent:eventID]) {
		identifier = listObject.internalObjectID;
	}
	
	NSAssert5((title || description),
			  @"Growl notify error: EventID %@, listObject %@, userInfo %@\nGave Title \"%@\" description \"%@\"",
			  eventID,
			  listObject,
			  userInfo,
			  title,
			  description);
	
	AILog(@"Posting Growl notification: Event ID: %@, listObject: %@, chat: %@, description: %@",
		  eventID, listObject, chat, description);
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:eventID
								   iconData:iconData
								   priority:[[details objectForKey:KEY_GROWL_PRIORITY] intValue]
								   isSticky:[[details objectForKey:KEY_GROWL_ALERT_STICKY] boolValue]
							   clickContext:clickContext
								 identifier:identifier];
}

- (void)postMultipleEventID:(NSString *)eventID
					 sticky:(BOOL)sticky
				   priority:(signed int)priority
			  forListObject:(AIListObject *)listObject
					forChat:(AIChat *)chat
				  withCount:(NSUInteger)count
{
	NSString			*title, *description;
	NSData				*iconData = nil;
	NSMutableDictionary	*clickContext = [NSMutableDictionary dictionary];
	NSString			*identifier = nil;
	
	[clickContext setObject:eventID
					 forKey:@"eventID"];
	
	if (listObject) {
		if ([listObject isKindOfClass:[AIListContact class]]) {
			//Use the parent
			listObject = [(AIListContact *)listObject parentContact];
			title = [listObject longDisplayName];
		} else {
			title = listObject.displayName;
		}
		
		iconData = [listObject userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:listObject
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
		}
		
		if (chat) {
			[clickContext setObject:chat.uniqueChatID
							 forKey:KEY_CHAT_ID];
			
		} else {
			[clickContext setObject:listObject.internalObjectID
							 forKey:KEY_LIST_OBJECT_ID];
		}
		
	} else {
		if (chat) {
			title = chat.displayName;
			
			[clickContext setObject:chat.uniqueChatID
							 forKey:KEY_CHAT_ID];
			
			//If we have no listObject or we have a name, we are a group chat and
			//should use the account's service icon
			iconData = [[AIServiceIcons serviceIconForObject:chat.account
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
			
		} else {
			title = @"Adium";
		}
	}
	
	description = [adium.contactAlertsController descriptionForCombinedEventID:eventID
				   forListObject:listObject
				   forChat:chat
				   withCount:count];
	
	if (listObject && [adium.contactAlertsController isContactStatusEvent:eventID]) {
		identifier = listObject.internalObjectID;
	}
	
	NSAssert5((title || description),
			  @"Growl notify error: EventID %@, listObject %@, chat %@\nGave Title \"%@\" description \"%@\"",
			  eventID,
			  listObject,
			  chat,
			  title,
			  description);
	
	AILog(@"Posting combined Growl notification: Event ID: %@, listObject: %@, chat: %@, description: %@",
		  eventID, listObject, chat, description);
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:eventID
								   iconData:iconData
								   priority:priority
								   isSticky:sticky
							   clickContext:clickContext
								 identifier:identifier];
}

#pragma mark Growl

/*!
 * @brief Returns the application name Growl will use
 */
- (NSString *)applicationNameForGrowl
{
	return @"Adium";
}

/*!
 * @brief Registration information for Growl
 *
 * Returns information that Growl needs, like which notifications we will post and our application name.
 */
- (NSDictionary *)registrationDictionaryForGrowl
{
	id <AIContactAlertsController> contactAlertsController = adium.contactAlertsController;
	NSArray						*allNotes = [contactAlertsController allEventIDs];
	NSMutableDictionary			*humanReadableNames = [NSMutableDictionary dictionary];
	NSMutableDictionary			*descriptions = [NSMutableDictionary dictionary];
	NSString					*eventID;
	
	for (eventID in allNotes) {
		[humanReadableNames setObject:[contactAlertsController globalShortDescriptionForEventID:eventID]
							   forKey:eventID];
		
		[descriptions setObject:[contactAlertsController longDescriptionForEventID:eventID 
																	 forListObject:nil]
						 forKey:eventID];		
	}

	NSDictionary	*growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		humanReadableNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
		descriptions, GROWL_NOTIFICATIONS_DESCRIPTIONS,
		nil];

	return growlReg;
}

/*!
 * @brief Called when Growl is ready
 *
 * Currently, this is just used for debugging Growl.
 */
- (void)growlIsReady
{
#ifdef GROWL_DEBUG
	AILog(@"Growl is go for launch.");
#endif
}

/*!
 * @brief Called when a Growl notification is clicked
 *
 * When a Growl notificaion is clicked, this method is called, allowing us to take action (e.g. open a new window, make
 * a conversation active, etc).
 *
 * @param clickContext A dictionary that was passed to Growl when we installed the notification.
 */
- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
	NSString		*internalObjectID, *uniqueChatID;
	AIListObject	*listObject;
	AIChat			*chat = nil;
		
	if ((internalObjectID = [clickContext objectForKey:KEY_LIST_OBJECT_ID])) {
		if ((listObject = [adium.contactController existingListObjectWithUniqueID:internalObjectID]) &&
			([listObject isKindOfClass:[AIListContact class]])) {
			
			//First look for an existing chat to avoid changing anything
			if (!(chat = [adium.chatController existingChatWithContact:(AIListContact *)listObject])) {
				//If we don't find one, create one
				chat = [adium.chatController openChatWithContact:(AIListContact *)listObject
												onPreferredAccount:YES];
			}
		}

	} else if ((uniqueChatID = [clickContext objectForKey:KEY_CHAT_ID])) {
		chat = [adium.chatController existingChatWithUniqueChatID:uniqueChatID];
		
		//If we didn't find a chat, it may have closed since the notification was posted.
		//If we have an appropriate existing list object, we can create a new chat.
		if ((!chat) &&
			(listObject = [adium.contactController existingListObjectWithUniqueID:uniqueChatID]) &&
			([listObject isKindOfClass:[AIListContact class]])) {
		
			//If the uniqueChatID led us to an existing contact, create a chat with it
			chat = [adium.chatController openChatWithContact:(AIListContact *)listObject
											onPreferredAccount:YES];
		}	
	}

	NSString *fileTransferID;
	if ((fileTransferID = [clickContext objectForKey:KEY_FILE_TRANSFER_ID])) {
		//If a file transfer notification is clicked, reveal the file
		[[ESFileTransfer existingFileTransferWithID:fileTransferID] reveal];
	}

	if (chat) {
		//Make the chat active
		[adium.interfaceController setActiveChat:chat];
	}

	//Make Adium active (needed if, for example, our notification was clicked with another app active)
	[NSApp activateIgnoringOtherApps:YES];	
}

@end
