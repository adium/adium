//
//  AISocialNetworkingStatusMenu.m
//  Adium
//
//  Created by Evan Schoenberg on 6/7/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import "AISocialNetworkingStatusMenu.h"
#import "AICustomSocialNetworkingStatusWindowController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation AISocialNetworkingStatusMenu

+ (NSMenu *)socialNetworkingSubmenuForAccount:(AIAccount *)inAccount
{
	NSMenu *menu = [[NSMenu alloc] init];

	[menu addItemWithTitle:AILocalizedString(@"Set to Current Adium Status", nil)
					target:self
					action:@selector(setToCurrentAdiumStatus:)
			 keyEquivalent:@""
		 representedObject:inAccount];

	[menu addItemWithTitle:[AILocalizedString(@"Custom", nil) stringByAppendingEllipsis]
					target:self
					action:@selector(showCustomSocialNetworkingStatusWindow:)
			 keyEquivalent:@""
		 representedObject:inAccount];
	
	return [menu autorelease];
}

+ (NSMenuItem *)socialNetworkingSubmenuItem
{
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Social Networking", nil)
													  target:nil
													  action:NULL
											   keyEquivalent:@""];
	[menuItem setSubmenu:[self socialNetworkingSubmenuForAccount:nil]];

	return [menuItem autorelease];	
}

+ (void)showCustomSocialNetworkingStatusWindow:(NSMenuItem *)sender
{
	AIAccount *account = [sender representedObject];
	NSAttributedString *currentStatusMessage = (account ?
												account.statusMessage :
												[adium.statusController.activeStatusState statusMessage]);

	[AICustomSocialNetworkingStatusWindowController showCustomSocialNetworkingStatusWindowWithInitialMessage:currentStatusMessage
																								  forAccount:account
																							 notifyingTarget:self];

}

+ (void)gotFilteredSocialNetworkingStatus:(NSAttributedString *)inStatusMessage context:(AIAccount *)inAccount
{
	if (inAccount)
		[inAccount setSocialNetworkingStatusMessage:inStatusMessage];
	else {
		for (AIAccount *account in adium.accountController.accounts) {
			if ([account.service isSocialNetworkingService] && account.online)
				[account setSocialNetworkingStatusMessage:inStatusMessage];
		}
	}
}

+ (void)setSocialNetworkingStatus:(NSAttributedString *)inStatusMessage forAccount:(AIAccount *)inAccount
{
	//Filter the content
	[adium.contentController filterAttributedString:inStatusMessage
															   usingFilterType:AIFilterContent
																	 direction:AIFilterOutgoing
																 filterContext:self
															   notifyingTarget:self
																	  selector:@selector(gotFilteredSocialNetworkingStatus:context:)
																	   context:inAccount];
}

+ (void)setToCurrentAdiumStatus:(NSMenuItem *)sender
{
	AIAccount *account = [sender representedObject];
	NSAttributedString *currentStatusMessage = [adium.statusController.activeStatusState statusMessage];

	[self setSocialNetworkingStatus:currentStatusMessage
						 forAccount:account];
}

@end
