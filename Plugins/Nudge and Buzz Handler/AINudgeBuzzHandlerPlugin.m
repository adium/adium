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

#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>

#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>

#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#import "AINudgeBuzzHandlerPlugin.h"

#define NOTIFICATION				AILocalizedString(@"Request Attention", "Request Attention (nudge or buzz) menu item")
#define TOOLBAR_NOTIFY_IDENTIFIER	@"NotifyParticipants"

@interface AINudgeBuzzHandlerPlugin()
- (BOOL)contactDoesSupportNotification:(AIListObject *)object;
- (IBAction)notifyParticipants:(NSToolbarItem *)senderItem;
- (AIChat *)chatForToolbar:(NSToolbarItem *)senderItem;

// AIListObject interaction
- (void)sendNotification:(AIListObject *)object;
- (IBAction)notifyContact:(id)sender;

// Notifications.
- (void)nudgeBuzzDidOccur:(NSNotification *)notification;

// Event processing.
- (NSString *)shortDescriptionForEventID:(NSString *)eventID;
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject;
- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject;
- (NSImage *)imageForEventID:(NSString *)eventID;
@end

@implementation AINudgeBuzzHandlerPlugin

- (void)installPlugin
{
	// Register our event.
	[adium.contactAlertsController registerEventID:CONTENT_NUDGE_BUZZ_OCCURED
										 withHandler:self
											 inGroup:AIMessageEventHandlerGroup
										  globalOnly:NO];
	
	// Register to observe a nudge or buzz event.
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(nudgeBuzzDidOccur:)
									   name:Chat_NudgeBuzzOccured
									 object:nil];
	
	// Register with AIContentController to recieve the AIContentFilter calls.
	[adium.contentController registerContentFilter:self 
											  ofType:AIFilterContent
										   direction:AIFilterOutgoing];
	
	// Create the menu item.
	notifyMenuItem = [[NSMenuItem alloc] initWithTitle:NOTIFICATION
										  target:self
										  action:@selector(notifyContact:)
								   keyEquivalent:@""];
	
	// Create the contextual menu item.
	notifyContextualMenuItem = [[NSMenuItem alloc] initWithTitle:NOTIFICATION
													target:self
													action:@selector(notifyContact:)
											 keyEquivalent:@""];
	
	// Register our menu items.
	[adium.menuController addMenuItem:notifyMenuItem toLocation:LOC_Contact_Action];
	[adium.menuController addContextualMenuItem:notifyContextualMenuItem toLocation:Context_Contact_Action];
	
	// Load the toolbar icon.
	notifyToolbarIcon = [NSImage imageNamed:@"msg-request-attention" forClass:[self class] loadLazily:YES];
	
	// Create the toolbar item
	NSToolbarItem *chatItem = [AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_NOTIFY_IDENTIFIER
																	  label:NOTIFICATION
															   paletteLabel:NOTIFICATION
																	toolTip:AILocalizedString(@"Send a notification to a contact", nil)
																	 target:self
															settingSelector:@selector(setImage:)
																itemContent:notifyToolbarIcon
																	 action:@selector(notifyParticipants:)
																	   menu:nil];
	
	// Register the toolbar into message windows
	[adium.toolbarController registerToolbarItem:chatItem forToolbarType:@"MessageWindow"];
}

- (void)uninstallPlugin
{
	// Unregister ourself.
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Toolbar Handling
- (IBAction)notifyParticipants:(NSToolbarItem *)senderItem
{
	AIChat *chat = [self chatForToolbar:senderItem];
	
	// Don't handle group chats.
	if (!chat || chat.isGroupChat) {
		return;
	}
	
	// Send a notification to this contact.
	[self sendNotification:chat.listObject];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)senderItem
{
	// Get the chat for this window.
	AIChat *chat = [self chatForToolbar:senderItem];
	
	// Don't handle group chats.
	if (!chat || chat.isGroupChat) {
		return NO;
	}
	
	// Return if the contact can be notified.
	return [self contactDoesSupportNotification:chat.listObject];
}

- (AIChat *)chatForToolbar:(NSToolbarItem *)senderItem
{
	NSToolbar		*windowToolbar = nil;
	NSToolbar		*senderToolbar = [senderItem toolbar];

	//for each open window
	for (NSWindow *currentWindow in [NSApp windows]) {
		//if it has a toolbar & it's ours
		if ((windowToolbar = [currentWindow toolbar]) && (windowToolbar == senderToolbar)) {
			return [adium.interfaceController activeChatInWindow:currentWindow];
		}
	}
	
	return nil;
}

#pragma mark Menu Item Handling
- (IBAction)notifyContact:(id)sender
{
	AIListObject *object;
	
	if (sender == notifyMenuItem) {
		object = adium.interfaceController.selectedListObject;
	} else {
		object = adium.menuController.currentContextMenuObject;
	}
	
	[self sendNotification:object];
	
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *object;
	
	if (menuItem == notifyMenuItem) {
		object = adium.interfaceController.selectedListObject;
	} else {
		object = adium.menuController.currentContextMenuObject;
	}
	
	return [self contactDoesSupportNotification:object];
}

#pragma mark Validation Checking
- (BOOL)contactDoesSupportNotification:(AIListObject *)object
{
	// Don't handle groups.
	if (![object isKindOfClass:[AIListContact class]]) {
		return NO;
	}
	
	if ([object isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *contact in [(AIMetaContact *)object uniqueContainedObjects]) {
			if (contact.account.supportsSendingNotifications) {
				return YES;
			}
		}
		
		return NO;
	} else {
		return ((AIListContact *)object).account.supportsSendingNotifications;
	}
}

#pragma mark Nudge/Buzz Handling

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	if ([context isKindOfClass:[AIContentMessage class]])
	{
		if ([[context destination] isKindOfClass:[AIListObject class]])
		{
			if ([[inAttributedString string] rangeOfString:@"/nudge"].location == 0)
			{
				[self sendNotification:[context destination]];
				return nil;
			}
		}
	}
		
	return inAttributedString;
}

- (CGFloat) filterPriority
{
		return DEFAULT_FILTER_PRIORITY;
}

- (void)sendNotification:(AIListObject *)object
{
	// If object is a Normal contact, this is right. Otherwise, the correct selection will be made later in the code.
	AIListContact		*sendChoice = (AIListContact *)object;
	AIChat				*chat;
	
	// Don't handle groups.
	if (![object isKindOfClass:[AIListContact class]]) {
		return;
	}
	
	// Find the correct choice to send for a meta contact.
	if ([object isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *contact in [(AIMetaContact *)object uniqueContainedObjects]) {
		// Loop until the first contact supporting notifications
			if ([self contactDoesSupportNotification:contact]) {
				sendChoice = contact;
				break;
			}
		}
		
	}
	
	// Pick the chat, or open a new one, with the contact.
	if (!(chat = [adium.chatController existingChatWithContact:sendChoice])) {
		chat = [adium.chatController chatWithContact:sendChoice];
	}

	AIContentNotification *contentNotification = [AIContentNotification notificationInChat:chat
																				withSource:chat.account
																			   destination:chat.listObject
																					  date:[NSDate date]
																		  notificationType:AIDefaultNotificationType];
	
	// Print the text to the window.
	[adium.contentController sendContentObject:contentNotification];
}

// Echoes the buzz event to the window and generates the event.
- (void)nudgeBuzzDidOccur:(NSNotification *)notification
{
	AIChat			*chat = [notification object];

	AIContentNotification *contentNotification = [AIContentNotification notificationInChat:chat
																				withSource:chat.listObject
																			   destination:chat.account
																					  date:[NSDate date]
																		  notificationType:AIDefaultNotificationType];

	// Print the text to the window.
	[adium.contentController receiveContentObject:contentNotification];
	
	// Fire off the event
	[adium.contactAlertsController generateEvent:CONTENT_NUDGE_BUZZ_OCCURED
									 forListObject:chat.listObject
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	
	// Flash content if this isn't the active chat.
	if (adium.interfaceController.activeChat != chat) {
		[chat incrementUnviewedContentCount];
	}
}


#pragma mark Event descriptions
- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if (listObject) {
		NSString	*name;
		NSString	*format = AILocalizedString(@"When %@ sends a notification", nil);
		
		name = ([listObject isKindOfClass:[AIListGroup class]] ?
				[NSString stringWithFormat:AILocalizedString(@"a member of %@", nil),listObject.displayName] :
				listObject.displayName);
			
		description = [NSString stringWithFormat:format, name];
	} else {
		description = AILocalizedString(@"When a contact sends a notification", nil);
	}
	
	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	
	if (includeSubject) {		
		description = [NSString stringWithFormat:
			AILocalizedString(@"%@ wants your attention!", "Message displayed when a contact sends a buzz/nudge/other notification"),
			listObject.displayName];
	} else {
		description = AILocalizedString(@"wants your attention!", "Phrase displayed when a contact sends a buzz/nudge/other notification. The contact's name will be shown above this phrase, as in a Growl notification.");
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	//Use the message icon from the main bundle
	if (!eventImage) eventImage = [NSImage imageNamed:@"events-message"];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	return [NSString stringWithFormat:AILocalizedString(@"%u attention requests", nil), count];
}

@end
