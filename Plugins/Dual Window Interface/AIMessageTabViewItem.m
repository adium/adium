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

#import <Adium/AIContactControllerProtocol.h>
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#define BACK_CELL_LEFT_INDENT	-1
#define BACK_CELL_RIGHT_INDENT	3
#define LABEL_SIDE_PAD		0

@interface AIMessageTabViewItem ()
- (id)initWithMessageView:(AIMessageViewController *)inMessageView;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)chatStatusChanged:(NSNotification *)notification;
- (void)listObjectAttributesChanged:(NSNotification *)notification;
- (void)setLargeImage:(NSImage *)inImage;
- (void)updateTabStatusIcon;
- (void)updateTabContactIcon;

- (void)chatSourceOrDestinationChanged:(NSNotification *)notification;
- (void)chatAttributesChanged:(NSNotification *)notification;
@end

@implementation AIMessageTabViewItem

//
+ (AIMessageTabViewItem *)messageTabWithView:(AIMessageViewController *)inMessageView
{
    return [[self alloc] initWithMessageView:inMessageView];
}

//init
- (id)initWithMessageView:(AIMessageViewController *)inMessageViewController
{
	/* XXX - Warning! Setting self as the identifier also means that we are retaining ourselves!  Something _must_
	 * break us out of this infinite loop.  This happens in -[AIMesageWindowController removeTabViewItem:silent:].
	 */
	if ((self = [super initWithIdentifier:self])) {
		messageViewController = inMessageViewController;
		windowController = nil;

		//Configure ourself for the message view
		AIChat *chat = messageViewController.chat;
		
		//groupchats don't have any concept of status beyond typing indicators, so we don't need to watch most of this
		if(!chat.isGroupChat)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(chatSourceOrDestinationChanged:)
											   name:Chat_SourceChanged
											 object:chat];
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(chatSourceOrDestinationChanged:)
											   name:Chat_DestinationChanged
											 object:chat];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatParticipatingListObjectsChanged:)
											   name:Chat_ParticipatingListObjectsChanged
											 object:chat];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatAttributesChanged:)
											   name:Chat_AttributesChanged
											 object:chat];
		} else {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(updateTabStatusIcon)
														 name:ListObject_StatusChanged
													   object:chat.account];	
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatStatusChanged:)
										   name:Chat_StatusChanged
										 object:chat];
		
		[self chatStatusChanged:nil];
		[self chatParticipatingListObjectsChanged:nil];
		
		//Set our contents
		[self setView:[messageViewController view]];
	}
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Access to our message view controller
- (AIMessageViewController *)messageViewController
{
    return messageViewController;
}

- (id <AIChatViewController>)chatViewController
{
	return [self messageViewController];
}

//Our chat
- (AIChat *)chat
{
	return messageViewController.chat;
}

//Our containing window
- (void)setWindowController:(AIMessageWindowController *)inWindowController{
	if (inWindowController != windowController) {
		[messageViewController messageViewWillLeaveWindowController:windowController];

		windowController = inWindowController;

		[messageViewController messageViewAddedToWindowController:windowController];
	}
}

- (AIMessageWindowController *)windowController{
	return windowController;
}

//Message View Delegate ----------------------------------------------------------------------
#pragma mark Message View Delegate

/*!
 * @brief The list objects participating in our chat changed
 */
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
	AIListObject	*listObject;

	//Remove the old observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ListObject_AttributesChanged object:nil];

	//If there is a single list object for this chat, observe its attribute changes
	if ((listObject = [messageViewController listObject])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:)
										   name:ListObject_AttributesChanged
										 object:nil];
		
	}

	//Notify that our list object's attributes have changed, because our list object has changed.
	//We fake a ListObject_AttributesChanged notification with our new list object. Our list object may be nil, but that's fine.
	notification = [NSNotification notificationWithName:ListObject_AttributesChanged
												 object:listObject];
	[self listObjectAttributesChanged:notification];
}

- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];

    //If the display name changed, we resize the tabs
    if (notification == nil || [keys containsObject:@"Display Name"] || [keys containsObject:@"accountJoined"]) {
		[self setLabel:[self label]];
		[self updateTabStatusIcon];
    } else if ([keys containsObject:KEY_UNVIEWED_CONTENT]) {
		[self setValue:nil forKeyPath:@"objectCount"];
		[self setValue:nil forKeyPath:@"countColor"];
	}
}

- (void)chatAttributesChanged:(NSNotification *)notification
{
	NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	//Redraw if the icon has changed
	if (keys == nil || [keys containsObject:@"tabStateIcon"]) {
		[self updateTabStatusIcon];
	}
	if (keys == nil || [keys containsObject:KEY_USER_ICON]) {
		[self updateTabContactIcon];
	}
}

- (void)chatSourceOrDestinationChanged:(NSNotification *)notification
{
	[self updateTabStatusIcon];
	[self updateTabContactIcon];
}

- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	AIListObject *listObject = [notification object];
	AIListContact *messageViewContact = [messageViewController listObject]; //Is the contact in the message view part of a metacontact?
	
	if (!listObject || (listObject == messageViewContact) || listObject == [messageViewContact parentContact]) {
		NSSet		 *keys = [[notification userInfo] objectForKey:@"Keys"];

		//Redraw if the icon has changed
		if (!keys || [keys containsObject:@"tabStatusIcon"]) {
			[self updateTabStatusIcon];
		}
		if (!keys || [keys containsObject:KEY_USER_ICON]) {
			[self updateTabContactIcon];
		}

		//If the list object's display name changed, we resize the tabs
		if (!keys || [keys containsObject:@"Display Name"]) {
			[self setLabel:[self label]];
			[self updateTabStatusIcon];
		}
	}
}

//Interface Container ----------------------------------------------------------------------
#pragma mark Interface Container

//Make this container active
- (void)makeActive:(id)sender
{
    NSTabView	*tabView = [self tabView];
    NSWindow	*window	= [tabView window];

    if ([tabView selectedTabViewItem] != self) {
        [tabView selectTabViewItem:self]; //Select our tab
    }

    if (![window isKeyWindow] || ![window isVisible]) {
        [window makeKeyAndOrderFront:nil]; //Bring our window to the front
    }
}

//Close this container
- (void)close:(id)sender
{
    [[self tabView] removeTabViewItem:self];
}



//Tab view item  ----------------------------------------------------------------------
#pragma mark Tab view item

//Called when our tab is selected
- (void)tabViewItemWasSelected
{
    //Ensure our entry view is first responder
    [messageViewController didSelect];
}

- (void)tabViewItemWillDeselect
{
	[messageViewController willDeselect];
}

- (NSString *)label
{
	return messageViewController.chat.displayName;
}

- (void)setIcon:(NSImage *)newIcon
{
	//method does nothing; force the tab bindings to reload -icon
}

//Return the icon to be used for our tabs.  State gets first priority, then status.
- (NSImage *)icon
{
	NSImage *image = self.stateIcon;
	
	//Multi-user chats won't have status icons
	if (!image && messageViewController.chat.isGroupChat) {
		BOOL displayOnline = messageViewController.chat.account.online && [messageViewController.chat boolValueForProperty:@"accountJoined"];
		
		image = [AIStatusIcons statusIconForStatusName:nil
											statusType:displayOnline ? AIAvailableStatusType : AIOfflineStatusType
											  iconType:AIStatusIconTab
											 direction:AIIconNormal];
	} else if (!image) {
		image = [self statusIcon];
	}

	if (!image) image = [AIStatusIcons statusIconForUnknownStatusWithIconType:AIStatusIconTab direction:AIIconNormal];

	return image;
}

//Status icon is the status of this contact (away, idle, online, stranger)
- (NSImage *)statusIcon
{
	return [AIStatusIcons statusIconForListObject:[messageViewController.chat listObject]
											 type:AIStatusIconTab
										direction:AIIconNormal];
}

//State icon is the state of the contact (Typing, unviewed content)
- (NSImage *)stateIcon
{
	return [messageViewController.chat valueForProperty:@"tabStateIcon"];
}

- (NSImage *)image
{
	return tabViewItemImage;
}

- (void)setLargeImage:(NSImage *)inImage
{
	if (largeImage != inImage) {
		largeImage = [inImage copy];
	}
}

- (NSImage *)largeImage
{
	return largeImage;
}

//bindings methods for PSMTabBarControl

- (void)setObjectCount:(NSNumber *)number
{
	//method does nothing; force the tab bindings to reload -objectCount
}

- (NSInteger)objectCount
{
	if (self.chat.isGroupChat) {
		if ([[adium.preferenceController preferenceForKey:KEY_TABBAR_SHOW_UNREAD_COUNT_GROUP
													group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue]) {
			if ([[adium.preferenceController preferenceForKey:KEY_TABBAR_SHOW_UNREAD_MENTION_ONLYGROUP
														group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue]) {
				return self.chat.unviewedMentionCount;
			} else {
				return self.chat.unviewedContentCount;
			}
		}
	} else {
		if ([[adium.preferenceController preferenceForKey:KEY_TABBAR_SHOW_UNREAD_COUNT
													group:PREF_GROUP_DUAL_WINDOW_INTERFACE] boolValue]) {
			return self.chat.unviewedContentCount;
		}
	}
	
	// Returning 0 disables it.
	return 0;
}

- (void)setCountColor:(NSColor *)color
{
	//method does nothing; force the tab bindings to reload -countColor	
}

- (NSColor *)countColor
{
	return self.chat.unviewedMentionCount ? [NSColor colorWithCalibratedRed:1.0f green:0.3f blue:0.3f alpha:0.6f] : [NSColor colorWithCalibratedWhite:0.3f alpha:0.6f];
}

- (void)tabViewDidChangeVisibility
{
	[self.messageViewController tabViewDidChangeVisibility];
}

//Update the contact and status icons on the tab.
- (void)updateTabStatusIcon
{
	/* Really, we should be observing for the icon changing and posting a dependent key change notification when it does...
	 * Pretending to have changed our icon key is a path of much less resistance to note that -[self icon] has changed.
	 */
	[self willChangeValueForKey:@"icon"];
	[self.windowController updateIconForTabViewItem:self];
	[self didChangeValueForKey:@"icon"];
}
- (void)updateTabContactIcon
{
	[self willChangeValueForKey:@"icon"];
	[self setLargeImage:[self.chat.chatImage imageByScalingToSize:NSMakeSize(48,48)]];
	[self didChangeValueForKey:@"icon"];
}

@end
