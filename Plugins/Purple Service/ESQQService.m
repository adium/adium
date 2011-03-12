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

#import "ESQQService.h"
#import "ESPurpleQQAccount.h"
#import "ESPurpleQQAccountViewController.h"
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AICharacterSetAdditions.h>

@implementation ESQQService
//Account Creation
- (Class)accountClass{
	return [ESPurpleQQAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleQQAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return nil;
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-qq";
}
- (NSString *)serviceID{
	return @"QQ";
}
- (NSString *)serviceClass{
	return @"QQ";
}
- (NSString *)shortDescription{
	return @"QQ";
}
- (NSString *)longDescription{
	return @"QQ";
}
- (NSCharacterSet *)allowedCharacters{
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;

	[allowedCharacters addCharactersInString:@"-"];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];

	return [returnSet autorelease];
}
- (NSUInteger)allowedLength{
	return 255;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)canCreateGroupChats{
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
	
}

@end
