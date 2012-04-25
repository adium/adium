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
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AILocalizationButton.h>
#import <Adium/AIService.h>
#import <Adium/DCJoinChatViewController.h>
#import <Adium/DCJoinChatWindowController.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

#define JOIN_CHAT_NIB		@"JoinChatWindow"

@interface DCJoinChatWindowController ()

- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)windowDidLoad;
- (void)_selectPreferredAccountInAccountMenu:(AIAccountMenu *)inAccountMenu;

@end

@implementation DCJoinChatWindowController

@synthesize joinChatViewController;

static DCJoinChatWindowController *sharedJoinChatInstance = nil;

// Create a new join chat window
+ (DCJoinChatWindowController *)showJoinChatWindow
{
    if (!sharedJoinChatInstance) {
        sharedJoinChatInstance = [[self alloc] initWithWindowNibName:JOIN_CHAT_NIB];
    }

    [[sharedJoinChatInstance window] makeKeyAndOrderFront:nil];
    return sharedJoinChatInstance;
}

+ (void)closeSharedInstance
{
    if (sharedJoinChatInstance) {
        [sharedJoinChatInstance closeWindow:nil];
    }
}

- (IBAction)joinChat:(id)sender
{
	// If there is a controller, it handles all of the join-chat work
	if (self.joinChatViewController) {
		[self.joinChatViewController joinChatWithAccount:[[popUp_service selectedItem] representedObject]];
	}
	
	[self closeWindow:nil];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	NSRect 	windowFrame = [[self window] frame];
	CGFloat		diff;

	// Remove the previous view controller's view
	[[self.joinChatViewController view] removeFromSuperview];

	// Get a view controller for this account if there is one
	self.joinChatViewController = [inAccount.service joinChatView];
	NSView *currentView = [self.joinChatViewController view];
	[self.joinChatViewController setDelegate:self];
	[self.joinChatViewController setSharedChatInstance:self];

	// Resize the window to fit the new view
	diff = NSHeight([view_customView frame]) - NSHeight([currentView frame]);
	windowFrame.size.height -= diff;
	windowFrame.origin.y += diff;

	diff = NSWidth([view_customView frame]) - NSWidth([currentView frame]);
	windowFrame.size.width -= diff;

	[[self window] setFrame:windowFrame display:YES animate:YES];

	if (self.joinChatViewController && currentView) {
		[view_customView addSubview:currentView];
		[self.joinChatViewController configureForAccount:inAccount];
	}

    [popUp_service selectItemWithRepresentedObject:inAccount];

	if ([[self window] respondsToSelector:@selector(recalculateKeyViewLoop)]) {
		[[self window] recalculateKeyViewLoop];
	}
}

// Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		self.joinChatViewController = nil;
	}

    return self;
}

- (void)dealloc
{
	self.joinChatViewController = nil;
	
	[super dealloc];
}

// Setup the window before it is displayed
- (void)windowDidLoad
{
	// Localized strings
	[[self window] setTitle:AILocalizedString(@"Join Chat", nil)];
	[label_account setLocalizedString:AILocalizedString(@"Account:", nil)];

	[button_joinChat setLocalizedString:AILocalizedString(@"Join", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];

	// Account menu
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO] retain];

	[self configureForAccount:[[popUp_service selectedItem] representedObject]];

    // Center the window
    [[self window] center];
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	sharedJoinChatInstance = nil;
	[accountMenu release]; accountMenu = nil;
    [self autorelease]; //Close the shared instance
}

#pragma mark DCJoinChatViewController delegate

- (void)setJoinChatEnabled:(BOOL)enabled
{
	[button_joinChat setEnabled:enabled];
}

- (AIListContact *)contactFromText:(NSString *)text
{
	AIListContact	*contact;
	AIAccount		*account;
	NSString		*UID;
	
	// Get the service type and UID
	account = [[popUp_service selectedItem] representedObject];
	UID = [account.service normalizeUID:text removeIgnoredCharacters:YES];
	
	// Find the contact
	contact = [adium.contactController contactWithService:account.service
													account:account 
														UID:UID];
	
	return contact;
}

#pragma mark Account Menu

// Account menu delegate
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_service setMenu:[inAccountMenu menu]];
	[self _selectPreferredAccountInAccountMenu:inAccountMenu];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	[self configureForAccount:inAccount];
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return inAccount.online && [inAccount.service canCreateGroupChats];
}

// Select the last used account / Available online account
- (void)_selectPreferredAccountInAccountMenu:(AIAccountMenu *)inAccountMenu
{
	if ([popUp_service numberOfItems]) {
		// First online account in our list
		AIAccount    *preferredAccount;

		for (preferredAccount in adium.accountController.accounts) {
			if (preferredAccount.online) {
				break;
			}
		}
		
		NSMenuItem	*menuItem = [inAccountMenu menuItemForAccount:preferredAccount];

		AILog(@"%@: _selectPreferredAccountInAccountMenu: %@: menuItem for %@ is %@",self,inAccountMenu,preferredAccount,menuItem);

		if (menuItem) {
			[popUp_service selectItem:menuItem];
			[self configureForAccount:preferredAccount];
		}
	}
}

@end
