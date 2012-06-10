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
#import "ESAccountPasswordPromptController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>

#define ACCOUNT_PASSWORD_PROMPT_NIB		@"PasswordPrompt"
#define	ACCOUNT_PASSWORD_REQUIRED		AILocalizedString(@"Connecting Account","Password prompt window title")

@interface ESAccountPasswordPromptController ()
- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount password:(NSString *)password notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
@end

/*!
 * @class ESAccountPasswordPromptController
 * @brief Account password prompt window controller
 * 
 * This AIPasswordPromptController subclass is responsible for requesting an account's password from the user when it
 * attempts to connect and the password isn't saved.  The user has the option of saving the password for future use.
 *
 * Only one password prompt window per account is shown; an attempt to show a prompt for an account which already has
 * an open account results in the existing account becoming key and front.
 */
@implementation ESAccountPasswordPromptController

static NSMutableDictionary	*passwordPromptControllerDict = nil;

+ (void)showPasswordPromptForAccount:(AIAccount *)inAccount password:(NSString *)inPassword notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{	
	ESAccountPasswordPromptController	*controller = nil;
	NSString							*identifier = inAccount.internalObjectID;
	
	if (!passwordPromptControllerDict) passwordPromptControllerDict = [[NSMutableDictionary alloc] init];
	
	if ((controller = [passwordPromptControllerDict objectForKey:identifier])) {
		//Update the existing controller for this account to have the new target, selector, and context
		[controller setTarget:inTarget selector:inSelector context:inContext];

	} else {
		// Do not trust the static analyzer, look at the superclass. This is not a leak.
		if ((controller = [[self alloc] initWithWindowNibName:ACCOUNT_PASSWORD_PROMPT_NIB 
												   forAccount:inAccount 
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

- (id)initWithWindowNibName:(NSString *)windowNibName forAccount:(AIAccount *)inAccount password:(NSString *)inPassword notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    if ((self = [super initWithWindowNibName:windowNibName
									password:inPassword
							 notifyingTarget:inTarget
									selector:inSelector
									 context:inContext])) {
		account = inAccount;
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

	NSString	*identifier = account.internalObjectID;

	[passwordPromptControllerDict removeObjectForKey:identifier];
}

/*!
 * @brief Window laoded
 *
 * Perform initial configuration
 */
- (void)windowDidLoad
{
	[[self window] setTitle:ACCOUNT_PASSWORD_REQUIRED];
	
    [textField_account setStringValue:account.formattedUID];
	[imageView_service setImage:[AIServiceIcons serviceIconForService:account.service
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	
	[checkBox_savePassword setState:[[account preferenceForKey:[self savedPasswordKey] 
														 group:GROUP_ACCOUNT_STATUS] boolValue]];

	[super windowDidLoad];
}

/*!
 * @brief The key 
 */
- (NSString *)savedPasswordKey
{
	return @"SavedPassword";
}

//Save a password; pass nil to forget the password
- (void)savePassword:(NSString *)inPassword
{
	if (inPassword) {
		[adium.accountController setPassword:inPassword forAccount:account];	
	} else {
		[adium.accountController forgetPasswordForAccount:account];	
	}
}

@end
