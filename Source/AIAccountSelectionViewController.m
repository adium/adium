//
//  AIAccountSelectionViewController.m
//  Adium
//
//  Created by Thijs Alkemade on 20-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import <Adium/AIAccountControllerProtocol.h>
#import "AIAccountSelectionView.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import "AIAccountSelectionViewController.h"
#import "AIMessageViewController.h"

@interface AIAccountSelectionViewController ()
- (void)chatStatusChanged:(NSNotification *)notification;
@end

@implementation AIAccountSelectionViewController

- (id)init
{
    self = [super initWithNibName:@"AIAccountSelectionTopBar" bundle:[NSBundle bundleForClass:[AIAccountSelectionViewController class]]];
    if (self) {
        [self loadView];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [accountMenu release];
    [contactMenu release];
    [chat release];
    
    [super dealloc];
}

- (void)setChat:(AIChat *)inChat
{
    if(chat != inChat){
		if(chat) {
			//Stop observing the existing chat
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_SourceChanged object:chat];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_DestinationChanged object:chat];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Interface_DidSendEnteredMessage object:chat];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_StatusChanged object:chat];
			
			//Release it
			[chat release]; chat = nil;
		}
        
		if(inChat){
			//Retain the new chat
			chat = [inChat retain];
			
			//Observe changes to this chat's source and destination
			[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(chatSourceChanged:)
                                                         name:Chat_SourceChanged
                                                       object:chat];
			[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(chatDestinationChanged:)
                                                         name:Chat_DestinationChanged
                                                       object:chat];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didSendMessage:)
                                                         name:Interface_DidSendEnteredMessage
                                                       object:chat];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(chatStatusChanged:)
                                                         name:Chat_StatusChanged
                                                       object:chat];
			
			//Update source and destination menus
			[self configureForCurrentChat];
		}			
	} else {
		[self configureForCurrentChat];
	}
}

/*!
 * @brief Invoked when the status of our chat changes
 *
 * The only chat status change we're interested in is one to the disallow account switching flag.  When this flag
 * changes we update the visibility of our account status menus accordingly.
 */
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];
	
    if (notification == nil || [modifiedKeys containsObject:@"DisallowAccountSwitching"]) {
		[self configureForCurrentChat];
    }
}

- (void)didSendMessage:(id)sender
{
    [owner hideTopBarController:self];
}

- (void)_reframe
{
    if (!choicesForAccount && !choicesForContact) {
        [owner hideTopBarController:self];
        return;
    }
    
    [owner unhideTopBarController:self];
    
    [self.view setFrameSize:NSMakeSize(NSWidth(self.view.superview.frame), 30 * ((choicesForAccount ? 1 : 0) + (choicesForContact ? 1 : 0)))];
    [view_backgroundView setBoundsOrigin:NSMakePoint(0.0f, choicesForContact ? 0.0f : -30.0f)];
    
    [owner didResizeTopbarController:self];
}

/*!
 * @brief Build and configure all menus for the current chat
 */
- (void)configureForCurrentChat
{
	AILogWithSignature(@"");
    
    // Rebuild 'To' contact menu
    choicesForContact = [self choicesAvailableForContact];
    if (choicesForContact) {
		[self _createContactMenu];
	}
    
    [self _reframe];
    
	//Update our 'From' account menu
	[self chatDestinationChanged:nil];
}


/*!
 * @brief Update our menus when the destination contact changes
 */
- (void)chatDestinationChanged:(NSNotification *)notification
{
	AILogWithSignature(@"popUp_contacts selecting %@ (%@)", chat.listObject, [notification object]);
    
	//Update selection in contact menu
	[popUp_contacts selectItemWithRepresentedObjectUsingCompare:chat.listObject];
    
	//Rebuild 'From' account menu
	choicesForAccount = [self choicesAvailableForAccount];
    if (choicesForAccount) {
		[self configureAccountMenu];
	}
    
    [self _reframe];

	//Update selection in account menu
	[self chatSourceChanged:nil];
}

/*!
 * @brief Update our menus when the source account changes
 */
- (void)chatSourceChanged:(NSNotification *)notification
{
	//Update selection in account menu
	AILogWithSignature(@"popUp_accounts selecting %@ (%@)", chat.account,  [notification object]);
	[popUp_accounts selectItemWithRepresentedObject:chat.account];
}

//Account Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account Menu
/*!
 * @brief Returns YES if a choice of source account is available
 */
- (BOOL)choicesAvailableForAccount
{
	NSInteger		choices = 0;
    
	for (AIAccount *account in adium.accountController.accounts) {
		if ([self _accountIsAvailable:account]) {
			if (++choices > 1) return YES;
		}
	}
	
	return NO;
}

- (void)rebuildAccountMenuFromMenuItems:(NSArray *)menuItems
{
	NSMenuItem	 *menuItem;
	NSMutableArray *menuItemsForAccountsWhichKnow = [NSMutableArray array];
	NSMutableArray *menuItemsForAccountsWhichDoNotKnow = [NSMutableArray array];
	
	for (menuItem in menuItems) {
		AIAccount *account = [menuItem representedObject];
		AIListContact *listContact = [adium.contactController existingContactWithService:chat.listObject.service
																				 account:account
																					 UID:chat.listObject.UID];
        
		if (!listContact || listContact.isStranger)
			[menuItemsForAccountsWhichDoNotKnow addObject:menuItem];
		else
			[menuItemsForAccountsWhichKnow addObject:menuItem];
	}
	
	NSMenu *menu = [[NSMenu alloc] init];
    
	//First, add items for accounts which have the current contact on their contact lists
	for (menuItem in menuItemsForAccountsWhichKnow) {
		[menu addItem:menuItem];
	}
	
	//If we added any items and will be adding more, put in a separator
	if ([menu numberOfItems] && [menuItemsForAccountsWhichDoNotKnow count]) [menu addItem:[NSMenuItem separatorItem]];
    
	//Finally, add items for accounts which are on the right service but don't know about this contact
	for (menuItem in menuItemsForAccountsWhichDoNotKnow) {
		[menu addItem:menuItem];
	}
    
	[popUp_accounts setMenu:menu];
	[menu release];
}

/*!
 * @brief Account Menu Delegate
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[self rebuildAccountMenuFromMenuItems:menuItems];
}
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[adium.chatController switchChat:chat toAccount:inAccount];
}
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount {
	return [self _accountIsAvailable:inAccount];
}
- (NSControlSize)controlSizeForAccountMenu:(AIAccountMenu *)inAccountMenu;
{
	return NSRegularControlSize;
}

/*!
 * @brief Check if an account is available for sending content
 *
 * An account is considered available if it's of the right service class and is currently online.
 * @param inAccount AIAccount instance to check
 * @return YES if the account is available
 */
- (BOOL)_accountIsAvailable:(AIAccount *)inAccount
{
	return [chat.listObject.service.serviceClass isEqualToString:inAccount.service.serviceClass] && inAccount.online;
}

/*!
 * @brief Create the account menu and add it to our view
 */
- (void)configureAccountMenu
{
	[label_accounts setStringValue:AILocalizedString(@"From:", "Label in front of the dropdown of accounts from which to send a message")];
    
	//Configure the contact menu
	if (accountMenu)
		[accountMenu rebuildMenu];
	else
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountNoSubmenu showTitleVerbs:NO] retain];
}

//Contact Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact Menu
/*!
 * @brief Returns YES if a choice of destination contact is available
 */
- (BOOL)choicesAvailableForContact {
	if (chat.listObject.metaContact)
		return chat.listObject.metaContact.uniqueContainedObjects.count > 1;
	
	return NO;
}

/*!
 * @brief Contact menu delegate
 */
- (void)contactMenuDidRebuild:(AIContactMenu *)inContactMenu {
	AILogWithSignature(@"");
	[popUp_contacts setMenu:[inContactMenu menu]];
	[self chatDestinationChanged:nil];
}
- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact {
	[adium.chatController switchChat:chat toListContact:inContact usingContactAccount:YES];
}
- (AIListContact *)contactMenu:(AIContactMenu *)inContactMenu validateContact:(AIListContact *)inContact {
	AIListContact *preferredContact = [adium.contactController preferredContactForContentType:CONTENT_MESSAGE_TYPE
                                                                               forListContact:inContact];
	return (preferredContact ? preferredContact : inContact);
}
/*!
 * @brief Create the contact menu and add it to our view
 */
- (void)_createContactMenu
{    
	[label_contacts setStringValue:AILocalizedString(@"To:", "Label in front of the dropdown for picking which contact to send a message to in the message window")];
    
	//Configure the contact menu
	if (contactMenu)
		[contactMenu rebuildMenu];
	else
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self forContactsInObject:chat.listObject.parentContact] retain];
}

@end
