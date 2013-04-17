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

#import <Adium/AIStatusControllerProtocol.h>
#import "DCPurpleZephyrJoinChatViewController.h"
#import "ESPurpleZephyrAccount.h"
#import "ESPurpleZephyrAccountViewController.h"
#import "ESZephyrService.h"

@implementation ESZephyrService

//Account Creation
- (Class)accountClass{
	return [ESPurpleZephyrAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleZephyrAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleZephyrJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-zephyr";
}
- (NSString *)serviceID{
	return @"Zephyr";
}
- (NSString *)serviceClass{
	return @"Zephyr";
}
- (NSString *)shortDescription{
	return @"Zephyr";
}
- (NSString *)longDescription{
	return @"Zephyr";
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"http://trac.adium.im/wiki/Zephyr", @"URL for Zephyr signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"About Zephyr", @"Text for Zephyr sign up button");
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789._@-"];
}
- (NSUInteger)allowedLength{
	return 255;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceUnsupported;
}
- (BOOL)canCreateGroupChats{
	return YES;
}
//No need for a password for Zephyr accounts
- (BOOL)supportsPassword
{
	return NO;
}
- (void)registerStatuses{
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_AWAY
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];

	/*
		 m = g_list_append(m, _("Online"));
		 m = g_list_append(m, PURPLE_AWAY_CUSTOM);
		 m = g_list_append(m, _("Hidden"));
	 */
}
@end
