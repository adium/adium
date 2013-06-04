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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListObject.h>
#import "CBStatusMenuItemPlugin.h"
#import "CBStatusMenuItemController.h"
#import "AIMenuBarIcons.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIContactHidingController.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
// For the KEY_SHOW_OFFLINE_CONTACTS and PREF_GROUP_CONTACT_LIST_DISPLAY
#import "AIContactController.h"
#import "AIInterfaceController.h"

#define STATUS_ITEM_MARGIN 8

@interface CBStatusMenuItemController ()
- (void)activateAdium;
- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)inImage;
- (void)updateMenuIcons;
- (void)updateMenuIconsBundle;
- (void)updateUnreadCount;
- (void)updateOpenChats;
- (void)updateStatusItemLength;

- (void)switchToChat:(id)sender;
- (void)activateAccountList:(id)sender;
- (void)disableStatusItem:(id)sender;

@property (nonatomic, retain) NSMenuItem *contactsMenuItem;
@end

@implementation CBStatusMenuItemController

@synthesize contactsMenuItem;

+ (CBStatusMenuItemController *)statusMenuItemController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		//Create and set up the status item
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:25] retain];
		
		statusItemView = [[AIStatusItemView alloc] initWithFrame:NSMakeRect(0,0,25,22)];
		statusItemView.statusItem = statusItem;
		[statusItem setView:statusItemView];
		
		unviewedContent = NO;
		[self updateMenuIconsBundle];
		
		// Create our menus
		mainMenu = [[NSMenu alloc] init];
		[mainMenu setDelegate:self];

		mainAccountsMenu = [[NSMenu alloc] init];
		[mainAccountsMenu setDelegate:self];
		
		mainOptionsMenu = [[NSMenu alloc] init];
		[mainOptionsMenu setDelegate:self];

		// Set the main menu as the status item's menu
		statusItemView.menu = mainMenu;

		// Flag all the menus as needing updates
		mainMenuNeedsUpdate = YES;
		contactsMenuNeedsUpdate = YES;
		accountsMenuNeedsUpdate = YES;
		optionsMenuNeedsUpdate = YES;
		
		self.contactsMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Contacts",nil)
																					  target:self
																					  action:nil
																			   keyEquivalent:@""] autorelease];

		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		//Register to recieve chat opened and chat closed notifications
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_DidOpen
		                         object:nil];
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_WillClose
		                         object:nil];
		[notificationCenter addObserver:self
		                       selector:@selector(updateOpenChats)
		                           name:Chat_OrderDidChange
		                         object:nil];		
		
		[notificationCenter addObserver:self
							   selector:@selector(updateMenuIcons)
								   name:AIStatusIconSetDidChangeNotification
								 object:nil];
		
		// Register for our menu bar icon set changing
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(updateMenuIconsBundle)
										   name:AIMenuBarIconsDidChangeNotification
										 object:nil];
		
		// Register as a chat observer so we can know the status of unread messages
		[adium.chatController registerChatObserver:self];
		
		// Register as a list object observer so we can know when accounts need to show reconnecting
	    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
		
		// Register as an observer of the preference group so we can update our "show groups contacts" option
		[adium.preferenceController registerPreferenceObserver:self
														forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
		// Register as an observer of the status preferences for unread conversation count
		[adium.preferenceController registerPreferenceObserver:self
														forGroup:PREF_GROUP_STATUS_PREFERENCES];		
		
		// Register as an observer of our own preference group
		[adium.preferenceController registerPreferenceObserver:self
														forGroup:PREF_GROUP_STATUS_MENU_ITEM];
		
		//Register to recieve active state changed notifications
		[notificationCenter addObserver:self
		                       selector:@selector(updateMenuIcons)
		                           name:AIStatusActiveStateChangedNotification
		                         object:nil];
		
		//Register ourself for the status menu items
		statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
		
		//Account menu
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
												  submenuType:AIAccountStatusSubmenu
											   showTitleVerbs:YES] retain];
		
		//Contact menu
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self
										  forContactsInObject:nil] retain];
	}
	
	return self;
}

- (void)dealloc
{
	// Invalidate and release our timers
	[self invalidateTimers];
	
	//Unregister ourself
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	//Release our objects
	[[statusItem statusBar] removeStatusItem:statusItem];
	[statusItemView release];

	// All the temporary NSMutableArrays we store
	[accountMenuItemsArray release];
	[stateMenuItemsArray release];
	[openChatsArray release];
	
	// The menus
	[mainMenu release];
	[mainAccountsMenu release];
	[mainOptionsMenu release];
	
	// Release our various menus.
	[accountMenu setDelegate:nil]; [accountMenu release];
	[contactMenu setDelegate:nil]; [contactMenu release];
	[statusMenu setDelegate:nil]; [statusMenu release];

	// Release our AIMenuBarIcons bundle
	[menuIcons release];
	[statusItem release];
	
	//To the superclass, Robin!
	[super dealloc];
}

#pragma mark Icon State

#define PREF_GROUP_APPEARANCE		@"Appearance"
#define	KEY_MENU_BAR_ICONS			@"Menu Bar Icons"
#define EXTENSION_MENU_BAR_ICONS	@"AdiumMenuBarIcons"
#define	RESOURCE_MENU_BAR_ICONS		@"Menu Bar Icons"

/*!
 * @brief Update the Xtra bundle
 *
 * Updates the stored information we have on an \c AdiumMenuBarIcons bundle.
 */
- (void)updateMenuIconsBundle
{
	NSString *menuIconPath = nil, *menuIconName;
	
	menuIconName = [adium.preferenceController preferenceForKey:KEY_MENU_BAR_ICONS
															group:PREF_GROUP_APPEARANCE
														   object:nil];
	
	// Get the path of the pack if found.
	if (menuIconName) {
		menuIconPath = [adium pathOfPackWithName:menuIconName
									   extension:EXTENSION_MENU_BAR_ICONS
							  resourceFolderName:RESOURCE_MENU_BAR_ICONS];
	}
	
	// If the pack is not found, get the default one.
	if (!menuIconPath || !menuIconName) {
		menuIconName = [adium.preferenceController defaultPreferenceForKey:KEY_MENU_BAR_ICONS
																	   group:PREF_GROUP_APPEARANCE
																	  object:nil];
		menuIconPath = [adium pathOfPackWithName:menuIconName
									   extension:EXTENSION_MENU_BAR_ICONS
							  resourceFolderName:RESOURCE_MENU_BAR_ICONS];
	}
	
	[menuIcons release];
	menuIcons = [[AIMenuBarIcons alloc] initWithURL:[NSURL fileURLWithPath:menuIconPath]];
	
	[self updateMenuIcons];
}

/*!
 * @brief Update the unread count
 *
 * Updates the string text found next to the status item's icon.
 */
- (void)updateUnreadCount
{
	NSUInteger unreadCount = (showConversationCount ?
					   [adium.chatController unviewedConversationCount] : [adium.chatController unviewedContentCount]);

	// Only show if enabled and greater-than zero; otherwise, set to nil.
	if (showUnreadCount && unreadCount > 0) {
		[statusItemView setStringValue:[NSString stringWithFormat:@"%lu", unreadCount]];
	} else {
		[statusItemView setStringValue:nil];
	}
}

/*!
 * @brief Update the unviewed content flash
 * @arg timer The NSTimer calling this method
 *
 * Toggles state between having unread content and not every time the timer ends.
 */
- (void)updateUnviewedContentFlash:(NSTimer *)timer
{
	// Invert our current setting
	currentlyIgnoringUnviewed = !currentlyIgnoringUnviewed;
	// Update our current menu icon
	[self updateMenuIcons];
}

/*!
 * @brief Invalidate running timers
 *
 * Since an NSTimer instance retains its targets, this method is used to prevent
 * \c autoreleased objects from being stuck around indefinitely.
 */
- (void)invalidateTimers
{
	currentlyIgnoringUnviewed = NO;
	[unviewedContentFlash invalidate];
	[unviewedContentFlash release]; unviewedContentFlash = nil;
}

#define	IMAGE_TYPE_CONTENT		@"Content"
#define	IMAGE_TYPE_AWAY			@"Away"
#define IMAGE_TYPE_IDLE			@"Idle"
#define	IMAGE_TYPE_INVISIBLE	@"Invisible"
#define	IMAGE_TYPE_OFFLINE		@"Offline"
#define	IMAGE_TYPE_ONLINE		@"Online"

/*!
 * @brief Update the menu icons
 *
 * Updates the menu icon with the appropriate icon and badge icon.
 */
- (void)updateMenuIcons
{
	NSImage			*badge = nil;
	NSString		*imageName;

	// If there's content, set our badge to the "content" icon.
	if (unviewedContent && !currentlyIgnoringUnviewed) {
		if (showBadge) {
			badge = [AIStatusIcons statusIconForStatusName:@"content"
												statusType:AIAvailableStatusType
											      iconType:AIStatusIconList
												 direction:AIIconNormal];
		}
		
		imageName = IMAGE_TYPE_CONTENT;
	} else {
		// Get the correct icon for our current state.
		switch([adium.statusController.activeStatusState statusType]) {
			case AIAwayStatusType:
				if (showBadge) {
					badge = [adium.statusController.activeStatusState icon];
				}
				
				imageName = IMAGE_TYPE_AWAY;
				break;
			
			case AIInvisibleStatusType:
				if (showBadge) {
					badge = [adium.statusController.activeStatusState icon];
				}
				
				imageName = IMAGE_TYPE_INVISIBLE;
				break;
				
			case AIOfflineStatusType:
				imageName = IMAGE_TYPE_OFFLINE;
				break;
				
			default:
				// Assuming we're using an online image unless proven otherwise
				imageName = IMAGE_TYPE_ONLINE;

				// Check idle here, since it has less precedence than offline, invisible, or away.
				for (AIAccount *account in adium.accountController.accounts) {
					if (account.online && [account valueForProperty:@"idleSince"]) {
						if (showBadge) {
							badge = [AIStatusIcons statusIconForStatusName:@"Idle"
																statusType:AIAvailableStatusType
																  iconType:AIStatusIconList
																 direction:AIIconNormal];
						}
						
						imageName = IMAGE_TYPE_IDLE;
						
						break;
					}
				}

				break;
		}
	}
	
	NSImage *menuIcon = [menuIcons imageOfType:imageName alternate:NO];
	NSImage *alternateMenuIcon = [menuIcons imageOfType:imageName alternate:YES];
	
	// Set our icon.
	statusItemView.regularImage = [self badgeDuck:menuIcon withImage:badge];
	// Badge the highlight image and set it.
	statusItemView.alternateImage = [self badgeDuck:alternateMenuIcon withImage:badge];
	// Update our unread count.
	if (showUnreadCount) {
		[self updateUnreadCount];
	}
	// Update the status item length
	[self updateStatusItemLength];
}

/*!
 * @brief Update the status item's width
 */
- (void)updateStatusItemLength
{
	[statusItem setLength:statusItemView.desiredWidth + STATUS_ITEM_MARGIN];
	[statusItemView setFrame:NSMakeRect(0, 0, statusItemView.desiredWidth + STATUS_ITEM_MARGIN, 22)];
	[statusItemView setNeedsDisplay:YES];
}

/*!
 * @brief Badge the given image with the given badge
 * @arg duckImage The base image
 * @arg badgeImage The badge which will be draw on the base image
 *
 * Draws the \c badgeImage in the bottom right quadrant of the \c duckImage.
 */
- (NSImage *)badgeDuck:(NSImage *)duckImage withImage:(NSImage *)badgeImage 
{
	NSImage *image = duckImage;
	
	if (badgeImage) {
		image = [[duckImage copy] autorelease];
		
		[image lockFocus];
		
		NSRect srcRect = { NSZeroPoint, [badgeImage size] };
		//Draw in the lower-right quadrant.
		NSRect destRect = {
			{ .x = srcRect.size.width, .y = 0.0f },
			[duckImage size]
		};
		destRect.size.width  *= 0.5f;
		destRect.size.height *= 0.5f;
		
		//If the badge is bigger than that portion, resize proportionally. Otherwise, leave it alone and adjust the destination origin appropriately.
		if ((srcRect.size.width > destRect.size.width) || (srcRect.size.height > destRect.size.height)) {
			//Resize the dest rect.
			CGFloat scale;
			if (srcRect.size.width > srcRect.size.height) {
				scale = destRect.size.width  / srcRect.size.width;
			} else {
				scale = destRect.size.height / srcRect.size.height;
			}
			
			destRect.size.width  = srcRect.size.width  * scale;
			destRect.size.height = srcRect.size.height * scale;
			
			//Make sure we scale in a pretty manner.
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		}
		
		//Move the drawing origin.
		destRect.origin.x = [duckImage size].width - destRect.size.width;
		
		[badgeImage drawInRect:destRect
					  fromRect:srcRect
					 operation:NSCompositeSourceOver
					  fraction:1.0f];
		[image unlockFocus];
	}
	
	return image;
}

#pragma mark Account Menu
/*!
 * @brief AIAccountMenu delegate method
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	// Going from or to 1 account requires a main menu update
	if ([accountMenuItemsArray count] == 1 || [menuItems count] == 1)
		mainMenuNeedsUpdate = YES;
	
	
	[accountMenuItemsArray release];
	accountMenuItemsArray = [menuItems retain];
	
	//We need to update next time we're clicked
	accountsMenuNeedsUpdate = YES;
}

/*!
 * @brief AIAccountMenu delegate method
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[inAccount toggleOnline];
}

#pragma mark Status Menu
/*!
 * @brief AIStatusMenu delegate method
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	[stateMenuItemsArray release];
	stateMenuItemsArray = [menuItemArray retain];
	
	//We need to update next time we're clicked
	mainMenuNeedsUpdate = YES;
}

#pragma mark Contact Menu
/*!
 * @brief AIContactMenu delegate method
 */
- (void)contactMenuDidRebuild:(AIContactMenu *)inContactMenu 
{
	NSMenu *menu = inContactMenu.menu;
	NSInteger newNumberOfMenuItems = menu.numberOfItems;

	// Going from or to 0 contacts requires a main menu update
	if (currentContactMenuItemsCount == 0 || newNumberOfMenuItems == 0)
		mainMenuNeedsUpdate = YES;

	currentContactMenuItemsCount = 	menu.numberOfItems;
	
	/* The alternate menu is what shows if you option-click the menu item */
	statusItemView.alternateMenu = menu;
	
	[self.contactsMenuItem setSubmenu:menu];
}

/*!
 * @brief AIContactMenu delegate method
 */
- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact
{
	[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:inContact
																	onPreferredAccount:YES]];
	
	[self activateAdium];
}

/*!
 * @brief AIContactMenu delegate method
 *
 * Shows the given contact if it is visible in the contact list.
 */
- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact
{
	// Show this contact if we're showing offline contacts or if this contact is online.
	for (id<AIContainingObject> container in inContact.containingObjects) 
	{
		if ([[AIContactHidingController sharedController] visibilityOfListObject:inContact inContainer:container])
			return YES;
	}
		
	return NO;
}

/*!
 * @brief AIContactMenu delegate method
 */
- (BOOL)contactMenuShouldDisplayGroupHeaders:(AIContactMenu *)inContactMenu
{
	return showContactGroups;
}

/*!
 * @brief AIContactMenu delegate method
 */
- (BOOL)contactMenuShouldUseDisplayName:(AIContactMenu *)inContactMenu
{
	return YES;
}

/*!
 * @brief AIContactMenu delegate method
 */
- (BOOL)contactMenuShouldUseUserIcon:(AIContactMenu *)inContactMenu
{
	return YES;
}

/*!
 * @brief AIContactMenu delegate method
 */
- (BOOL)contactMenuShouldSetTooltip:(AIContactMenu *)inContactMenu
{
	return YES;
}

- (BOOL) contactMenuShouldIncludeContactListMenuItem:(AIContactMenu *)inContactMenu
{
	return YES;
}

- (BOOL)contactMenuShouldPopulateMenuLazily:(AIContactMenu *)inContactMenu
{
	return YES;
}

#pragma mark List Object Observer
/*!
 * @brief List Observer delegate method
 *
 * Updates the menu icon if our accounts change connecting state.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"isConnecting"] ||
			[inModifiedKeys containsObject:@"waitingToReconnect"]) {
			[self updateMenuIcons];
		}
	}
	
	return nil;
}

#pragma mark Chat Observer
/*!
 * @brief Chat observer delegate method
 *
 * Updates our opened chats when called.
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	[self updateOpenChats];
	
	// We didn't modify anything; return nil.
	return nil;
}

/*!
 * @brief Updates open chats menu
 *
 * Update our content image if necessary, creating an NSTimer instance to flash the badge if the 
 * user has the preference enabled to do so.
 */
- (void)updateOpenChats
{
	[self retain];
	
	NSUInteger unviewedContentCount = [adium.chatController unviewedContentCount];

	// Update our open chats
	[openChatsArray release];
	openChatsArray = [[adium.interfaceController openChats] retain];
	
	// We think there's unviewed content, but there's not.
	if (unviewedContent && unviewedContentCount == 0) {
		// Invalidate and release the unviewed content flash timer
		[unviewedContentFlash invalidate];
		[unviewedContentFlash release]; unviewedContentFlash = nil;
		currentlyIgnoringUnviewed = NO;
		
		// Update unviewed content
		unviewedContent = NO;
		
		// Update our menu icons
		[self updateMenuIcons];
	// We think there's no unviewed content, and there is.
	} else if (!unviewedContent && unviewedContentCount > 0) {
		// If this particular Xtra wants us to flash unviewed content, start the timer up
		if (flashUnviewed) {
			currentlyIgnoringUnviewed = NO;
			unviewedContentFlash = [[NSTimer scheduledTimerWithTimeInterval:1.0
																	 target:self
																   selector:@selector(updateUnviewedContentFlash:)
																   userInfo:nil
																	repeats:YES] retain];
		}
		
		// Update unviewed content
		unviewedContent = YES;
		
		// Update our menu icons
		[self updateMenuIcons];
	// If we already know there's unviewed content, just update the count.
	} else if (unviewedContent && unviewedContentCount > 0) {
		[self updateUnreadCount];
	}

	mainMenuNeedsUpdate = YES;	
	
	[self release];
}

#pragma mark Menu Delegates/Actions
/*!
 * @brief NSMenu delegate method
 *
 * This method updates all of the given menus which we control if we've deteremined an update to be necessary.
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	// Main menu if it needs an update
	if (menu == mainMenu && mainMenuNeedsUpdate) {
		NSMenuItem      *menuItem;
		
		//Clear out all the items, start from scratch
		[menu removeAllItems];
		
		// Show the contacts menu if we have any contacts to display
		if ([contactMenu.menu numberOfItems] > 0) {
			// Add contacts
			[menu addItem:self.contactsMenuItem];

		} else {
			[menu addItemWithTitle:[AILocalizedString(@"Contact List", nil) stringByAppendingEllipsis]
							target:adium.interfaceController
							action:@selector(toggleContactList:)
					 keyEquivalent:@""];
		}
		
		// If there's more than one account, show the accounts menu
		if ([accountMenuItemsArray count] > 1) {
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Accounts",nil)
																			target:self
																			action:nil
																	 keyEquivalent:@""];
			
			[menuItem setSubmenu:mainAccountsMenu];
			[menu addItem:menuItem];
			[menuItem release];
		}
		
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Options",nil)
																		target:self
																		action:nil
																 keyEquivalent:@""];
		[menuItem setSubmenu:mainOptionsMenu];
		[menu addItem:menuItem];
		[menuItem release];
		
		[menu addItem:[NSMenuItem separatorItem]];

		//Add the state menu items
		menuItem = nil;
		for (menuItem in stateMenuItemsArray) {
			[menu addItem:menuItem];
			
			//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
			if ([[menuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
				[[menuItem target] validateMenuItem:menuItem];
			}
		}

		//If there exist any open chats, add them
		if ([openChatsArray count] > 0) {
			//Add a seperator
			[menu addItem:[NSMenuItem separatorItem]];
			
			//Create and add the menu items
			for (AIChat *chat in openChatsArray) {
				NSImage *image = nil;
				//Create a menu item from the chat
				menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:chat.displayName
																				target:self
																				action:@selector(switchToChat:)
																		 keyEquivalent:@""];
				//Set the represented object
				[menuItem setRepresentedObject:chat];
				
				//Set the image
				
				//If there is a chat status image, use that
				image = [AIStatusIcons statusIconForChat:chat type:AIStatusIconMenu direction:AIIconNormal];
				//Otherwise use the chat's -chatMenuImage
				if (!image) {
					image = [chat chatMenuImage];
				}
				
				[menuItem setImage:image];
				
				//Add it to the menu
				[menu addItem:menuItem];
				[menuItem release];
			}
		}
		
		//Only update next time if we need to
		mainMenuNeedsUpdate = NO;
	// Accounts menu
	} else if (menu == mainAccountsMenu && accountsMenuNeedsUpdate) {
		NSMenuItem      *menuItem;
		
		[menu removeAllItems];
		
		[menu addItemWithTitle:[AILocalizedString(@"Account List", nil) stringByAppendingEllipsis]
									target:self
									action:@selector(activateAccountList:)
							 keyEquivalent:@""];
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		//Add the account menu items
		for (menuItem in accountMenuItemsArray) {
			NSMenu	*submenu;
			
			[menu addItem:menuItem];
			
			//Validate the menu items as they are added since they weren't previously validated when the menu was clicked
			if ([[menuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
				[[menuItem target] validateMenuItem:menuItem];
			}
			
			if ((submenu = [menuItem submenu])) {
				for (NSMenuItem *submenuItem in submenu.itemArray) {
					//Validate the submenu items as they are added since they weren't previously validated when the menu was clicked
					if ([[submenuItem target] respondsToSelector:@selector(validateMenuItem:)]) {
						[[submenuItem target] validateMenuItem:submenuItem];
					}
				}
			}
		}
		
		accountsMenuNeedsUpdate = NO;
	} else if (menu == mainOptionsMenu && optionsMenuNeedsUpdate) {
		[menu removeAllItems];
		
		[menu addItemWithTitle:[AILocalizedString(@"Adium Preferences", nil) stringByAppendingEllipsis]
						target:self
						action:@selector(showPreferenceWindow:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:AILocalizedString(@"Toggle Contact List", nil)
						target:adium.interfaceController
						action:@selector(toggleContactList:)
				 keyEquivalent:@""];
		
		[menu addItem:[NSMenuItem separatorItem]];

		[menu addItemWithTitle:AILocalizedString(@"Hide Status Item", nil)
						target:self
						action:@selector(disableStatusItem:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:AILocalizedString(@"Quit Adium", nil)
						target:NSApp
						action:@selector(terminate:)
				 keyEquivalent:@""];
		
		optionsMenuNeedsUpdate = NO;
	}
}

/*!
 * @brief Switch to a chat
 * @arg An NSMenuItem instance whose \c representedObject is an AIChat.
 */
- (void)switchToChat:(id)sender
{
	[adium.interfaceController setActiveChat:[sender representedObject]];
	[self activateAdium];
}

/*!
 * @brief Open the account list
 */
- (void)activateAccountList:(id)sender
{
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Accounts"];
	[self activateAdium];
}

/*!
 * @brief Disable the status item
 *
 * Updates the preference for displaying the status item to be NO.
 */
- (void)disableStatusItem:(id)sender
{
	[adium.preferenceController setPreference:[NSNumber numberWithBool:NO]
										 forKey:KEY_STATUS_MENU_ITEM_ENABLED
										  group:PREF_GROUP_STATUS_MENU_ITEM];
}

/*!
 * @brief Show the preference window
 */
- (void)showPreferenceWindow:(id)sender
{
	[adium.preferenceController showPreferenceWindow:nil];
	[self activateAdium];
}

/*!
 * @brief Activate Adium
 * 
 * Brings Adium to front.
 */
- (void)activateAdium
{
	if (![NSApp isActive]) {
		[NSApp activateIgnoringOtherApps:YES];
		[NSApp arrangeInFront:nil];
	}
}

#pragma mark Preferences Observer
/*!
 * @brief Preferences observer
 *
 * Updates our display based on preference changes, such as the display of badges or the unread count being displayed.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) {
		showContactGroups = ![[prefDict objectForKey:KEY_HIDE_CONTACT_LIST_GROUPS] boolValue];
		[contactMenu rebuildMenu];
	}
	
	if ([group isEqualToString:PREF_GROUP_STATUS_MENU_ITEM]) {
		showUnreadCount = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_COUNT] boolValue];
		showBadge = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_BADGE] boolValue];
		flashUnviewed = [[prefDict objectForKey:KEY_STATUS_MENU_ITEM_FLASH] boolValue];
		
		[self updateMenuIcons];
		[self updateUnreadCount];
		[self updateStatusItemLength];
	}
	
	if ([group isEqualToString:PREF_GROUP_STATUS_PREFERENCES]) {
		showConversationCount = [[prefDict objectForKey:KEY_STATUS_CONVERSATION_COUNT] boolValue];
		
		[self updateUnreadCount];
	}
}

@end
