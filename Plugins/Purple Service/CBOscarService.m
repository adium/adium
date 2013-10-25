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

#import "AIPurpleAIMAccountViewController.h"
#import "CBOscarService.h"
#import "DCPurpleOscarJoinChatViewController.h"
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

/*!
 * @class CBOscarService
 * @brief Superclass for ESAIMService and ESICQService
 *
 * This service is abstract and should not be used directly.
 */
@implementation CBOscarService

//Account Creation
- (AIAccountViewController *)accountViewController{
    return [AIPurpleOscarAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleOscarJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceClass{
	return @"AIM-compatible";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"+abcdefghijklmnopqrstuvwxyz0123456789@._- "];
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}
- (AIServiceImportance)serviceImportance{
	return AIServiceUnsupported;
}

#pragma mark Must be subclassed
- (NSString *)serviceCodeUniqueID{
	return @""; /* Subclasses should return a value starting with libpurple-oscar */
}
- (NSString *)shortDescription{
	return @"";
}
- (NSString *)longDescription{
	return @"";
}
- (NSString *)serviceID{
	return @"";
}

- (NSString *)normalizeChatName:(NSString *)inChatName
{
	return [[inChatName compactedString] lowercaseString];
}

#pragma mark Statuses
/*!
 * @brief Register statuses
 */
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
