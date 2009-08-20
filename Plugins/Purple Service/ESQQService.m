//
//  ESQQService.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

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
