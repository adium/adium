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
#import "AISpecialPasswordPromptController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>

#define TITLE_IRC_SERVICE_PASSWORD		AILocalizedString(@"%@ Password", "%@ is the name of the authentication service.")

#define MESSAGE_IRC_SERVICE				AILocalizedString(@"Please enter your %@ password.", "%@ is the name of the authentication service.")

#define SPECIAL_ACCOUNT_PASSWORD_PROMPT @"AISpecialPasswordPrompt"

@interface AISpecialPasswordPromptController()
+ (NSString *)identifierForType:(AISpecialPasswordType)inType name:(NSString *)inName account:(AIAccount *)inAccount;
- (id)initWithWindowNibName:(NSString *)windowNibName 
				 forAccount:(AIAccount *)inAccount 
					   type:(AISpecialPasswordType)inType 
					   name:(NSString *)inName 
				   password:(NSString *)inPassword 
			notifyingTarget:(id)inTarget 
				   selector:(SEL)inSelector 
					context:(id)inContext;
@end

@implementation AISpecialPasswordPromptController

static NSMutableDictionary	*passwordPromptControllerDict = nil;

+ (NSString *)identifierForType:(AISpecialPasswordType)inType name:(NSString *)inName account:(AIAccount *)inAccount
{
	return [NSString stringWithFormat:@"%d.%@.%@", inType, inName, inAccount.internalObjectID];
}

+ (void)showPasswordPromptForType:(AISpecialPasswordType)inType
						  account:(AIAccount *)inAccount
							 name:(NSString *)inName
						 password:(NSString *)inPassword
				  notifyingTarget:(id)inTarget
						 selector:(SEL)inSelector
						  context:(id)inContext
{
	AISpecialPasswordPromptController	*controller = nil;
	NSString							*identifier = [AISpecialPasswordPromptController identifierForType:inType name:inName account:inAccount];
	
	if (!passwordPromptControllerDict) passwordPromptControllerDict = [[NSMutableDictionary alloc] init];
	
	if ((controller = [passwordPromptControllerDict objectForKey:identifier])) {
		//Update the existing controller for this account to have the new target, selector, and context
		[controller setTarget:inTarget selector:inSelector context:inContext];
		
	} else {
		// Do not trust the static analyzer, look at the superclass. This is not a leak.
		if ((controller = [[self alloc] initWithWindowNibName:SPECIAL_ACCOUNT_PASSWORD_PROMPT 
												   forAccount:inAccount 
														 type:inType
														 name:inName
													 password:inPassword
											  notifyingTarget:inTarget
													 selector:inSelector
													  context:inContext])) {
			[passwordPromptControllerDict setObject:controller
											 forKey:identifier];
		}	
	}
	
	//bring the window front
	[controller showWindowInFrontIfAllowed:YES];
}

- (id)initWithWindowNibName:(NSString *)windowNibName 
				 forAccount:(AIAccount *)inAccount 
					   type:(AISpecialPasswordType)inType 
					   name:(NSString *)inName 
				   password:(NSString *)inPassword 
			notifyingTarget:(id)inTarget 
				   selector:(SEL)inSelector 
					context:(id)inContext
{
    if ((self = [super initWithWindowNibName:windowNibName
									password:inPassword
							 notifyingTarget:inTarget
									selector:inSelector
									 context:inContext])) {
		account = inAccount;
		type = inType;
		name = inName;
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
	[super windowWillClose:sender];
	
	NSString	*identifier = [AISpecialPasswordPromptController identifierForType:type name:name account:account];
	
	[passwordPromptControllerDict removeObjectForKey:identifier];
}

/*!
 * @brief Window laoded
 *
 * Perform initial configuration
 */
- (void)windowDidLoad
{
	NSString *title = nil, *label = nil;
	
	switch (type) {
		case AINickServPassword:
			title = [NSString stringWithFormat:TITLE_IRC_SERVICE_PASSWORD, @"NickServ"];
			label = [NSString stringWithFormat:MESSAGE_IRC_SERVICE, @"NickServ"];
			break;
			
		case AIQPassword:
			title = [NSString stringWithFormat:TITLE_IRC_SERVICE_PASSWORD, @"Q"];
			label = [NSString stringWithFormat:MESSAGE_IRC_SERVICE, @"Q"];
			break;
			
		case AIXPassword:
			title = [NSString stringWithFormat:TITLE_IRC_SERVICE_PASSWORD, @"X"];
			label = [NSString stringWithFormat:MESSAGE_IRC_SERVICE, @"X"];
			break;
			
		case AIAuthServPassword:
			title = [NSString stringWithFormat:TITLE_IRC_SERVICE_PASSWORD, @"AuthServ"];
			label = [NSString stringWithFormat:MESSAGE_IRC_SERVICE, @"AuthServ"];
			break;
	}
	
	[[self window] setTitle:title];
	[label_pleaseEnter setStringValue:label];
	
	[label_server setStringValue:account.host];
	[label_username setStringValue:name];
	
	[imageView_service setImage:[AIServiceIcons serviceIconForService:account.service
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	
	[checkBox_savePassword setState:NSOnState];
	
	[super windowDidLoad];
}

- (void)savePassword:(NSString *)inPassword
{
	[adium.accountController setPassword:inPassword forType:type forAccount:account name:name];
}

@end
