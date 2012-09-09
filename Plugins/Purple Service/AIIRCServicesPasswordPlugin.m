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

#import "AIIRCServicesPasswordPlugin.h"
#import "ESIRCAccount.h"
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIPasswordPromptController.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIChat.h>
#import <Adium/AIListObject.h>
#import <Adium/AIAccount.h>

@interface AIIRCServicesPasswordPlugin()
- (BOOL)message:(NSString *)message containsFragments:(NSArray *)fragments;
- (void)willReceiveContent:(NSNotification *)notification;
- (void)passwordReturned:(NSString *)inPassword returnCode:(AIPasswordPromptReturn)returnCode context:(NSDictionary *)inDict;
@end

@implementation AIIRCServicesPasswordPlugin
- (void)installPlugin
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(willReceiveContent:)
												 name:Content_WillReceiveContent
											   object:nil];
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Content handling
- (void)willReceiveContent:(NSNotification *)notification
{	
	AIContentObject		*contentObject = [[notification userInfo] objectForKey:@"Object"];
	
	if (![contentObject isKindOfClass:[AIContentMessage class]]) {
		return;
	}
	
	NSString *nick = contentObject.source.UID;
	NSString *server = contentObject.chat.account.host;
	NSString *identNick;

	BOOL validService = NO;
	AISpecialPasswordType serviceType;
	
	AIAccount *account = contentObject.chat.account;
	
	if ([nick isCaseInsensitivelyEqualToString:@"NickServ"]) {
		validService = YES;
		serviceType = AINickServPassword;
		identNick = account.displayName;
	} else if ([nick isCaseInsensitivelyEqualToString:@"Q"] && [server rangeOfString:@"quakenet" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		validService = YES;
		serviceType = AIQPassword;
		identNick = account.UID;
	} else if ([nick isCaseInsensitivelyEqualToString:@"X"] && [server rangeOfString:@"undernet" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		validService = YES;
		serviceType = AIXPassword;
		identNick = account.UID;
	} else if ([nick isCaseInsensitivelyEqualToString:@"AuthServ"] && [server rangeOfString:@"gamesurge" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		validService = YES;
		serviceType = AIAuthServPassword;
		identNick = account.UID;
	}

	if (validService) {
		NSString *message = contentObject.message.string;
		
		if([self message:message containsFragments:[NSArray arrayWithObjects:
													@"identify yourself",
													@"authentication required",
													@"nickname is registered",
													@"nickname is owned",
													@"nick is owned",
													@"nick belongs to another user",
													@"invalid password",
													@"incorrect password", nil]]) {
			
			[account setValue:nil forProperty:@"Identifying" notify:NotifyNever];
			
			AILogWithSignature(@"%@ received challenge from %@ :%@", account.displayName, nick, message);
			
			BOOL forcePrompt = [self message:message containsFragments:[NSArray arrayWithObjects:@"invalid", @"incorrect", nil]];
			[adium.accountController passwordForType:serviceType
										  forAccount:account
										promptOption:(forcePrompt ? AIPromptAlways : AIPromptAsNeeded)
												name:identNick
									 notifyingTarget:self
											selector:@selector(passwordReturned:returnCode:context:)
											 context:[NSDictionary dictionaryWithObjectsAndKeys:account, @"Account", identNick, @"Name", nil]];

			contentObject.displayContent = NO;
		} else if ([self message:message containsFragments:[NSArray arrayWithObjects:
															@"password accepted",
															@"you are now identified",
															@"you are now logged in",
															@"you are already logged in",
															@"authentication successful",
															@"i recognize you", nil]]) {
			if ([account boolValueForProperty:@"Identifying"]) {
				[account setValue:nil forProperty:@"Identifying" notify:NotifyNever];
				contentObject.displayContent = NO;
			}
		} else if ([self message:message containsFragments:[NSArray arrayWithObjects:
															@"before it is changed",
															@"changed in 60 seconds",
															@"Remember: Nobody from CService will ever ask you for your password, do NOT give out your password to anyone claiming to be CService.",
															@"you are seeking their assistance. See",
															@"REMINDER: Do not share your password with anyone. DALnet staff will not ask for your password unless",
															@"You have been invited to", nil]]) {
			contentObject.displayContent = NO;
		}
	}
}

- (BOOL)message:(NSString *)message containsFragments:(NSArray *)fragments
{
	for (NSString *fragment in fragments) {
		if ([message rangeOfString:fragment options:NSCaseInsensitiveSearch].location != NSNotFound) {
			return YES;
		}
	}
	
	return NO;
}

#pragma mark Password Return
- (void)passwordReturned:(NSString *)inPassword returnCode:(AIPasswordPromptReturn)returnCode context:(NSDictionary *)inDict
{
	ESIRCAccount *account = [inDict objectForKey:@"Account"];
	NSString	 *displayName = [inDict objectForKey:@"Name"];
	
	AILogWithSignature(@"%@ password returned with any: %d", displayName, inPassword.length > 0);
	
	if (inPassword && inPassword.length) {
		[account setValue:[NSNumber numberWithBool:YES] forProperty:@"Identifying" notify:NotifyNever];
		[(ESIRCAccount *)account identifyForName:displayName
										password:[inPassword stringByReplacingOccurrencesOfString:@" "
																					   withString:@""]];
	}
}

@end
