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
#import "DCPurpleMSNJoinChatViewController.h"
#import "ESPurpleMSNAccount.h"
#import "ESPurpleMSNAccountViewController.h"

@implementation ESMSNService

//Account Creation
- (Class)accountClass{
	return [ESPurpleMSNAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleMSNAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleMSNJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-MSN";
}
- (NSString *)serviceID{
	return @"MSN";
}
- (NSString *)serviceClass{
	return @"MSN";
}
- (NSString *)shortDescription{
	return @"MSN";
}
- (NSString *)longDescription{
	return @"MSN Messenger";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._-"];
}
- (NSUInteger)allowedLength{
	return 113;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"MSN Passport","");    //Sign-in name
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"http://www.passport.com/", @"URL for MSN signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"Sign up for Windows Live ID", @"Text for MSN sign up button");
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
	
	[adium.statusController registerStatus:STATUS_NAME_BRB
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BRB]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_BUSY
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_PHONE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_PHONE]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_LUNCH
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_LUNCH]
									  ofType:AIAwayStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];
	/*
	m = g_list_append(m, _("Available"));
	m = g_list_append(m, _("Away From Computer"));
	m = g_list_append(m, _("Be Right Back"));
	m = g_list_append(m, _("Busy"));
	m = g_list_append(m, _("On The Phone"));
	m = g_list_append(m, _("Out To Lunch"));
	m = g_list_append(m, _("Hidden"));
	 */
}

@end
