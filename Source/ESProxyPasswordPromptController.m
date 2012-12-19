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
#import "ESProxyPasswordPromptController.h"

#define PROXY_PASSWORD_PROMPT_NIB		@"ProxyPasswordPrompt"
#define	PROXY_PASSWORD_REQUIRED			AILocalizedString(@"Accessing Proxy","Proxy password prompt window title")

#define	NONE							AILocalizedString(@"<None>", "Placeholder shown when no information is available")

@interface ESProxyPasswordPromptController ()
- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
@end

@implementation ESProxyPasswordPromptController

static NSMutableDictionary	*proxyPasswordPromptControllerDict = nil;

+ (void)showPasswordPromptForProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	ESProxyPasswordPromptController		*controller = nil;
	NSString							*identifier = [NSString stringWithFormat:@"%@.%@.%p",inServer,inUserName,inTarget];
	
	if (!proxyPasswordPromptControllerDict) proxyPasswordPromptControllerDict = [[NSMutableDictionary alloc] init];
	
	if ((controller = [proxyPasswordPromptControllerDict objectForKey:identifier])) {
		//Update the existing controller for this account to have the new target, selector, and context
		[controller setTarget:inTarget selector:inSelector context:inContext];
		
	} else {
		// Do not trust the static analyzer, look at the superclass. This is not a leak.
		if ((controller = [[self alloc] initWithWindowNibName:PROXY_PASSWORD_PROMPT_NIB
											   forProxyServer:inServer
													 userName:inUserName
											  notifyingTarget:inTarget
													 selector:inSelector
													  context:inContext])) {
			[proxyPasswordPromptControllerDict setObject:controller
												  forKey:identifier];
		}
	}
	
    //bring the window front
	[controller showWindowInFrontIfAllowed:YES];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forProxyServer:(NSString *)inServer userName:(NSString *)inUserName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	if ((self = [super initWithWindowNibName:windowNibName password:nil notifyingTarget:inTarget selector:inSelector context:inContext])) {
		server   = inServer;
		userName = inUserName;
	}

	return self;
}

/*!
 * @brief Our window will close
 *
 * Remove this controller from our dictionary of controllers
 */
- (void)windowWillClose:(id)sender
{
	NSString	*identifier = [NSString stringWithFormat:@"%@.%@.%p",server,userName,target];

	[proxyPasswordPromptControllerDict removeObjectForKey:identifier];
	
	[super windowWillClose:sender];
}

- (void)windowDidLoad
{
	[[self window] setTitle:PROXY_PASSWORD_REQUIRED];

	[textField_server setStringValue:([server length] ? server : NONE)];
	[textField_userName setStringValue:([userName length] ? userName : NONE)];
	
	[super windowDidLoad];
}

/*!
 * @brief Not actually used... do we need this?
 */
- (NSString *)savedPasswordKey
{
	return @"SavedProxyPassword";
}

/*!
 * @brief Save a password; pass nil to forget the password
 *
 * Called with nil when Save Password becomes unchecked, or called with the password when it is checked as the window
 * closes after the user presses Okay.
 */
- (void)savePassword:(NSString *)inPassword
{
	[adium.accountController setPassword:inPassword forProxyServer:server userName:userName];
}


@end
