//
//  PurpleFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 1/15/09.
//  Copyright 2009 Adium X. All rights reserved.
//

#import "PurpleFacebookAccount.h"
#import <Adium/AIAccountControllerProtocol.h>
#import "AIFacebookXMPPService.h"
#import "AIFacebookXMPPAccount.h"

#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>


@interface PurpleFacebookAccount ()
- (void)finishMigration;
@end

@implementation PurpleFacebookAccount

- (void)didCompleteFacebookAuthorization
{
	[super didCompleteFacebookAuthorization];
	
	/* Now that we're authorized, we can perform any needed migration of transcripts, etc. */
	if (self.migrationData) {
		[self finishMigration];        
    }
}

#pragma mark Migration
/*
 * Move logs from the old account's to the new account's log folder, changing the name along the way.
 * Finally delete the old account.
 */
- (void)finishMigration
{
	if (!self.migrationData)
		return;
	
	//Move logs to the new account
	NSString *logsDir = [[adium.loginController userDirectory] stringByAppendingPathComponent:@"Logs"];
	AIService *newXMPPService = [adium.accountController serviceWithUniqueID:FACEBOOK_XMPP_SERVICE_ID];
	
	NSString *oldFolder = [NSString stringWithFormat:@"%@.%@",
						   [self.migrationData objectForKey:@"originalServiceID"],
						   [[self.migrationData objectForKey:@"originalUID"] safeFilenameString]];

	
	NSString *newFolder = [NSString stringWithFormat:@"%@.%@", 
						   newXMPPService.serviceID,
						   [self.UID safeFilenameString]];
	NSString *basePath = [[logsDir stringByAppendingPathComponent:oldFolder] stringByExpandingTildeInPath];
	NSString *newPath = [[logsDir stringByAppendingPathComponent:newFolder] stringByExpandingTildeInPath];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSInteger errors = 0;
	
	for (NSString *file in [fileManager enumeratorAtPath:basePath]) {
		if ([[file pathExtension] isEqualToString:@"xml"]) {
			/* turn 'XXXXXXX69 (2009-01-20T19.10.07-0500).xml'
			 * into '-XXXXXXX69@chat.facebook.com (2009-01-20T19.10.07-0500).xml'
			 */
			NSRange UIDrange = [[file lastPathComponent] rangeOfString:@" "];
			if (UIDrange.location > 0) {
				NSString *uid = [[file lastPathComponent] substringToIndex:UIDrange.location];
				NSString *newName = [file stringByReplacingOccurrencesOfString:uid
																	withString:[NSString stringWithFormat:@"-%@@%@", uid, self.host]];
				
				[fileManager createDirectoryAtPath:[newPath stringByAppendingPathComponent:[newName stringByDeletingLastPathComponent]]
					   withIntermediateDirectories:YES
										attributes:nil
											 error:NULL];
				if (![fileManager moveItemAtPath:[basePath stringByAppendingPathComponent:file]
										  toPath:[newPath stringByAppendingPathComponent:newName]
										   error:NULL])
					errors++;
			}
		}
	}
	
	if (!errors)
		[fileManager removeItemAtPath:basePath error:NULL];
	
	/* We're done self-identifying as the legacy service; from now on, we are the modern service */
	[adium.accountController moveAccount:self toService:newXMPPService];
}


@end
