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

#import "AIDualWindowInterfacePlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import <Adium/AIChatControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>

#define ADIUM_UNIQUE_CONTAINER			@"ADIUM_UNIQUE_CONTAINER"

@implementation AIDualWindowInterfacePlugin

//Install
- (void)installPlugin
{
    [adium.interfaceController registerInterfaceController:self];
}

//Open the interface
- (void)openInterface
{
	containers = [[NSMutableDictionary alloc] init];
	delayedContainerShowArray = [[NSMutableArray alloc] init];
	uniqueContainerNumber = 0;
	applicationIsHidden = NO;

	//Preferences
	//XXX - move to separate plugin
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] 
										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	//Watch Adium hide and unhide (Used for better window opening behavior)
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidHide:)
												 name:NSApplicationDidHideNotification
											   object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidUnhide:)
												 name:NSApplicationDidUnhideNotification
											   object:NSApp];
}

//Close the interface
- (void)closeInterface
{
	//Close and unload our windows
	[[containers allValues] makeObjectsPerformSelector:@selector(closeWindow:) withObject:nil];

	//Stop observing
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//Cleanup
	containers = nil;
	delayedContainerShowArray = nil;
}	


//Interface: Chat Control ----------------------------------------------------------------------------------------------
#pragma mark Interface: Chat Control
//Open a new chat window
- (id)openChat:(AIChat *)chat inContainerWithID:(NSString *)containerID withName:(NSString *)containerName atIndex:(NSUInteger)idx
{
	AIMessageTabViewItem		*messageTab = (AIMessageTabViewItem *)[chat chatContainer];
	AIMessageWindowController	*container = nil;
	AIMessageViewController 	*messageView = nil;
	
	//Create the message tab (if necessary)
	if (!messageTab) {
		container = [self openContainerWithID:containerID name:containerName];
		messageView = [AIMessageViewController messageDisplayControllerForChat:chat];
		
		//
		
		//Add chat to container
		messageTab = [AIMessageTabViewItem messageTabWithView:messageView];
		[chat setValue:messageTab
		   forProperty:@"messageTabViewItem"
				notify:NotifyNever];
		[container addTabViewItem:messageTab atIndex:idx silent:NO];
	}

    //Display the account selector if necessary
	[[messageTab messageViewController] setAccountSelectionMenuVisibleIfNeeded:YES];
	
	//Open the container window.  We wait until after the chat has been added to the container
	//before making it visible so window opening looks cleaner.
	if (container && !applicationIsHidden && ![[container window] isMiniaturized] && ![[container window] isVisible]) {
		[container showWindowInFrontIfAllowed:!(adium.interfaceController.activeChat)];
	}
	
	return messageTab;
}

/*!
 * @brief Close a chat
 *
 * First, tell the chatController to close the chat. If it returns YES, remove our interface to the chat.
 * Take no action if it returns NO; this indicates that the chat shouldn't close, probably because it's about
 * to receive another message.
 */
- (void)closeChat:(AIChat *)chat
{
	AIMessageTabViewItem		*messageTab = (AIMessageTabViewItem *)chat.chatContainer;
	AIMessageWindowController *container = messageTab.windowController;

	//Close the chat
	[container removeTabViewItem:messageTab silent:NO];
	[chat setValue:nil
	   forProperty:@"messageTabViewItem"
			notify:NotifyNever];
}

//Make a chat active
- (void)setActiveChat:(AIChat *)inChat
{
	AIMessageTabViewItem *messageTab = (AIMessageTabViewItem *)[inChat chatContainer];
	if (messageTab) [messageTab makeActive:nil];
}

//Move a chat
- (void)moveChat:(AIChat *)chat toContainerWithID:(NSString *)containerID index:(NSUInteger)idx
{
	AIMessageTabViewItem		*messageTab = (AIMessageTabViewItem *)[chat chatContainer];
	AIMessageWindowController	*windowController = [containers objectForKey:containerID];

	if ([messageTab windowController] == windowController) {
		[windowController moveTabViewItem:messageTab toIndex:idx];
	} else {
		[[messageTab windowController] removeTabViewItem:messageTab silent:YES];

		//Create the container if necessary
		if (!windowController) {
			windowController = [self openContainerWithID:containerID name:containerID];
		}

		[windowController addTabViewItem:messageTab atIndex:idx silent:YES];
	}
}


//Interface: Chat Access -----------------------------------------------------------------------------------------------
#pragma mark Interface: Chat Access
/*!
 * @brief Return an array of NSDictionary objects for all open containers with associated information
 * 
 * The returned array has zero or more NSDictionary objects with the following information for each container
 *	Key				Value
 *	@"ID"			NSString of the containerID
 *	@"Frame"		NSString of the window's [NSWindow frame]
 *	@"Content"		NSArray of the AIChat objects within that container
 *	@"ActiveChat"	AIChat that is currently active
 *	@"Name"			NSString of the container's name
 */
- (NSArray *)openContainersAndChats
{
	NSMutableArray				*openContainersAndChats = [NSMutableArray array];
	
	for (AIMessageWindowController *container in [containers objectEnumerator]) {
		[openContainersAndChats addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										   container.containerID, @"ID",
										   NSStringFromRect(container.window.frame), @"Frame",
										   container.containedChats, @"Content",
										   container.activeChat, @"ActiveChat",
										   container.name, @"Name",
										   nil]];
	}
	
	return openContainersAndChats;
}

//Returns an array of open container IDs
- (NSArray *)openContainerIDs
{
	return [containers allKeys];
}

//Returns an array of open chats
- (NSArray *)openChats
{
	NSMutableArray				*openContainersAndChats = [NSMutableArray array];

	for (AIMessageWindowController *container in [containers objectEnumerator]) {
		[openContainersAndChats addObjectsFromArray:container.containedChats];
	}
	
	return openContainersAndChats;
}

//Returns the ID of the container containing the chat
- (NSString *)containerIDForChat:(AIChat *)chat
{
	return [[(AIMessageTabViewItem *)[chat chatContainer] windowController] containerID];
}

//Returns an array of all the chats in a container
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID
{
	return [[containers objectForKey:containerID] containedChats];
}

/*!
 * @brief Find the window currently displaying a chat
 *
 * If the chat is not in any window, or is not visible in any window, returns nil
 */
- (NSWindow *)windowForChat:(AIChat *)chat
{
	AIMessageWindowController	*windowController = [(AIMessageTabViewItem *)[chat chatContainer] windowController];
	
	return (([windowController activeChat] == chat) ?
			[windowController window] :
			nil);
}

/*!
 * @brief Find the chat active in a window
 *
 * If the window does not have an active chat, nil is returned
 */
- (AIChat *)activeChatInWindow:(NSWindow *)window
{
	AIChat				*chat = nil;
	NSWindowController	*windowController = [window windowController];

	if ([windowController isKindOfClass:[AIMessageWindowController class]]) {
		chat = [(AIMessageWindowController *)windowController activeChat];
	}
	
	return chat;
}

//Containers -----------------------------------------------------------------------------------------------------------
#pragma mark Containers
//Open a new container
- (AIMessageWindowController *)openContainerWithID:(NSString *)containerID name:(NSString *)containerName
{
	if (!containerID) {
		while (!containerID || [containers objectForKey:containerID]) {
			containerID = [NSString stringWithFormat:@"%@:%ld", ADIUM_UNIQUE_CONTAINER, (long)uniqueContainerNumber++];
		}
	}

	AIMessageWindowController	*windowController = [containers objectForKey:containerID];
	if (!windowController) {
		windowController = [AIMessageWindowController messageWindowControllerForInterface:self withID:containerID name:containerName];
		[containers setObject:windowController forKey:containerID];
		
		//If Adium is hidden, remember to open this container later
		if (applicationIsHidden) [delayedContainerShowArray addObject:windowController];
	}
	
	return windowController;
}

//Close a continer
- (void)closeContainer:(AIMessageWindowController *)container
{
	[container closeWindow:nil];
}

//A container did close
- (void)containerDidClose:(AIMessageWindowController *)container
{
	NSString	*key = [[containers allKeysForObject:container] lastObject];
	if (key) [containers removeObjectForKey:key];
}

//Adium hid
- (void)applicationDidHide:(NSNotification *)notification
{
	applicationIsHidden = YES;
}

//Adium unhid
- (void)applicationDidUnhide:(NSNotification *)notification
{
	AIMessageWindowController	*container;

	//Open any containers that should have opened while we were hidden
	for (container in delayedContainerShowArray) [container showWindowInFrontIfAllowed:YES];

	[delayedContainerShowArray removeAllObjects];
	applicationIsHidden = NO;
}


//Custom Tab Management ------------------------------------------------------------------------------------------------
#pragma mark Custom Tab Management
//Transfer a tab from one window to another (or to its own window)
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem
			   toContainer:(id)newMessageWindowController
				   atIndex:(NSInteger)idx
		 withTabBarAtPoint:(NSPoint)screenPoint
{
	AIMessageWindowController 	*oldMessageWindowController = [tabViewItem windowController];
	
	if (oldMessageWindowController != newMessageWindowController) {
		//Get the frame of the source window (We must do this before removing the tab, since removing a tab may
		//destroy the source window)
		NSRect  oldMessageWindowFrame = [[oldMessageWindowController window] frame];
		
		//Remove the tab, which will close the containiner if it becomes empty
		[oldMessageWindowController removeTabViewItem:tabViewItem silent:YES];
		
		//Spawn a new window (if necessary)
		if (!newMessageWindowController) {
			NSRect          newFrame;
			
			//Default to the width of the source container, and the drop point
			newFrame.size.width = oldMessageWindowFrame.size.width;
			newFrame.size.height = oldMessageWindowFrame.size.height;
			
			newFrame.origin = screenPoint;
			
			//Create a new unique container, set the frame
			newMessageWindowController = [self openNewContainer];
			
			//If we weren't given an origin, find one from the window's frame
			if (newFrame.origin.x == -1 && newFrame.origin.y == -1) {
				NSRect curFrame = [[newMessageWindowController window] frame];
				newFrame.origin = curFrame.origin;

				//Cascade
				newFrame.origin.x += 20;
				newFrame.origin.y -= 20;
			}
			
			[[newMessageWindowController window] setFrame:newFrame display:NO];
		}
		
		[(AIMessageWindowController *)newMessageWindowController addTabViewItem:tabViewItem atIndex:idx silent:YES]; 
		[adium.interfaceController chatOrderDidChange];
		[tabViewItem makeActive:nil];
	}
	
}

- (id)openNewContainer
{	
	AIMessageWindowController *controller = [self openContainerWithID:nil name:nil];
	return controller;
}

- (void)moveChatToNewContainer:(AIChat *)inChat
{
	[self transferMessageTab:(AIMessageTabViewItem *)[inChat chatContainer]
				 toContainer:nil
					 atIndex:0
		   withTabBarAtPoint:NSMakePoint(-1, -1)];
}

@end

