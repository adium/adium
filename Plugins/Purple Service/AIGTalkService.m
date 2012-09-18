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

#import "AIGTalkService.h"
#import "AIPurpleGTalkAccount.h"
#import "AIPurpleGTalkAccountViewController.h"
#import "AIPurpleGTalkJoinChatViewController.h"
#import "AIXMPPOAuthAccountViewController.h"

@implementation AIGTalkService

//Account Creation
- (Class)accountClass{
	return [AIPurpleGTalkAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [AIXMPPOAuthAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [AIPurpleGTalkJoinChatViewController joinChatView];
}


//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-jabber-gtalk";
}
- (NSString *)serviceID{
	return @"GTalk";
}
- (NSString *)shortDescription{
	return @"GTalk";
}
- (NSString *)longDescription{
	return @"Google Talk";
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"https://www.google.com/accounts/NewAccount", @"URL for Google signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"Sign up for Google", @"Text for Google sign up button");
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}
- (BOOL)caseSensitive{
	return NO;
}
- (BOOL)canRegisterNewAccounts{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}
/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@gmail.com","Sample name and server for new gmail accounts");
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"GTalk ID",nil); //Jabber ID
}

@end
