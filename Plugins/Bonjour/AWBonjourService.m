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

#import "AWBonjourService.h"
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/DCJoinChatViewController.h>
#import "AWBonjourAccount.h"
#import "ESBonjourAccountViewController.h"

@implementation AWBonjourService

//Account Creation
- (Class)accountClass{
	return [AWBonjourAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESBonjourAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"bonjour-libezv";
}
- (NSString *)serviceID{
	return @"Bonjour";
}
- (NSString *)serviceClass{
	return @"Bonjour";
}
- (NSString *)shortDescription{
	return @"Bonjour";
}
- (NSString *)longDescription{
	return @"Bonjour";
}
- (NSCharacterSet *)allowedCharacters{
	return [[NSCharacterSet illegalCharacterSet] invertedSet];
}
- (NSUInteger)allowedLength{
	return 999;
}
- (BOOL)caseSensitive{
	return YES;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)supportsProxySettings{
	return NO;
}
//No need for a password for Bonjour accounts
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
}
- (NSString *)defaultUserName {
	return NSFullUserName(); 
}
@end
