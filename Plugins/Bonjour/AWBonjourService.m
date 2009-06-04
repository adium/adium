//
//  AWBonjourService.m
//  Adium
//
//  Created by Adam Iser on 8/26/04.
//  Copyright (c) 2004-2006 The Adium Team. All rights reserved.
//

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
