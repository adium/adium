//
//  AISpecialPasswordPromptController.m
//  Adium
//
//  Created by Zachary West on 2009-03-28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccountControllerProtocol.h>
#import "AISpecialPasswordPromptController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>

#define TITLE_NICKSERV_PASSWORD		AILocalizedString(@"NickServ Password", nil)
#define TITLE_CHANSERV_PASSWORD		AILocalizedString(@"ChanServ Password", nil)

#define MESSAGE_NICKSERV			AILocalizedString(@"Please enter your NickServ password.", nil)
#define MESSAGE_CHANSERV			AILocalizedString(@"Please enter your ChanServ password.", nil)

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
		account = [inAccount retain];
		type = inType;
		name = [inName retain];
	}
	
    return self;
}

- (void)dealloc
{
	[account release];
	[name release];
	
	[super dealloc];
}

/*!
 * @brief Our window will close
 *
 * Remove this controller from our dictionary of controllers
 */
- (void)windowWillClose:(id)sender
{
	NSString	*identifier = [AISpecialPasswordPromptController identifierForType:type name:name account:account];
	
	[passwordPromptControllerDict removeObjectForKey:identifier];
	
	[super windowWillClose:sender];
}

/*!
 * @brief Window laoded
 *
 * Perform initial configuration
 */
- (void)windowDidLoad
{
	switch (type) {
		case AINickServPassword:
			[[self window] setTitle:TITLE_NICKSERV_PASSWORD];
			[label_pleaseEnter setStringValue:MESSAGE_NICKSERV];
			break;
			
		case AIChanServPassword:
			[[self window] setTitle:TITLE_CHANSERV_PASSWORD];
			[label_pleaseEnter setStringValue:MESSAGE_CHANSERV];
			break;
	}
	
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
