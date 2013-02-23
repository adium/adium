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

#import "ESAIMService.h"
#import "ESPurpleAIMAccount.h"
#import "AIPurpleAIMAccountViewController.h"

@implementation ESAIMService
//Account Creation
- (AIAccountViewController *)accountViewController{
    return [AIPurpleAIMAccountViewController accountViewController];
}

//Service Description
- (Class)accountClass{
	return [ESPurpleAIMAccount class];
}

- (NSString *)serviceCodeUniqueID{
	return @"libpurple-oscar-AIM";
}
- (NSString *)serviceID{
	return @"AIM";
}
- (NSString *)shortDescription{
	return @"AIM";
}
- (NSString *)longDescription{
	return @"AOL Instant Messenger";
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}
- (BOOL)canCreateGroupChats{
	return YES;
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"Screen Name",nil); //ScreenName
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"https://new.aol.com/", @"URL for AIM signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"Sign up for AIM", @"Text for AIM sign up button");
}

@end
