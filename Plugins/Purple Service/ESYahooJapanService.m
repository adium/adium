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

#import "DCPurpleYahooJoinChatViewController.h"
#import "ESPurpleYahooAccountViewController.h"
#import "ESPurpleYahooJapanAccount.h"
#import "ESYahooJapanService.h"

@implementation ESYahooJapanService

//Account Creation
- (Class)accountClass{
	return [ESPurpleYahooJapanAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleYahooAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleYahooJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-Yahoo!-Japan";
}
- (NSString *)serviceID{
	return @"Yahoo! Japan";
}
- (NSString *)serviceClass{
	return @"Yahoo! Japan";
}
- (NSString *)shortDescription{
	return @"Yahoo! Japan";
}
- (NSString *)longDescription{
	return @"Yahoo! Japan";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789_@.-"];
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"https://account.edit.yahoo.co.jp/registration", @"URL for Yahoo! Japan signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"Sign up for Yahoo! Japan", @"Text for Yahoo! Japan sign up button");
}

@end
