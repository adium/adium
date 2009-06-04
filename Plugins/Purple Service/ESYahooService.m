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
#import "DCPurpleYahooJoinChatViewController.h"
#import "ESPurpleYahooAccount.h"
#import "ESPurpleYahooAccountViewController.h"
#import "ESYahooService.h"

@implementation ESYahooService

//Account Creation
- (Class)accountClass{
	return [ESPurpleYahooAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleYahooAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleYahooJoinChatViewController joinChatView];
}

- (BOOL)canCreateGroupChats{
	return YES;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-Yahoo!";
}
- (NSString *)serviceID{
	return @"Yahoo!";
}
- (NSString *)serviceClass{
	return @"Yahoo!";
}
- (NSString *)shortDescription{
	return @"Yahoo!";
}
- (NSString *)longDescription{
	return @"Yahoo! Messenger";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789_@.- +"];
}
- (NSUInteger)allowedLength{
	return 50;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"Yahoo! ID",nil);    //Yahoo! ID
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
	
	/* Yahoo supports custom statuses... ESPurpleYahooAccount will convert a properly written cusutom status
	 * into the Yahoo-specific statuses as necessary. Uncomment to explicitly add support for these statuses. */
	/*
	[adium.statusController registerStatus:STATUS_NAME_BRB
							 withDescription:STATUS_DESCRIPTION_BRB
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_BUSY
							 withDescription:STATUS_DESCRIPTION_BUSY
									  ofType:AIAwayStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_NOT_AT_HOME
							 withDescription:STATUS_DESCRIPTION_NOT_AT_HOME
									  ofType:AIAwayStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_NOT_AT_DESK
							 withDescription:STATUS_DESCRIPTION_NOT_AT_DESK
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_NOT_IN_OFFICE
							 withDescription:STATUS_DESCRIPTION_NOT_IN_OFFICE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_PHONE
							 withDescription:STATUS_DESCRIPTION_PHONE
									  ofType:AIAwayStatusType
								  forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_VACATION
							 withDescription:STATUS_DESCRIPTION_VACATION
									  ofType:AIAwayStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_LUNCH
							 withDescription:STATUS_DESCRIPTION_LUNCH
									  ofType:AIAwayStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_STEPPED_OUT
							 withDescription:STATUS_DESCRIPTION_STEPPED_OUT
									  ofType:AIAwayStatusType
								  forService:self];
	 */
	
	/*
	m = g_list_append(m, _("Be Right Back"));
	m = g_list_append(m, _("Busy"));
	m = g_list_append(m, _("Not At Home"));
	m = g_list_append(m, _("Not At Desk"));
	m = g_list_append(m, _("Not In Office"));
	m = g_list_append(m, _("On The Phone"));
	m = g_list_append(m, _("On Vacation"));
	m = g_list_append(m, _("Out To Lunch"));
	m = g_list_append(m, _("Stepped Out"));
	 */
}

@end
