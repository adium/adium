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

#import "AIStressTestService.h"
#import "AIStressTestAccount.h"
#import "DCStressTestJoinChatViewController.h"

@implementation AIStressTestService

//Account Creation
- (Class)accountClass{
	return [AIStressTestAccount class];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCStressTestJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"Stress-Test";
}
- (NSString *)serviceID{
	return @"Stress Test";
}
- (NSString *)serviceClass{
	return @"Stress Test";
}
- (NSString *)shortDescription{
	return @"Stress Test";
}
- (NSString *)longDescription{
	return @"Stress Test (Das ist verboten)";
}
- (NSCharacterSet *)allowedCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."];
}
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@""];
}
- (int)allowedLength{
	return 20;
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceUnsupported;
}
- (BOOL)supportsProxySettings{
	return NO;
}
- (BOOL)supportsPassword
{
	return NO;
}
@end
