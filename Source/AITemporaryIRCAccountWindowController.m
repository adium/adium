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

#import "AITemporaryIRCAccountWindowController.h"

#import "AIEditAccountWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import "AIServiceMenu.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIStringFormatter.h>

@implementation AITemporaryIRCAccountWindowController

/*!
 * @brief Prompt for adding a new (temporary) IRC account after the user clicked an irc://-link.
 *
 * @param newChannel The channel part of the IRC link 
 * @param newServer The server part of the link
 * @param newPort The port number of the link, or -1 if no port number specified (will assume 6667)
 * @param newPassword The password part of the link. This is the password of the channel, _not_ the password of the account!
 */
- (id)initWithChannel:(NSString *)newChannel server:(NSString *)newServer port:(NSInteger)newPort andPassword:(NSString *)newPassword
{
	if((self = [super initWithWindowNibName:@"TemporaryIRCAccountWindow"])) {
		channel = [newChannel retain];
		server = [newServer retain];
		port = (newPort == -1 ? 6667 : newPort);
		password = [newPassword retain];
	}
	return self;
}

- (void)show
{
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)dealloc
{
	[channel release];
	[server release];
	[password release];
	
	[account release];
	
	[super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
	return @"TemporaryIRCAccountWindow";
}

- (void)awakeFromNib
{
	[[self window] setTitle:AILocalizedString(@"Connect Temporary IRC Account", nil)];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[textField_explanation setStringValue:[NSString stringWithFormat:AILocalizedString(@"You need to create a new IRC account to connect to irc://%@%@/%@:", nil),
										   server,
										   (port == 6667 ? @"" : [NSString stringWithFormat:@":%d", port]),
										   channel]];
	
	[textField_server setStringValue:server];
	
	[label_name setLocalizedString:AILocalizedString(@"Nickname:", "Name for IRC user names")];
	[label_server setLocalizedString:AILocalizedString(@"Server:", nil)];
	
	[button_okay setLocalizedString:AILocalizedString(@"Connect", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
	[button_advanced setLocalizedString:[AILocalizedString(@"Advanced", nil) stringByAppendingEllipsis]];
	
	[button_remember setLocalizedString:AILocalizedString(@"Remember this account", nil)];
	
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[self autorelease];
}

- (NSString *)UID
{
	NSString *UID = [textField_name stringValue];
	
	//Use the default user name if possible, if no UID is specified
	if (!UID || ![UID length]) UID = [[adium.accountController firstServiceWithServiceID:@"IRC"] defaultUserName];
	
	return UID;
}

- (NSString *)host
{
	NSString *host = [textField_server stringValue];
	
	//Use the supplied host if the text field is empty
	if (!host || ![host length]) host = server;
	
	return host;
}

- (AIAccount *)account
{
	if (!account) {
		account = [[adium.accountController createAccountWithService:[adium.accountController firstServiceWithServiceID:@"IRC"]
																 UID:self.UID] retain];
		
		[account setPreference:server forKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
	}
	
	return account;
}

- (IBAction)okay:(id)sender
{
	AIAccount	*theAccount = self.account;
	
	[account filterAndSetUID:self.UID];
	
	[theAccount setIsTemporary:([button_remember state] == NSOffState)];
	
	[theAccount setPreference:self.host
					   forKey:KEY_CONNECT_HOST
						group:GROUP_ACCOUNT_STATUS];
	
	[adium.accountController addAccount:theAccount];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(accountConnected:)
												 name:ACCOUNT_CONNECTED
											   object:theAccount];
	
	//Connect the account
	[theAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	
	[button_okay setEnabled:FALSE];
}

- (IBAction)displayAdvanced:(id)sender
{
	if (![account.UID isEqualToString:self.UID]) {
		[account filterAndSetUID:self.UID];
	}
	
	if (![account.host isEqualToString:self.host]) {
		[account setPreference:self.host
						   forKey:KEY_CONNECT_HOST
							group:GROUP_ACCOUNT_STATUS];
	}
	
	AIEditAccountWindowController *editAccountWindowController = [[AIEditAccountWindowController alloc] initWithAccount:self.account
																										notifyingTarget:self];
	[editAccountWindowController showOnWindow:[self window]];
}

- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)inSuccess
{
	//If the AIEditAccountWindowController changes the account object, update to follow suit
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
	}
	
	//Make sure our UID is still accurate
	if (![inAccount.UID isEqualToString:self.UID]) {
		[textField_name setStringValue:inAccount.UID];
	}
	
	if (![inAccount.host isEqualToString:[self host]]) {
		[textField_server setStringValue:inAccount.host];
	}
}

- (void)accountConnected:(NSNotification *)not
{
	[adium.chatController chatWithName:channel
							identifier:nil
							 onAccount:account
					  chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										channel, @"channel",
										password, @"password", /* may be nil, so should be last */
										nil]];
	
	[[self window] performClose:nil];
}

@end
