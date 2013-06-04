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
#import "DCPurpleGaduGaduJoinChatViewController.h"
#import "ESGaduGaduService.h"
#import "ESPurpleGaduGaduAccount.h"
#import "ESPurpleGaduGaduAccountViewController.h"

@implementation ESGaduGaduService

//Account Creation
- (Class)accountClass{
	return [ESPurpleGaduGaduAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleGaduGaduAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleGaduGaduJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-Gadu-Gadu";
}
- (NSString *)serviceID{
	return @"Gadu-Gadu";
}
- (NSString *)serviceClass{
	return @"Gadu-Gadu";
}
- (NSString *)shortDescription{
	return @"Gadu-Gadu";
}
- (NSString *)longDescription{
	return @"Gadu-Gadu";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._ "];
}
- (NSUInteger)allowedLength{
	return 24;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
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

	/*
	[adium.statusController registerStatus:STATUS_NAME_NOT_AVAILABLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AVAILABLE]
									  ofType:AIAwayStatusType
								  forService:self];
	*/
	
	[adium.statusController registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];

	//What does a Blocked invisible status mean, anyways?
	[adium.statusController registerStatus:@"blocked"
							 withDescription:AILocalizedString(@"Blocked", nil)
									  ofType:AIInvisibleStatusType
								  forService:self];

	[adium.statusController registerStatus:STATUS_NAME_OFFLINE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE]
									  ofType:AIOfflineStatusType
								  forService:self];	
}

@end
