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
#import <PSMTabBarControl/NSBezierPath_AMShading.h>

#define BOX_RECT	NSMakeRect(0, 0, 300, 28)
#define LABEL_RECT	NSMakeRect(17, 7, 56, 17)
#define POPUP_RECT	NSMakeRect(75, 1, 212, 26)

@interface AIAccountSelectionView ()
- (id)_init;
- (void)configureForCurrentChat;
- (void)chatDestinationChanged:(NSNotification *)notification;
- (void)chatSourceChanged:(NSNotification *)notification;
- (BOOL)_accountIsAvailable:(AIAccount *)inAccount;
- (void)configureAccountMenu;
- (void)_createContactMenu;
- (void)_destroyAccountMenu;
- (void)_destroyContactMenu;
- (BOOL)choicesAvailableForAccount;
- (BOOL)choicesAvailableForContact;
- (NSTextField *)_textFieldLabelWithValue:(NSString *)inValue frame:(NSRect)inFrame;
- (NSPopUpButton *)_popUpButtonWithFrame:(NSRect)inFrame;
- (NSView *)_boxWithFrame:(NSRect)inFrame;
- (void)_repositionMenusAndResize;
@end

/*!
 * @class AIAccountSelectionView
 * @brief A view for picking the destination (contact) and source (account) for a chat.
 *
 * This view manages data, as well, MVC be damned.
 *
 * The To: field, display first, is the indepdenent variable.  It shows all contacts within the selected metacontact, or shows nothing
 * if a normal contact is the chat's destination.
 *
 * The From: field is the dependent variable. It shows all accounts which could message the selected contact.
 */
@implementation AIAccountSelectionView

/*!
 * @brief InitWithCoder
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if((self = [super initWithCoder:aDecoder])) {
		[self _init];
	}
	return self;
}

/*!
 * @brief InitWithFrame
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		[self _init];
	}
	return self;
}

/*!
 * @brief Common init
 */
- (id)_init
{
	return self;
}

- (void)dealloc
{
	[self setChat:nil];

	[leftColor release];
	[rightColor release];
	[super dealloc];
}

- (void)setLeftColor:(NSColor *)inLeftColor rightColor:(NSColor *)inRightColor
{
	if (leftColor != inLeftColor) {
		[leftColor release];
		leftColor = [inLeftColor retain];
	}
	
	if (rightColor != inRightColor) {
		[rightColor release];
		rightColor = [inRightColor retain];
	}
	
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)aRect
{	
	if (rightColor && leftColor) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self bounds]];
		[path linearVerticalGradientFillWithStartColor:leftColor 
											  endColor:rightColor];
	}
}

#pragma mark Chat
/*!
 * @brief Set the chat associated with this selection view
 *
 * @param inChat AIChat instance this view representents
 */
- (void)setChat:(AIChat *)inChat
{
	if(chat != inChat){
		if(chat){
			//Stop observing the existing chat
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_SourceChanged object:chat];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_DestinationChanged object:chat];

			//Remove our menus
			[self _destroyAccountMenu];
			[self _destroyContactMenu];
			
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
			
			//Update source and destination menus
			[self configureForCurrentChat];
		}			
	} else {
		[self configureForCurrentChat];
	}
}

/*!
 * @brief Build and configure all menus for the current chat
 */
- (void)configureForCurrentChat
{
	AILogWithSignature(@"");

	//Rebuild 'To' contact menu
	if ([self choicesAvailableForContact]) {
		[self _createContactMenu];
	} else {
		[self _destroyContactMenu];
	}

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
	if ([self choicesAvailableForAccount]){
		[self configureAccountMenu];
	} else {
		[self _destroyAccountMenu];	
	}

	//Reposition our menus and resize as necessary
	[self _repositionMenusAndResize];

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

/*!
 * @brief Reposition our menus and resize the account selection view as necessary
 *
 * Invoke this method after the visibility of either menu has changed.
 */
- (void)_repositionMenusAndResize
{
	NSInteger		newHeight = 0;
	NSRect	oldFrame = [self frame];
	
	//Account menu is always at the bottom
	if(box_accounts){
		[box_accounts setFrameOrigin:NSMakePoint(0, 0)];
		newHeight += [box_accounts frame].size.height;
	}

	//Contact menu is at the bottom, unless the account menu is present in which case it moves up
	if(box_contacts){
		[box_contacts setFrameOrigin:NSMakePoint(0, (box_accounts ? [box_accounts frame].size.height : 0))];
		newHeight += [box_contacts frame].size.height;
	}

	//Resize our view to fit whichever menus are visible
	[self setFrameSize:NSMakeSize([self frame].size.width, newHeight)];
	[[self superview] setNeedsDisplayInRect:NSUnionRect(oldFrame,[self frame])];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIViewFrameDidChangeNotification object:self];
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
	[box_accounts removeFromSuperview]; [box_accounts release];
	box_accounts = [[self _boxWithFrame:BOX_RECT] retain];
	
	[popUp_accounts release];
	popUp_accounts = [[self _popUpButtonWithFrame:POPUP_RECT] retain];
	[box_accounts addSubview:popUp_accounts];
	
	NSTextField *label_accounts = [self _textFieldLabelWithValue:AILocalizedString(@"From:", "Label in front of the dropdown of accounts from which to send a message")
														   frame:LABEL_RECT];
	[box_accounts addSubview:label_accounts];

	//Resize the contact box to fit our view and insert it
	[box_accounts setFrameSize:NSMakeSize(NSWidth([self frame]), NSHeight(BOX_RECT))];
	[self addSubview:box_accounts];

	//Configure the contact menu
	if (accountMenu)
		[accountMenu rebuildMenu];
	else
		accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountNoSubmenu showTitleVerbs:NO] retain];
}

/*!
 * @brief Destroy the account menu, removing it from our view
 */
- (void)_destroyAccountMenu
{
	if (popUp_accounts) {
		[box_accounts removeFromSuperview];
		[popUp_accounts release]; popUp_accounts = nil;
		[box_accounts release]; box_accounts = nil;
		[accountMenu release]; accountMenu = nil;
	}
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
	[box_contacts removeFromSuperview]; [box_contacts release];
	box_contacts = [[self _boxWithFrame:BOX_RECT] retain];

	[popUp_contacts release];
	popUp_contacts = [[self _popUpButtonWithFrame:POPUP_RECT] retain];
	[box_contacts addSubview:popUp_contacts];
		
	NSTextField *label_contacts = [self _textFieldLabelWithValue:AILocalizedString(@"To:", "Label in front of the dropdown for picking which contact to send a message to in the message window") frame:LABEL_RECT];
	[box_contacts addSubview:label_contacts];

	//Resize the contact box to fit our view and insert it
	[box_contacts setFrameSize:NSMakeSize(NSWidth([self frame]), NSHeight(BOX_RECT))];
	[self addSubview:box_contacts];

	//Configure the contact menu
	if (contactMenu)
		[contactMenu rebuildMenu];
	else
		contactMenu = [[AIContactMenu contactMenuWithDelegate:self forContactsInObject:chat.listObject.parentContact] retain];
}

/*!
 * @brief Destroy the contact menu, remove it from our view
 */
- (void)_destroyContactMenu
{
	if(popUp_contacts){
		[box_contacts removeFromSuperview];
		[box_contacts release]; box_contacts = nil;
		[popUp_contacts release]; popUp_contacts = nil;
		[contactMenu release]; contactMenu = nil;
	}
}


//Misc -----------------------------------------------------------------------------------------------------------------
#pragma mark Misc
/*!
 * @brief
 */
- (NSTextField *)_textFieldLabelWithValue:(NSString *)inValue frame:(NSRect)inFrame
{
	NSTextField *label = [[NSTextField alloc] initWithFrame:inFrame];

	[label setStringValue:inValue];
	[label setEditable:NO];
	[label setSelectable:NO];
	[label setBordered:NO];
	[label setDrawsBackground:NO];
	[label setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
	[label setAlignment:NSRightTextAlignment];

	return [label autorelease];
}

/*!
 * @brief
 */
- (NSPopUpButton *)_popUpButtonWithFrame:(NSRect)inFrame
{
	NSPopUpButton *popUp = [[NSPopUpButton alloc] initWithFrame:inFrame];

	[popUp setAutoresizingMask:(NSViewWidthSizable)];

	/* If we don't explicitly set the font of the pop-up button
	 * menu items without a font of their own get displayed at 14 pt (as of Mac OS X 10.4.10)
	 * which is too big the text gets clipped.
	 *
	 * If you uncomment this line, you can notice this problem in descenders
	 * (such as that of the letter 'g') in the recipient pop-up.
	 */
	[popUp setFont:[NSFont systemFontOfSize:0.0f]];
	
	return [popUp autorelease];
}

/*!
 * @brief
 */
- (NSView *)_boxWithFrame:(NSRect)inFrame
{
	NSView	*box = [[NSView alloc] initWithFrame:inFrame];

	[box setAutoresizingMask:(NSViewWidthSizable)];
	
	return [box autorelease];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@{%@}",[super description], chat];
}

@end
