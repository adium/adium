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


#import "AIInterfaceController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIAuthorizationRequestsWindowController.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITooltipUtilities.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIWindowControllerAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIService.h>
#import "AIMessageWindowController.h"
#import <Adium/AIContactList.h>
#import "AIListOutlineView.h"
#import "GBQuestionHandlerPlugin.h"

#import "AIMessageViewController.h"

#define ERROR_MESSAGE_WINDOW_TITLE		AILocalizedString(@"Adium : Error","Error message window title")
#define LABEL_ENTRY_SPACING				4.0f
#define DISPLAY_IMAGE_ON_RIGHT			NO

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT				@"Default Font"

#define MESSAGES_WINDOW_MENU_TITLE		AILocalizedString(@"Chats","Title for the messages window menu item")

//#define	LOG_RESPONDER_CHAIN

@interface NSObject (AIInterfaceController_WindowPrefsTarget)
- (void)selectedWindowLevel:(id)sender;
@end

@interface AIInterfaceController ()
- (void)_resetOpenChatsCache;
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item;
- (NSMutableAttributedString *)_tooltipTitleForObject:(AIListObject *)object;
- (NSMutableAttributedString *)_tooltipBodyForObject:(AIListObject *)object;
- (void)_pasteWithPreferredSelector:(SEL)preferredSelector sender:(id)sender;
- (void)updateCloseMenuKeys;

- (void)saveContainers;
- (void)restoreSavedContainers;
- (void)saveContainersOnQuit:(NSNotification *)notification;

- (void)toggleUserlist:(id)sender;
- (void)toggleUserlistSide:(id)sender;
- (void)clearDisplay:(id)sender;
- (IBAction)closeContextualChat:(id)sender;
- (void)openAuthorizationWindow:(id)sender;
- (void)didReceiveContent:(NSNotification *)notification;
- (void)adiumDidFinishLoading:(NSNotification *)inNotification;
- (void)flashTimer:(NSTimer *)inTimer;

//Window Menu
- (void)updateActiveWindowMenuItem;
- (void)buildWindowMenu;

- (AIChat *)mostRecentActiveChat;
@end

/*!
 * @class AIInterfaceController
 * @brief Interface controller
 *
 * Chat window related requests, such as opening and closing chats, are routed through the interface controller
 * to the appropriate component. The interface controller keeps track of the most recently active chat, handles chat
 * cycling (switching between chats), chat sorting, and so on.  The interface controller also handles switching to
 * an appropriate window or chat when the dock icon is clicked for a 'reopen' event.
 *
 * Contact list window requests, such as toggling window visibilty are routed to the contact list controller component.
 *
 * Error messages are routed through the interface controller.
 *
 * Tooltips, such as seen on hover in the contact list are generated and displayed here.  Tooltip display components and
 * plugins register with the interface controller to be queried for contact information when a tooltip is displayed.
 *
 * When displays in Adium flash, such as in the dock or the contact list for unviewed content, the interface controller
 * manages keeping the flashing synchronized.
 *
 * Finally, the interface controller manages many menu items, providing better menu item validation and target routing
 * than the responder chain alone would do.
 */
@implementation AIInterfaceController

- (id)init
{
	if ((self = [super init])) {
		contactListViewArray = [[NSMutableArray alloc] init];
		messageViewArray = [[NSMutableArray alloc] init];
		contactListTooltipEntryArray = [[NSMutableArray alloc] init];
		contactListTooltipSecondaryEntryArray = [[NSMutableArray alloc] init];
		closeMenuConfiguredForChat = NO;
		_cachedOpenChats = nil;
		mostRecentActiveChat = nil;
		activeChat = nil;
		
		tooltipListObject = nil;
		tooltipTitle = nil;
		tooltipBody = nil;
		tooltipImage = nil;
		flashObserverArray = nil;
		flashTimer = nil;
		flashState = 0;
		
		windowMenuArray = nil;
		
		recentlyClosedChats = [[NSMutableArray alloc] init];
		
#ifdef LOG_RESPONDER_CHAIN
		[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reportResponderChain:) userInfo:nil repeats:YES];
#endif
	}
	
	return self;
}

#ifdef LOG_RESPONDER_CHAIN
//Can be called by a timer to periodically log the responder chain
//[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reportResponderChain:) userInfo:nil repeats:YES];
- (void)reportResponderChain:(NSTimer *)inTimer
{
	NSMutableString	*responderChain = [NSMutableString string];
	
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
#warning 64BIT: Check formatting arguments
	[responderChain appendFormat:@"%@ (%i): ",keyWin,[keyWin respondsToSelector:@selector(print:)]];
	
	NSResponder	*responder = [keyWin firstResponder];
	
	//First, walk down the responder chain looking for a responder which can handle the preferred selector
	while (responder) {
#warning 64BIT: Check formatting arguments
		[responderChain appendFormat:@"%@ (%i)",responder,[responder respondsToSelector:@selector(print:)]];
		responder = [responder nextResponder];
		if (responder) [responderChain appendString:@" -> "];
	}

	NSLog(responderChain);
}
#endif

- (void)controllerDidLoad
{
    //Load the interface
    [interfacePlugin openInterface];

	//Open the contact list window
    [self showContactList:nil];
	
	//Userlist show/hide item
	menuItem_toggleUserlist = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Toggle User List", nil)
																							 target:self
																							 action:@selector(toggleUserlist:)
																					  keyEquivalent:@"/"];
	[menuItem_toggleUserlist setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[adium.menuController addMenuItem:menuItem_toggleUserlist toLocation:LOC_Display_General];
	
	menuItem_toggleUserlistSide = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Toggle User List Side", nil)
																				   target:self
																				   action:@selector(toggleUserlistSide:)
																			keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem_toggleUserlistSide toLocation:LOC_Display_General];

	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Toggle User List", nil)
																				target:self
																				action:@selector(toggleUserlist:)
																		 keyEquivalent:@""];
	
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_GroupChat_Action];
	
	// Clear display
	menuItem_clearDisplay = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Clear Display", nil)
																				 target:self
																				 action:@selector(clearDisplay:)
																		  keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem_clearDisplay toLocation:LOC_Display_MessageControl];
																			  
	//Contact list menu item
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Contact List","Name of the window which lists contacts")
																				target:self
																				action:@selector(toggleContactList:)
																		 keyEquivalent:@"/"];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Window_Fixed];
	
	//Contact list menu item for the dock menu
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Contact List","Name of the window which lists contacts")
																	target:self
																	action:@selector(showContactListAndBringToFront:)
															 keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Dock_Status];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Close Chat","Title for the close chat menu item")
																	target:self
																	action:@selector(closeContextualChat:)
															 keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_Tab_Action];
	
	// Authorization requests menu item
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle(@"Authorization Requests",nil, [NSBundle bundleForClass:[AIAuthorizationRequestsWindowController class]], nil)
										  target:self
										  action:@selector(openAuthorizationWindow:)
								   keyEquivalent:@""];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Window_Auxiliary];

    //Observe content so we can open chats as necessary
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveContent:) 
									   name:CONTENT_MESSAGE_RECEIVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveContent:) 
									   name:CONTENT_MESSAGE_RECEIVED_GROUP object:nil];
	
	//Observe Adium finishing loading so we can do things which may require other components or plugins
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumDidFinishLoading:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];
	
	//Observe quits so we can save containers.
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(saveContainersOnQuit:)
									   name:AIAppWillTerminateNotification
									 object:nil];
}

- (void)controllerWillClose
{
    [contactListPlugin closeContactList];
    [interfacePlugin closeInterface];
}

// Dealloc
- (void)dealloc
{
    contactListViewArray = nil;
    messageViewArray = nil;
    interfaceArray = nil;
	
    tooltipListObject = nil;
	tooltipTitle = nil;
	tooltipBody = nil;
	tooltipImage = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	recentlyClosedChats = nil;
	
}

- (void)adiumDidFinishLoading:(NSNotification *)inNotification
{
	//Observe preference changes. This will also restore saved containers if appropriate.
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_INTERFACE];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:AIApplicationDidFinishLoadingNotification
										object:nil];
}

//Registers code to handle the interface
- (void)registerInterfaceController:(id <AIInterfaceComponent>)inController
{
	if (!interfacePlugin) interfacePlugin = inController;
}

//Register code to handle the contact list
- (void)registerContactListController:(id <AIMultiContactListComponent>)inController
{
	if (!contactListPlugin) contactListPlugin = inController;
}

//Preferences changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!object) {
		//Update prefs
		tabbedChatting = [[prefDict objectForKey:KEY_TABBED_CHATTING] boolValue];
		groupChatsByContactGroup = [[prefDict objectForKey:KEY_GROUP_CHATS_BY_GROUP] boolValue];
		saveContainers = [[prefDict objectForKey:KEY_SAVE_CONTAINERS] boolValue];
	
		if (firstTime) {
			if (saveContainers) {
				//Restore saved containers
				[self performSelector:@selector(restoreSavedContainers) withObject:nil afterDelay:0.0];
			} else if ([prefDict objectForKey:KEY_CONTAINERS]) {
				/* We've loaded without wanting to save containers; clear any saved
				 * from a previous session.
				 */
				[adium.preferenceController setPreference:nil
													 forKey:KEY_CONTAINERS
													  group:PREF_GROUP_INTERFACE];
			}
		}
	}
}

//Handle a reopen/dock icon click
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
	if (![self contactListIsVisibleAndMain] && [[interfacePlugin openContainerIDs] count] == 0) {
		//The contact list is not visible, and there are no chat windows. Make the contact list visible.
		[self showContactList:nil];

	} else {
		AIChat	*mostRecentUnviewedChat;

		//If windows are open, try switching to a chat with unviewed content
		if ((mostRecentUnviewedChat = [adium.chatController mostRecentUnviewedChat])) {
			if ([mostRecentActiveChat unviewedContentCount]) {
				//If the most recently active chat has unviewed content, ensure it is in the front
				[self setActiveChat:mostRecentActiveChat];
			} else {
				//Otherwise, switch to the chat which most recently received content
				[self setActiveChat:mostRecentUnviewedChat];
			}

		} else {
			NSWindow *targetWindow = nil;
			BOOL	 unMinimizedWindows = 0;
			
			//If there was no unviewed content, ensure that atleast one of Adium's windows is unminimized
			for (NSWindow *window in [NSApp windows]) {
				//Check stylemask to rule out the system menu's window (Which reports itself as visible like a real window)
				if (([window styleMask] & (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask))) {
					if (!targetWindow) targetWindow = window;
					if (![window isMiniaturized]) unMinimizedWindows++;
				}
			}
			
			//If there are no unminimized windows, unminimize the last one
			if (unMinimizedWindows == 0 && targetWindow) {
				[targetWindow deminiaturize:nil];
			}
		}
	}

	return YES; 
}

//Contact List ---------------------------------------------------------------------------------------------------------
#pragma mark Contact list
/*!
 * @brief Toggles contact list between visible and hiden
 */
- (IBAction)toggleContactList:(id)sender
{
    if ([self contactListIsVisibleAndMain]) {
		[self closeContactList:nil];
    } else {
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		[self showContactList:nil];
    } 
}

/*!
 * @brief Brings contact list to the front
 */
- (IBAction)showContactList:(id)sender
{
	[contactListPlugin showContactListAndBringToFront:YES];
}

/*!
 * @brief Show the contact list window and bring Adium to the front
 */
- (IBAction)showContactListAndBringToFront:(id)sender
{
	[contactListPlugin showContactListAndBringToFront:YES];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

/*!
 * @brief Close the contact list window
 */
- (IBAction)closeContactList:(id)sender
{
	[contactListPlugin closeContactList];
}

/*!
 * @returns YES if contact list is visible and selected, otherwise NO
 */
- (BOOL)contactListIsVisibleAndMain
{
	return [contactListPlugin contactListIsVisibleAndMain];
}

/*!
* @returns YES if contact list is visible, otherwise NO
 */
- (BOOL)contactListIsVisible
{
	return [contactListPlugin contactListIsVisible];
}

//Detachable Contact List ----------------------------------------------------------------------------------------------
#pragma mark Detachable Contact List

/*!
 * @returns Created contact list controller for detached contact list
 */
- (AIListWindowController *)detachContactList:(AIContactList *)aContactList
{
	return [contactListPlugin detachContactList:aContactList];
}


#pragma mark Container Saving
/*!
 * @brief Restores containers saved from a previous session
 */
- (void)restoreSavedContainers
{
	NSData				*savedData = [adium.preferenceController preferenceForKey:KEY_CONTAINERS
																	group:PREF_GROUP_INTERFACE];
	
	// If there's no data, we can't restore anything.
	if (!savedData)
		return;

	[[AIContactObserverManager sharedManager] delayListObjectNotifications];

	for (NSDictionary *dict in [NSKeyedUnarchiver unarchiveObjectWithData:savedData]) {
		AIMessageWindowController *windowController = [self openContainerWithID:[dict objectForKey:@"ID"]
																		   name:[dict objectForKey:@"Name"]];
		AIChat *containerActiveChat = nil;
		
		// Position the container where it was last saved (using -savedFrameFromString: to prevent going offscreen)
		[[windowController window] setFrame:[windowController savedFrameFromString:[dict objectForKey:@"Frame"]] display:YES];
		
		for (NSDictionary *chatDict in [dict objectForKey:@"Content"]) {
			AIChat			*chat = nil;
			AIService		*service = [adium.accountController firstServiceWithServiceID:[chatDict objectForKey:@"serviceID"]];
			AIAccount		*account = [adium.accountController accountWithInternalObjectID:[chatDict objectForKey:@"AccountID"]];
					
			if ([[chatDict objectForKey:@"IsGroupChat"] boolValue]) {
				chat = [adium.chatController chatWithName:[chatDict objectForKey:@"Name"]
												 identifier:nil
												  onAccount:account
										   chatCreationInfo:[chatDict objectForKey:@"ChatCreationInfo"]];
			} else {
				AIListContact		*contact = [adium.contactController contactWithService:service
																					account:account
																						UID:[chatDict objectForKey:@"UID"]];
				
				chat = [adium.chatController chatWithContact:contact];
			}
			
			// Tag the chat as restored.
			[chat setValue:[NSNumber numberWithBool:YES]
			   forProperty:@"Restored Chat"
					notify:NotifyNow];
			
			if ([[chatDict objectForKey:@"ActiveChat"] boolValue]) {
				containerActiveChat = chat;
			}
					
			// Open the chat into the container we've created above.
			[self openChat:chat inContainerWithID:[dict objectForKey:@"ID"] atIndex:-1];
		}
		
		if (containerActiveChat)
			[self setActiveChat:containerActiveChat];
	}
	
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
}

/*!
 * @brief Saves open container information with their content when Adium quits
 */
- (void)saveContainersOnQuit:(NSNotification *)notification
{
	[self saveContainers];
}

/*!
 * @brief Save opened containers and windows
 *
 * @param withContent Save the current buffer of the window to restore at a later point
 */
- (void)saveContainers
{
	if (!saveContainers) {
		// Don't save anything if we're not set to.
		return;
	}

	// Save active containers.
	NSMutableArray		*savedContainers = [NSMutableArray array];
	
	for (NSDictionary *dict in [interfacePlugin openContainersAndChats]) {
		NSMutableArray		*containerContents = [NSMutableArray array];
		
		for (AIChat *chat in [dict objectForKey:@"Content"]) {
			NSMutableDictionary		*newContainerDict = [NSMutableDictionary dictionary];

			[newContainerDict setObject:chat.account.internalObjectID forKey:@"AccountID"];
			
			// Save chat-specific information.
			if (chat.isGroupChat) {
				// -chatCreationDictionary may be nil, so put it last.
				[newContainerDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool:YES], @"IsGroupChat",
															[NSNumber numberWithBool:([dict objectForKey:@"ActiveChat"] == chat)], @"ActiveChat",
															chat.name, @"Name",
															[chat chatCreationDictionary], @"ChatCreationInfo",nil]];
			} else {
				[newContainerDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithBool:([dict objectForKey:@"ActiveChat"] == chat)], @"ActiveChat",
															chat.listObject.UID, @"UID",
															chat.account.service.serviceID, @"serviceID",
															chat.account.internalObjectID, @"AccountID",nil]];
			}
					
			[containerContents addObject:newContainerDict];
		}
		
		// Replace the "Content" key in -openContainersAndChats with our version of the content.
		// Remove the ActiveChat reference
		// We use the same keys otherwise that -openContainersAndChats provides (Name, ID, Frame)
		NSMutableDictionary *saveDict = [dict mutableCopy];

		[saveDict removeObjectForKey:@"ActiveChat"];
		
		[saveDict setObject:containerContents
					 forKey:@"Content"];
		
		[savedContainers addObject:saveDict];
	}
	
	[adium.preferenceController setPreference:[NSKeyedArchiver archivedDataWithRootObject:savedContainers]
										 forKey:KEY_CONTAINERS
										  group:PREF_GROUP_INTERFACE];
}

//Messaging ------------------------------------------------------------------------------------------------------------
//Methods for instructing the interface to provide a representation of chats, and to determine which chat has user focus
#pragma mark Messaging

/*!
 * @brief Opens window for chat
 */
- (void)openChat:(AIChat *)inChat
{
	NSArray		*containerIDs = [interfacePlugin openContainerIDs];
	NSString	*containerID = nil;
	NSString	*containerName = nil;
	
	//Determine the correct container for this chat
	
	if (!tabbedChatting) {
		//We're not using tabs; each chat starts in its own container, based on the destination object or the chat name
		if ([inChat listObject]) {
			containerID = inChat.listObject.internalObjectID;
		} else {
			containerID = inChat.name;
		}
		
	} else if (groupChatsByContactGroup) {
		if (inChat.isGroupChat) {
			containerID = AILocalizedString(@"Group Chats",nil);
			
		} else {
			//XXX multiple containers: this is "correct" but maybe not desirable, as it is non-deterministic
			AIListGroup	*group = inChat.listObject.parentContact.groups.anyObject;
			
			//If the contact is in the contact list root, we don't have a group
			if (group && ![group isKindOfClass:[AIContactList class]]) {
				containerID = group.displayName;
			}
		}
		
		containerName = containerID;
	}
	
	if (!containerID) {
		//Open new chats into the first container (if not available, create a new one)
		if ([containerIDs count] > 0) {
			containerID = [containerIDs objectAtIndex:0];
		} else {
			containerID = nil;
		}
	}

	//Determine the correct placement for this chat within the container
	[interfacePlugin openChat:inChat inContainerWithID:containerID withName:containerName atIndex:-1];
	if (![inChat isOpen]) {
		[inChat setIsOpen:YES];
		
		//Post the notification last, so observers receive a chat whose isOpen flag is yes.
		[[NSNotificationCenter defaultCenter] postNotificationName:Chat_DidOpen object:inChat userInfo:nil];
	}
}

- (id)openChat:(AIChat *)inChat inContainerWithID:(NSString *)containerID atIndex:(NSUInteger)idx
{	
	NSArray		*openContainerIDs = [interfacePlugin openContainerIDs];

	if (!containerID) {
		//Open new chats into the first container (if not available, create a new one)
		if ([openContainerIDs count] > 0) {
			containerID = [openContainerIDs objectAtIndex:0];
		} else {
			containerID = AILocalizedString(@"Chats",nil);
		}
	}

	//Determine the correct placement for this chat within the container
	id tabViewItem = [interfacePlugin openChat:inChat inContainerWithID:containerID withName:nil atIndex:idx];
	if (![inChat isOpen]) {
		[inChat setIsOpen:YES];
		
		//Post the notification last, so observers receive a chat whose isOpen flag is yes.
		[[NSNotificationCenter defaultCenter] postNotificationName:Chat_DidOpen object:inChat userInfo:nil];
	}
	return tabViewItem;
}

/**
 * @brief Opens a container with a specific ID
 *
 * Asks the interfacePlugin to openContainerWithID:
 */
- (AIMessageWindowController *)openContainerWithID:(NSString *)containerID name:(NSString *)containerName
{
	return [interfacePlugin openContainerWithID:containerID name:containerName];
}

/*!
 * @brief Close the interface for a chat
 *
 * Tell the interface plugin to close the chat.
 */
- (void)closeChat:(AIChat *)inChat
{
	if (inChat) {
		if ([adium.chatController closeChat:inChat]) {
			
			NSMutableDictionary *newRecentlyClosedChat = [NSMutableDictionary dictionary];
			
			[newRecentlyClosedChat setObject:inChat.account.internalObjectID forKey:@"AccountID"];
			
			if (inChat.isGroupChat) {
				// -chatCreationDictionary may be nil, so put it last.
				[newRecentlyClosedChat addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																 [NSNumber numberWithBool:YES], @"IsGroupChat",
																 inChat.name, @"Name",
																 [inChat chatCreationDictionary], @"ChatCreationInfo",nil]];
			} else {
				[newRecentlyClosedChat addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																 inChat.listObject.UID, @"UID",
																 inChat.account.service.serviceID, @"serviceID",
																 inChat.account.internalObjectID, @"AccountID",nil]];
			}
			
			[recentlyClosedChats insertObject:newRecentlyClosedChat atIndex:0];
			
			// this sounds like a sensible limit: no-one will remember what chat they had in the closed tab beyond these
			while (recentlyClosedChats.count > 16) {
				[recentlyClosedChats removeLastObject];
			}
			
			[interfacePlugin closeChat:inChat];
		}
	}
}

/*!
 * @brief Consolidate chats into a single container
 */
- (void)consolidateChats
{
	//We work with copies of these arrays, since moving chats may change their contents
	NSArray			*openContainerIDs = [[interfacePlugin openContainerIDs] copy];
	NSEnumerator	*containerEnumerator = [openContainerIDs objectEnumerator];
	NSString		*firstContainerID = [containerEnumerator nextObject];
	NSString		*containerID;
	
	//For all containers but the first, move the chats they contain to the first container
	while ((containerID = [containerEnumerator nextObject])) {
		NSArray			*openChats = [[interfacePlugin openChatsInContainerWithID:containerID] copy];

		//Move all the chats, providing a target index if chat sorting is enabled
		for (AIChat *chat in openChats) {
			[interfacePlugin moveChat:chat
					toContainerWithID:firstContainerID
								index:-1];
		}
	}
	
	[self chatOrderDidChange];
}

- (void)moveChatToNewContainer:(AIChat *)inChat
{
	[interfacePlugin moveChatToNewContainer:inChat];
}

/*!
 * @returns Active chat
 */
- (AIChat *)activeChat
{
	return activeChat;
}

/*!
 * @brief Set the active chat window
 */
- (void)setActiveChat:(AIChat *)inChat
{
	[interfacePlugin setActiveChat:inChat];
}

/*!
 * @returns Last chat to be active, nil if not chat is open
 */
- (AIChat *)mostRecentActiveChat
{
	return mostRecentActiveChat;
}

/*!
 * @brief Sets active chat window based on chat
 */
- (void)setMostRecentActiveChat:(AIChat *)inChat
{
	[self setActiveChat:inChat];
}

/*!
 * @returns Array of open chats (cached, so call as frequently as desired)
 */
- (NSArray *)openChats
{
	if (!_cachedOpenChats) {
		_cachedOpenChats = [interfacePlugin openChats];
	}
	
	return _cachedOpenChats;
}

- (NSArray *)openContainerIDs
{
	return [interfacePlugin openContainerIDs];
}

/*!
 * @param containerID ID for chat window
 *
 * @returns Array of all chats in chat window
 */
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID
{
	return [interfacePlugin openChatsInContainerWithID:containerID];
}

/*!
 * @brief The container ID for a chat
 *
 * @param chat The chat to look up
 * @returns The container ID for the container the chat is in.
 */
- (NSString *)containerIDForChat:(AIChat *)chat
{
	return [interfacePlugin containerIDForChat:chat];
}

/*!
 * @brief Resets the cache of open chats
 */
- (void)_resetOpenChatsCache
{
	_cachedOpenChats = nil;
}

- (IBAction)reopenChat:(id)sender
{
	if (recentlyClosedChats.count == 0) {
		AILogWithSignature(@"Can't open recently closed tab: no recently closed tabs!");
		return;
	}
	
	NSDictionary *chatDict = [recentlyClosedChats objectAtIndex:0];
	[recentlyClosedChats removeObjectAtIndex:0];
	
	AIChat			*chat = nil;
	AIService		*service = [adium.accountController firstServiceWithServiceID:[chatDict objectForKey:@"serviceID"]];
	AIAccount		*account = [adium.accountController accountWithInternalObjectID:[chatDict objectForKey:@"AccountID"]];
	
	if ([[chatDict objectForKey:@"IsGroupChat"] boolValue]) {
		chat = [adium.chatController chatWithName:[chatDict objectForKey:@"Name"]
									   identifier:nil
										onAccount:account
								 chatCreationInfo:[chatDict objectForKey:@"ChatCreationInfo"]];
	} else {
		AIListContact *contact = [adium.contactController contactWithService:service
																	 account:account
																		 UID:[chatDict objectForKey:@"UID"]];
		
		if (contact) chat = [adium.chatController chatWithContact:contact];
	}
	
	if (!chat) {
		NSRunAlertPanel(AILocalizedString(@"Restoring chat failed", nil),
						AILocalizedString(@"Restoring the last closed tab failed. Perhaps the account not exist anymore?", nil),
						AILocalizedString(@"OK", nil),
						nil,
						nil);
		return;
	}
	
	// Tag the chat as restored.
	[chat setValue:[NSNumber numberWithBool:YES]
	   forProperty:@"Restored Chat"
			notify:NotifyNow];
	
	[self openChat:chat inContainerWithID:nil atIndex:-1];
	[self setActiveChat:chat];
}


//Interface plugin callbacks -------------------------------------------------------------------------------------------
//These methods are called by the interface to let us know what's going on.  We're informed of chats opening, closing,
//changing order, etc.
#pragma mark Interface plugin callbacks
/*!
 * @brief A chat window did open: rebuild our window menu to show the new chat
 *
 * This should be called by the interface plugin (e.g. AIDualWindowInterfacePlugin) after a chat opens
 *
 * @param inChat Newly created chat 
 */
- (void)chatDidOpen:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];
	[self saveContainers];
}

/*!
 * @brief A chat has become active: update our chat closing keys and flag this chat as selected in the window menu
 *
 * @param inChat Chat which has become active
 */
- (void)chatDidBecomeActive:(AIChat *)inChat
{
	AIChat	*previouslyActiveChat = activeChat;
	
	activeChat = inChat;
	
	[self updateCloseMenuKeys];
	[self updateActiveWindowMenuItem];
	
	if (inChat && (inChat != mostRecentActiveChat)) {
		mostRecentActiveChat = nil;
		mostRecentActiveChat = inChat;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_BecameActive
											  object:inChat 
											userInfo:(previouslyActiveChat ?
													  [NSDictionary dictionaryWithObject:previouslyActiveChat
																				  forKey:@"PreviouslyActiveChat"] :
													  nil)];
	
	if (inChat) {
		/* Clear the unviewed content on the next event loop so other methods have a chance to react to the chat becoming
		* active. Specifically, this lets the handleReopenWithVisibleWindows: method have a chance to know that this chat
		* had unviewed content.
		*/
		[inChat performSelector:@selector(clearUnviewedContentCount)
					 withObject:nil
					 afterDelay:0];
	}
}

/*!
 * @brief A chat has become visible: send out a notification for components and plugins to take action
 *
 * @param inChat Chat that has become active
 * @param nWindow Containing chat window
 */
- (void)chatDidBecomeVisible:(AIChat *)inChat inWindow:(NSWindow *)inWindow
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIChatDidBecomeVisible"
											  object:inChat
											userInfo:[NSDictionary dictionaryWithObject:inWindow
																				 forKey:@"NSWindow"]];
}

/*!
 * @brief Find the window currently displaying a chat
 *
 * @returns Window for chat otherwise if the chat is not in any window, or is not visible in any window, returns nil
 */
- (NSWindow *)windowForChat:(AIChat *)inChat
{
	return [interfacePlugin windowForChat:inChat];
}

/*!
 * @brief Find the chat active in a window
 *
 * If the window does not have an active chat, nil is returned
 */
- (AIChat *)activeChatInWindow:(NSWindow *)window
{
	return [interfacePlugin activeChatInWindow:window];
}

/*!
 * @brief A chat window did close: rebuild our window menu to remove the chat
 * 
 * @param inChat Chat that closed
 */
- (void)chatDidClose:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[inChat clearUnviewedContentCount];
	[self buildWindowMenu];
	
	if (!adium.isQuitting) {
		// Don't save containers when the chats are closed while quitting
		[self saveContainers];
	}
	
	if (inChat == activeChat) {
		activeChat = nil;
	}
	
	if (inChat == mostRecentActiveChat) {
		mostRecentActiveChat = nil;
	}
}

/*!
 * @brief The order of chats has changed: rebuild our window menu to reflect the new order
 */
- (void)chatOrderDidChange
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];

	if (!adium.isQuitting) {
		// Don't save containers when the chats are closed while quitting
		[self saveContainers];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_OrderDidChange object:nil userInfo:nil];
	
}

#pragma mark Unviewed content

/*!
 * @breif Content was received, increase the unviewed content count of the chat (if it's not currently active)
 */
- (void)didReceiveContent:(NSNotification *)notification
{
	AIChat		*chat = [[notification userInfo] objectForKey:@"AIChat"];
	
	if (chat != activeChat) {
		[chat incrementUnviewedContentCount];
	}
}


//Chat close menus -----------------------------------------------------------------------------------------------------
#pragma mark Chat close menus

/*!
 * @brief Closes currently active window
 */
- (IBAction)closeMenu:(id)sender
{
    [[[NSApplication sharedApplication] keyWindow] performClose:nil];
}

/*!
 * @brief Closes currently active chat (if there is an active chat)
 */
- (IBAction)closeChatMenu:(id)sender
{
	if (activeChat) [self closeChat:activeChat];
}

/*!
 * @brief Closes currently selected chat based on current chat contextual menu
 */
- (IBAction)closeContextualChat:(id)sender
{
	[self closeChat:[adium.menuController currentContextMenuChat]];
}

/*!
 * @brief Loop through open chats and close them
 */
- (IBAction)closeAllChats:(id)sender
{
	for (AIChat *chatToClose in [interfacePlugin.openChats copy]) {
		[self closeChat:chatToClose];
	}
}

/*!
 * @brief Updates the key equivalents on 'close' and 'close chat' (dynamically changed to make cmd-w less destructive)
 */
- (void)updateCloseMenuKeys
{
	if (activeChat && !closeMenuConfiguredForChat) {
        [menuItem_close setKeyEquivalent:@"W"];
        [menuItem_closeChat setKeyEquivalent:@"w"];
		closeMenuConfiguredForChat = YES;
	} else if (!activeChat && closeMenuConfiguredForChat) {
        [menuItem_close setKeyEquivalent:@"w"];
		[menuItem_closeChat removeKeyEquivalent];		
		closeMenuConfiguredForChat = NO;
	}
}


//Window Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Window Menu

/*!
 * @brief Open the authorization requests window.
 */
- (void)openAuthorizationWindow:(id)sender
{
	[[AIAuthorizationRequestsWindowController sharedController] showOnWindow:nil];
}

/*!
 * @brief Make a chat window active
 * 
 * Invoked by a selection in the window menu
 */
- (IBAction)showChatWindow:(id)sender
{
	[self setActiveChat:[sender representedObject]];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

/*!
 * @brief Updates the 'check' icon so it's next to the active window
 */
- (void)updateActiveWindowMenuItem
{
	for (NSMenuItem *item in windowMenuArray) {
		if ([item representedObject]) [item setState:([item representedObject] == activeChat ? NSOnState : NSOffState)];
    }
}

/*!
 * @brief Builds the window menu
 * 
 * This function gets called whenever chats are opened, closed, or re-ordered - so improvements and optimizations here
 * would probably be helpful
 */
- (void)buildWindowMenu
{	
    NSMenuItem				*item;
    NSInteger						windowKey = 1;
	
    //Remove any existing menus
    for (item in windowMenuArray) {
        [adium.menuController removeMenuItem:item];
    }
    windowMenuArray = [[NSMutableArray alloc] init];
	
    //Messages window and any open messasges	
	for (NSDictionary *containerDict in [interfacePlugin openContainersAndChats]) {
		NSString		*containerName = [containerDict objectForKey:@"Name"];
		NSArray			*contentArray = [containerDict objectForKey:@"Content"];
		
		//Add a menu item for the container
		if (contentArray.count > 1) {
			item = [[NSMenuItem alloc] initWithTitle:([containerName length] ? containerName : AILocalizedString(@"Chats", nil))
																		target:nil
																		action:nil
																 keyEquivalent:@""];
			[self _addItemToMainMenuAndDock:item];
		}
		
		//Add items for the chats it contains
		for (AIChat *chat in contentArray) {
			NSString		*windowKeyString;
			
			//Prepare a key equivalent for the controller
			if (windowKey < 10) {
				windowKeyString = [NSString stringWithFormat:@"%ld", (windowKey)];
			} else if (windowKey == 10) {
				windowKeyString = @"0";
			} else {
				windowKeyString = @"";
			}
			
			item = [[NSMenuItem alloc] initWithTitle:chat.displayName
																		target:self
																		action:@selector(showChatWindow:)
																 keyEquivalent:windowKeyString];
			if ([contentArray count] > 1) [item setIndentationLevel:1];
			[item setRepresentedObject:chat];
			[item setImage:chat.chatMenuImage];
			[self _addItemToMainMenuAndDock:item];

			windowKey++;
		}
	}

	[self updateActiveWindowMenuItem];
}

/*!
 * brief Adds a menu item to the internal array, dock menu, and main menu
 *
 * Should be used for adding a new window to the window menu (and dock menu)
 */
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item
{
	//Add to main menu first
	[adium.menuController addMenuItem:item toLocation:LOC_Window_Fixed];
	[windowMenuArray addObject:item];
	
	//Make a copy, and add to the dock
	item = [item copy];
	[item setKeyEquivalent:@""];
	[adium.menuController addMenuItem:item toLocation:LOC_Dock_Status];
	[windowMenuArray addObject:item];
}


//Chat Cycling ---------------------------------------------------------------------------------------------------------
#pragma mark Chat Cycling

/*!
 * @brief Cycles to the next active chat
 */
- (void)nextChat:(id)sender
{
	if (!activeChat) return;
	
	NSString *containerID = [self containerIDForChat:activeChat];
	NSArray *chats = [self openChatsInContainerWithID:containerID];

	NSInteger nextChat = [chats indexOfObject:activeChat] + 1;
	
	if (nextChat >= chats.count)
		nextChat = 0;
	
	[self setActiveChat:[chats objectAtIndex:nextChat]];
}

/*!
 * @brief Cycles to the previus active chat
 */
- (void)previousChat:(id)sender
{
	if (!activeChat) return;
	
	NSString *containerID = [self containerIDForChat:activeChat];
	NSArray *chats = [self openChatsInContainerWithID:containerID];
	
	NSInteger nextChat = [chats indexOfObject:activeChat] - 1;
	
	if (nextChat < 0)
		nextChat = chats.count - 1;
	
	[self setActiveChat:[chats objectAtIndex:nextChat]];
}

//Selected contact ------------------------------------------------
#pragma mark Selected contact
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector
{
    NSResponder	*responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
    //Check the first responder
    if ([responder respondsToSelector:selector]) {
        return [responder performSelector:selector];
    }
	
    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if ([responder respondsToSelector:selector]) {
            return [responder performSelector:selector];
        }
		
    } while (responder != nil);
	
    //None found, return nil
    return nil;
}
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol
{
	NSResponder *responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
	//Check the first responder
	if ([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]) {
		return [responder performSelector:selector];
	}
	
    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if ([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]) {
            return [responder performSelector:selector];
        }
		
    } while (responder != nil);
	
    //None found, return nil
    return nil;
}

/*!
 * @returns The "selected"(represented) contact (By finding the first responder that returns a contact)
 * If no listObject is found, try to find a list object selected in a group chat
 */
- (AIListObject *)selectedListObject
{
	AIListObject *listObject = [self _performSelectorOnFirstAvailableResponder:@selector(listObject)];
	if ( !listObject) {
		listObject = [self _performSelectorOnFirstAvailableResponder:@selector(preferredListObject)];
	}
	return listObject;
}

- (AIListObject *)selectedListObjectInContactList
{
	return [self _performSelectorOnFirstAvailableResponder:@selector(listObject) conformingToProtocol:@protocol(ContactListOutlineView)];
}
- (NSArray *)arrayOfSelectedListObjectsInContactList
{
	return [self _performSelectorOnFirstAvailableResponder:@selector(arrayOfListObjects) conformingToProtocol:@protocol(ContactListOutlineView)];
}
- (NSArray *)arrayOfSelectedListObjectsWithGroupsInContactList
{
	return [self _performSelectorOnFirstAvailableResponder:@selector(arrayOfListObjectsWithGroups) conformingToProtocol:@protocol(ContactListOutlineView)];
}

//Message View ---------------------------------------------------------------------------------------------------------
//Message view is abstracted from the containing interface, since they're not directly related to eachother
#pragma mark Message View
//Registers a view to handle the contact list
- (void)registerMessageDisplayPlugin:(id <AIMessageDisplayPlugin>)inPlugin
{
    [messageViewArray addObject:inPlugin];
}
- (void)unregisterMessageDisplayPlugin:(id <AIMessageDisplayPlugin>)inPlugin
{
    [messageViewArray removeObject:inPlugin];
}
- (id <AIMessageDisplayController>)messageDisplayControllerForChat:(AIChat *)inChat
{
	//Sometimes our users find it amusing to disable plugins that are located within the Adium bundle.  This error
	//trap prevents us from crashing if they happen to disable all the available message view plugins.
	//PUT THAT PLUGIN BACK IT WAS IMPORTANT!
	if ([messageViewArray count] == 0) {
		AILogWithSignature(@"WARNING: Called for %@ without a mesage display controller.", inChat);
		return nil;
	}
	
	return [[messageViewArray objectAtIndex:0] messageDisplayControllerForChat:inChat];
}


//Error Display --------------------------------------------------------------------------------------------------------
#pragma mark Error Display
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    [self handleMessage:inTitle withDescription:inDesc withWindowTitle:ERROR_MESSAGE_WINDOW_TITLE];
}

- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;
{
    NSDictionary	*errorDict;
    
    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",inWindowTitle,@"Window Title",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:Interface_ShouldDisplayErrorMessage object:nil userInfo:errorDict];
}

//Display then clear the last disconnection error
- (void)account:(AIAccount *)inAccount disconnectedWithError:(NSString *)disconnectionError
{

}

//Question Display -----------------------------------------------------------------------------------------------------
#pragma mark Question Display
- (void)displayQuestion:(NSString *)inTitle withAttributedDescription:(NSAttributedString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton suppression:(NSString *)inSuppression
		responseHandler:(void (^)(AITextAndButtonsReturnCode ret, BOOL suppressed, id userInfo))handler;
{
	[self displayQuestion:inTitle
withAttributedDescription:inDesc
		  withWindowTitle:inWindowTitle
			defaultButton:inDefaultButton
		  alternateButton:inAlternateButton
			  otherButton:inOtherButton
			  suppression:inSuppression
				  makeKey:TRUE
		  responseHandler:handler];
}

- (void)displayQuestion:(NSString *)inTitle withAttributedDescription:(NSAttributedString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton suppression:(NSString *)inSuppression
				makeKey:(BOOL)key responseHandler:(void (^)(AITextAndButtonsReturnCode ret, BOOL suppressed, id userInfo))handler
{
	NSMutableDictionary *questionDict = [NSMutableDictionary dictionary];
	
	if(inTitle != nil)
		[questionDict setObject:inTitle forKey:@"Title"];
	if(inDesc != nil)
		[questionDict setObject:inDesc forKey:@"Description"];
	if(inWindowTitle != nil)
		[questionDict setObject:inWindowTitle forKey:@"Window Title"];
	if(inDefaultButton != nil)
		[questionDict setObject:inDefaultButton forKey:@"Default Button"];
	if(inAlternateButton != nil)
		[questionDict setObject:inAlternateButton forKey:@"Alternate Button"];
	if(inOtherButton != nil)
		[questionDict setObject:inOtherButton forKey:@"Other Button"];
	if(inSuppression != nil)
		[questionDict setObject:inSuppression forKey:@"Suppression Checkbox"];
	if (handler) {
		[questionDict setObject:[handler copy] forKey:@"Handler"];
	}
	[questionDict setObject:@(key) forKey:@"Make Key"];
	
	[GBQuestionHandlerPlugin handleQuestion:questionDict];
}

- (void)displayQuestion:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton suppression:(NSString *)inSuppression
		responseHandler:(void (^)(AITextAndButtonsReturnCode ret, BOOL suppressed, id userInfo))handler;
{
	[self displayQuestion:inTitle
withAttributedDescription:[[NSAttributedString alloc] initWithString:inDesc
														   attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0]
																								  forKey:NSFontAttributeName]]
		  withWindowTitle:inWindowTitle
			defaultButton:inDefaultButton
		  alternateButton:inAlternateButton
			  otherButton:inOtherButton
			  suppression:inSuppression
		   responseHandler:handler];
}


- (void)displayQuestion:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle
		  defaultButton:(NSString *)inDefaultButton alternateButton:(NSString *)inAlternateButton otherButton:(NSString *)inOtherButton suppression:(NSString *)inSuppression
				makeKey:(BOOL)key responseHandler:(void (^)(AITextAndButtonsReturnCode ret, BOOL suppressed, id userInfo))handler;
{
	[self displayQuestion:inTitle
withAttributedDescription:[[NSAttributedString alloc] initWithString:inDesc
														  attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0]
																								 forKey:NSFontAttributeName]]
		  withWindowTitle:inWindowTitle
			defaultButton:inDefaultButton
		  alternateButton:inAlternateButton
			  otherButton:inOtherButton
			  suppression:inSuppression
				  makeKey:key
		  responseHandler:handler];
}
//Synchronized Flashing ------------------------------------------------------------------------------------------------
#pragma mark Synchronized Flashing
//Register to observe the synchronized flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Setup the timer if we don't have one yet
    if (!flashObserverArray) {
        flashObserverArray = [[NSMutableArray alloc] init];
        flashTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) 
                                                       target:self 
                                                     selector:@selector(flashTimer:) 
                                                     userInfo:nil
                                                      repeats:YES];
    }
    
    //Add the new observer to the array
    [flashObserverArray addObject:inObserver];
}

//Unregister from observing flashing
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Remove the observer from our array
    [flashObserverArray removeObject:inObserver];
    
    //Release the observer array and uninstall the timer
    if ([flashObserverArray count] == 0) {
        flashObserverArray = nil;
        [flashTimer invalidate];
        flashTimer = nil;
    }
}

//Timer, invoke a flash
- (void)flashTimer:(NSTimer *)inTimer
{
	flashState++;

	for (id<AIFlashObserver>observer in [flashObserverArray copy]) {
		[observer flash:flashState];
	}
}

//Current state of flashing.  This is an integer the increases by 1 with every flash.  Mod to whatever range is desired
- (int)flashState
{
    return flashState;
}


//Tooltips -------------------------------------------------------------------------------------------------------------
#pragma mark Tooltips
//Registers code to display tooltip info about a contact
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray addObject:inEntry];
    else
        [contactListTooltipEntryArray addObject:inEntry];
}

//Unregisters code to display tooltip info about a contact
- (void)unregisterContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray removeObject:inEntry];
    else
        [contactListTooltipEntryArray removeObject:inEntry];
}

- (NSArray *)contactListTooltipPrimaryEntries
{
	return contactListTooltipEntryArray;
}

- (NSArray *)contactListTooltipSecondaryEntries
{
	return contactListTooltipSecondaryEntryArray;
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow 
{
    if (object) {
        if (object == tooltipListObject) { //If we already have this tooltip open
                                         //Move the existing tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
												body:tooltipBody
											   image:tooltipImage 
										imageOnRight:DISPLAY_IMAGE_ON_RIGHT 
											onWindow:inWindow
											 atPoint:point 
										 orientation:TooltipBelow];
            
        } else { //This is a new tooltip
            NSArray                     *tabArray;
            NSMutableParagraphStyle     *paragraphStyleTitle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            NSMutableParagraphStyle     *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            
            //Hold onto the new object
			tooltipListObject = object;
            
            //Buddy Icon
			tooltipImage = [tooltipListObject userIcon];
			if (!tooltipImage) tooltipImage = [AIServiceIcons serviceIconForObject:tooltipListObject
																			 type:AIServiceIconLarge
																		direction:AIIconNormal];
            
            //Reset the maxLabelWidth for the tooltip generation
            maxLabelWidth = 0;
            
            //Build a tooltip string for the primary information
			tooltipTitle = [self _tooltipTitleForObject:object];
            
            //If there is an image, set the title tab and indentation settings independently
            if (tooltipImage) {
                //Set a right-align tab at the maximum label width and a left-align just past it
                tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType 
																					location:maxLabelWidth]
                                                            ,[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                   location:maxLabelWidth + LABEL_ENTRY_SPACING]
                                                            ,nil];
                
                [paragraphStyleTitle setTabStops:tabArray];
                tabArray = nil;
                [paragraphStyleTitle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
                
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName 
                                     value:paragraphStyleTitle
                                     range:NSMakeRange(0,[tooltipTitle length])];
                
                //Reset the max label width since the body will be independent
                maxLabelWidth = 0;
            }
            
            //Build a tooltip string for the secondary information
			tooltipBody = nil;
            tooltipBody = [self _tooltipBodyForObject:object];
            
            //Set a right-align tab at the maximum label width for the body and a left-align just past it
            tabArray = [[NSArray alloc] initWithObjects:[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                 location:maxLabelWidth]
                                                        ,[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                location:maxLabelWidth + LABEL_ENTRY_SPACING]
                                                        ,nil];
            [paragraphStyle setTabStops:tabArray];
            [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
            
            [tooltipBody addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipBody length])];
            //If there is no image, also use these settings for the top part
            if (!tooltipImage) {
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipTitle length])];
            }
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
                                                body:tooltipBody 
                                               image:tooltipImage
                                        imageOnRight:DISPLAY_IMAGE_ON_RIGHT
                                            onWindow:inWindow
                                             atPoint:point 
                                         orientation:TooltipBelow];
			
        }
        
    } else {
        //Hide the existing tooltip
        if (tooltipListObject) {
            [AITooltipUtilities showTooltipWithTitle:nil 
                                                body:nil
                                               image:nil 
                                            onWindow:nil
                                             atPoint:point
                                         orientation:TooltipBelow];
            tooltipListObject = nil;
			
			tooltipTitle = nil;
			tooltipBody = nil;
			tooltipImage = nil;
        }
    }
}

- (NSMutableAttributedString *)_tooltipTitleForObject:(AIListObject *)object
{
    NSMutableAttributedString           *titleString = [[NSMutableAttributedString alloc] init];
    
    id <AIContactListTooltipEntry>		tooltipEntry;
    NSEnumerator                        *labelEnumerator;
    NSMutableArray                      *labelArray = [NSMutableArray array];
    NSMutableArray                      *entryArray = [NSMutableArray array];
    NSMutableAttributedString           *entryString;
    CGFloat                               labelWidth;
    BOOL                                isFirst = YES;
    
    NSString                            *formattedUID = object.formattedUID;
    
    //Configure fonts and attributes
    NSFontManager                       *fontManager = [NSFontManager sharedFontManager];
    NSFont                              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary                 *titleDict = [NSMutableDictionary dictionaryWithObject:[fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask]
	                                                                                    forKey:NSFontAttributeName];
    NSMutableDictionary                 *labelDict = [NSMutableDictionary dictionaryWithObject:[fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask]
	                                                                                    forKey:NSFontAttributeName];
    NSMutableDictionary                 *labelEndLineDict = [NSMutableDictionary dictionaryWithObject:[NSFont toolTipsFontOfSize:2]
	                                                                                           forKey:NSFontAttributeName];
    NSMutableDictionary                 *entryDict = [NSMutableDictionary dictionaryWithObject:toolTipsFont
	                                                                                    forKey:NSFontAttributeName];
	
	//Get the user's display name as an attributed string
    NSAttributedString                  *displayName = [[NSAttributedString alloc] initWithString:object.displayName
																					   attributes:titleDict];
	NSAttributedString					*filteredDisplayName = [adium.contentController filterAttributedString:displayName
																								 usingFilterType:AIFilterTooltips
																									   direction:AIFilterIncoming
																										 context:nil];
	
	//Append the user's display name
	if (filteredDisplayName) {
		[titleString appendAttributedString:filteredDisplayName];
	}
	
	//Append the user's formatted UID if there is one that's different to the display name
	if (formattedUID && (!([[[displayName string] compactedString] isEqualToString:[formattedUID compactedString]]))) {
		[titleString appendString:[NSString stringWithFormat:@" (%@)", formattedUID] withAttributes:titleDict];
	}
    	
    if ([object isKindOfClass:[AIListGroup class]]) {
        [titleString appendString:[NSString stringWithFormat:@" (%ld/%ld)",[(AIListGroup *)object visibleCount],[(AIListGroup *)object countOfContainedObjects]] 
                   withAttributes:titleDict];
    }
    
    //Entries from plugins
    
    //Calculate the widest label while loading the arrays
    
    for (tooltipEntry in contactListTooltipEntryArray) {
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						 attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
    }
    
    //Add labels plus entires to the toolTip
    labelEnumerator = [labelArray objectEnumerator];
    
    for (entryString in entryArray) {        
        NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																				 attributes:labelDict];
        
        //Add a carriage return
        [titleString appendString:@"\n" withAttributes:labelEndLineDict];
        
        if (isFirst) {
            //skip a line
            [titleString appendString:@"\n" withAttributes:labelEndLineDict];
            isFirst = NO;
        }
        
        //Add the label (with its spacing)
        [titleString appendAttributedString:labelAttribString];

		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];
        [titleString appendAttributedString:entryString];
    }

    return titleString;
}

- (NSMutableAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString       *tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    NSFontManager                   *fontManager = [NSFontManager sharedFontManager];
    NSFont                          *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary             *labelDict = [NSMutableDictionary dictionaryWithObject:[fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask]
	                                                                                forKey:NSFontAttributeName];
    NSMutableDictionary             *labelEndLineDict = [NSMutableDictionary dictionaryWithObject:[NSFont toolTipsFontOfSize:1]
	                                                                                       forKey:NSFontAttributeName];
    NSMutableDictionary             *entryDict = [NSMutableDictionary dictionaryWithObject:toolTipsFont
	                                                                                forKey:NSFontAttributeName];
    
    //Entries from plugins
    NSEnumerator                    *labelEnumerator; 
    NSMutableArray                  *labelArray = [NSMutableArray array]; //Array of NSStrings
    NSMutableArray                  *entryArray = [NSMutableArray array]; //Array of NSMutableStrings   
    CGFloat                         labelWidth;
    BOOL                            firstEntry = YES;
    
    //Calculate the widest label while loading the arrays
	for (id <AIContactListTooltipEntry>tooltipEntry in contactListTooltipSecondaryEntryArray) {
		NSMutableAttributedString *entryString = [[tooltipEntry entryForObject:object] mutableCopy];
		if (entryString && entryString.length) {
			NSString        *labelString = [tooltipEntry labelForObject:object];

			if (labelString && labelString.length) {
				[entryArray addObject:entryString];
				[labelArray addObject:labelString];
				
				NSAttributedString *labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						attributes:labelDict];
				
				//The largest size should be the label's size plus the distance to the next tab at least a space past its end
				labelWidth = labelAttribString.size.width;
				
				if (labelWidth > maxLabelWidth)
					maxLabelWidth = labelWidth;
			}
		}
	}
		
    //Add labels plus entires to the toolTip
    labelEnumerator = [labelArray objectEnumerator];
    for (__strong NSMutableAttributedString *entryString in entryArray) {
        NSMutableAttributedString *labelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																						attributes:labelDict];
        
        if (firstEntry) {
            firstEntry = NO;
        } else {
            //Add a carriage return and skip a line
            [tipString appendString:@"\n\n" withAttributes:labelEndLineDict];
        }
        
        //Add the label (with its spacing)
        [tipString appendAttributedString:labelString];

        NSRange fullLength = NSMakeRange(0, [entryString length]);
        
        //remove any background coloration
        [entryString removeAttribute:NSBackgroundColorAttributeName range:fullLength];
        
        //adjust foreground colors for the tooltip background
        [entryString adjustColorsToShowOnBackground:[NSColor colorWithCalibratedRed:1.000f green:1.000f blue:0.800f alpha:1.0f]];

        //headIndent doesn't apply to the first line of a paragraph... so when new lines are in the entry, we need to tab over to the proper location
		if ([entryString replaceOccurrencesOfString:@"\r" withString:@"\r\t\t" options:NSLiteralSearch range:fullLength]) {
            fullLength = NSMakeRange(0, [entryString length]);
		}
		
        [entryString replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:NSLiteralSearch range:fullLength];
		
        //Run the entry through the filters and add it to tipString
		entryString = [[adium.contentController filterAttributedString:entryString
														 usingFilterType:AIFilterTooltips
															   direction:AIFilterIncoming
																 context:object] mutableCopy];
		
		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];
        [tipString appendAttributedString:entryString];
    }

    return tipString;
}

//Custom pasting ----------------------------------------------------------------------------------------------------
#pragma mark Custom Pasting
//Paste, stripping formatting
- (IBAction)paste:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsPlainTextWithTraits:) sender:sender];
}

//Paste with formatting
- (IBAction)pasteAndMatchStyle:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsPlainText:) sender:sender];
}

- (IBAction)pasteWithImagesAndColors:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsRichText:) sender:sender];	
}

/*!
 * @brief Send a paste message, using preferredSelector if possible and paste: if not
 *
 * Walks the responder chain looking for a responder which can handle pasting, skipping instances of
 * WebHTMLView.  These are skipped because we can control what paste does to WebView (by using a custom subclass) but
 * have no control over what the WebHTMLView would do.
 *
 * If no responder is found, repeats the process looking for the simpler paste: selector.
 */
- (void)_pasteWithPreferredSelector:(SEL)selector sender:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSResponder	*responder;

	//First, look for a responder which can handle the preferred selector
	if (!(responder = [keyWin earliestResponderWhichRespondsToSelector:selector
														  andIsNotOfClass:NSClassFromString(@"WebHTMLView")])) {		
		//No responder found.  Try again, looking for one which will respond to paste:
		selector = @selector(paste:);
		responder = [keyWin earliestResponderWhichRespondsToSelector:selector
														andIsNotOfClass:NSClassFromString(@"WebHTMLView")];
	}

	//Sending pasteAsRichText: to a non rich text NSTextView won't do anything; change it to a generic paste:
	if ([responder isKindOfClass:[NSTextView class]] && ![(NSTextView *)responder isRichText]) {
		selector = @selector(paste:);
	}

	if (selector) {
		[keyWin makeFirstResponder:responder];
		[responder performSelector:selector
						withObject:sender];
	}
}

//Custom Printing ------------------------------------------------------------------------------------------------------
#pragma mark Custom Printing
- (IBAction)adiumPrint:(id)sender
{
	//Pass the print command to the window, which is responsible for routing it to the correct place or
	//creating a view and printing.  Adium will not print from a window that does not respond to adiumPrint:
	NSWindow	*keyWindowController = [[[NSApplication sharedApplication] keyWindow] windowController];
	if ([keyWindowController respondsToSelector:@selector(adiumPrint:)]) {
		[keyWindowController performSelector:@selector(adiumPrint:)
								  withObject:sender];
	}
}

#pragma mark Preferences Display
- (IBAction)showPreferenceWindow:(id)sender
{
	[adium.preferenceController showPreferenceWindow:sender];
}

#pragma mark Font Panel
- (IBAction)toggleFontPanel:(id)sender
{
	if ([NSFontPanel sharedFontPanelExists] &&
		[[NSFontPanel sharedFontPanel] isVisible]) {
		[[NSFontPanel sharedFontPanel] close];

	} else {
		NSFontPanel	*fontPanel = [NSFontPanel sharedFontPanel];
		
		if (!fontPanelAccessoryView) {
			[NSBundle loadNibNamed:@"FontPanelAccessoryView" owner:self];
			[fontPanel setAccessoryView:fontPanelAccessoryView];
			
			[button_fontPanelSetAsDefault setLocalizedString:AILocalizedString(@"Save This Setting As My Default Font", "Appears in the Format > Show Fonts window. You are limited for horizontal space, so try to keep it at most the length of the English string.")];
		}
		
		[fontPanel orderFront:self]; 
	}
}

- (IBAction)setFontPanelSettingsAsDefaultFont:(id)sender
{
	NSFont	*selectedFont = [[NSFontManager sharedFontManager] selectedFont];

	[adium.preferenceController setPreference:[selectedFont stringRepresentation]
										 forKey:KEY_FORMATTING_FONT
										  group:PREF_GROUP_FORMATTING];
	
	//We can't get foreground/background color from the font panel so far as I can tell... so we do the best we can.
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [keyWin firstResponder]; 
	if ([responder isKindOfClass:[NSTextView class]]) {
		NSDictionary	*typingAttributes = [(NSTextView *)responder typingAttributes];
		NSColor			*foregroundColor, *backgroundColor;

		if ((foregroundColor = [typingAttributes objectForKey:NSForegroundColorAttributeName])) {
			[adium.preferenceController setPreference:[foregroundColor stringRepresentation]
												 forKey:KEY_FORMATTING_TEXT_COLOR
												  group:PREF_GROUP_FORMATTING];
		}

		if ((backgroundColor = [typingAttributes objectForKey:AIBodyColorAttributeName])) {
			[adium.preferenceController setPreference:[backgroundColor stringRepresentation]
												 forKey:KEY_FORMATTING_BACKGROUND_COLOR
												  group:PREF_GROUP_FORMATTING];
		}
	}
}

//Custom Dimming menu items --------------------------------------------------------------------------------------------
#pragma mark Custom Dimming menu items
//The standard ones do not dim correctly when unavailable
- (IBAction)toggleFontTrait:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    
    if ([fontManager traitsOfFont:[fontManager selectedFont]] & [sender tag]) {
        [fontManager removeFontTrait:sender];
    } else {
        [fontManager addFontTrait:sender];
    }
}

- (void)toggleToolbarShown:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window toggleToolbarShown:sender];
}

- (void)runToolbarCustomizationPalette:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window runToolbarCustomizationPalette:sender];
}

//Menu item validation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [keyWin firstResponder]; 
	
    if (menuItem == menuItem_bold || menuItem == menuItem_italic) {
		NSFont			*selectedFont = [[NSFontManager sharedFontManager] selectedFont];
		
		//We must be in a text view, have text on the pasteboard, and have a font that supports bold or italic
		if ([responder isKindOfClass:[NSTextView class]]) {
			return (menuItem == menuItem_bold ? [selectedFont supportsBold] : [selectedFont supportsItalics]);
		}
		return NO;
		
	} else if (menuItem == menuItem_paste || menuItem == menuItem_pasteAndMatchStyle || menuItem == menuItem_pasteWithImagesAndColors) {

		//The user can paste if the pasteboard contains an image, some text, one or more files, or one or more URLs.
		NSPasteboard *pboard = [NSPasteboard generalPasteboard];
		NSArray *nonImageTypes = [NSArray arrayWithObjects:
			NSStringPboardType,
			NSRTFPboardType,
			NSURLPboardType,
			NSFilenamesPboardType,
			NSFilesPromisePboardType,
			NSRTFDPboardType,
			nil];
		return ([pboard availableTypeFromArray:nonImageTypes] != nil) || [NSImage canInitWithPasteboard:pboard];
	
	} else if (menuItem == menuItem_showToolbar) {
		[menuItem_showToolbar setTitle:([[keyWin toolbar] isVisible] ? 
										AILocalizedString(@"Hide Toolbar",nil) : 
										AILocalizedString(@"Show Toolbar",nil))];
		return [keyWin toolbar] != nil;
	
	} else if (menuItem == menuItem_customizeToolbar) {
		return ([keyWin toolbar] != nil && [[keyWin toolbar] isVisible] && [[keyWin windowController] canCustomizeToolbar]);

	} else if (menuItem == menuItem_close) {
		return (keyWin && ([[keyWin standardWindowButton:NSWindowCloseButton] isEnabled] ||
							  ([[keyWin windowController] respondsToSelector:@selector(windowPermitsClose)] &&
							   [[keyWin windowController] windowPermitsClose])));
		
	} else if (menuItem == menuItem_closeChat || menuItem == menuItem_clearDisplay) {
		return activeChat != nil;
		
	} else if( menuItem == menuItem_closeAllChats) {
		return [[self openChats] count] > 0;

	} else if (menuItem == menuItem_print) {
		NSWindowController *windowController = [keyWin windowController];

		return ([windowController respondsToSelector:@selector(adiumPrint:)] &&
				(![windowController respondsToSelector:@selector(validatePrintMenuItem:)] ||
				 [windowController validatePrintMenuItem:menuItem]));
		
	} else if (menuItem == menuItem_showFonts) {
		[menuItem_showFonts setTitle:(([NSFontPanel sharedFontPanelExists] && [[NSFontPanel sharedFontPanel] isVisible]) ?
									  AILocalizedString(@"Hide Fonts",nil) :
									  AILocalizedString(@"Show Fonts",nil))];
		return YES;
	} else if (menuItem == menuItem_toggleUserlist || menuItem == menuItem_toggleUserlistSide) {
		return self.activeChat.isGroupChat;
	} else if (menuItem == menuItem_reopenTab) {
		return recentlyClosedChats.count > 0;
	} else {
		return YES;
	}
}

#pragma mark Window levels
- (NSMenu *)menuForWindowLevelsNotifyingTarget:(id)target
{
	NSMenu		*windowPositionMenu = [[NSMenu alloc] init];
	NSMenuItem	*menuItem;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Above other windows",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AIFloatingWindowLevel];
	[windowPositionMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Normally",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AINormalWindowLevel];
	[windowPositionMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Below other windows",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AIDesktopWindowLevel];
	[windowPositionMenu addItem:menuItem];
	
	[windowPositionMenu setAutoenablesItems:NO];

	return windowPositionMenu;
}

-(void)toggleUserlist:(id)sender
{
	[self.activeChat.chatContainer.chatViewController toggleUserList];
}

-(void)toggleUserlistSide:(id)sender
{
	[self.activeChat.chatContainer.chatViewController toggleUserListSide];
}

-(void)clearDisplay:(id)sender
{
	[self.activeChat.chatContainer.messageViewController.messageDisplayController clearView];
}

@end
