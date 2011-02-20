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

#import "AISocialNetworkingStatusMenu.h"
#import "AICustomSocialNetworkingStatusWindowController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AISocialNetworkingStatusMenu ()
+ (void)setToCurrentAdiumStatus:(NSMenuItem *)sender;
+ (void)showCustomSocialNetworkingStatusWindow:(NSMenuItem *)sender;
@end

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
