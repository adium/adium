//
//  AIAnnoyingIRCMessagesHiderPlugin.m
//  Adium
//
//  Created by Zachary West on 2009-05-31.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIAnnoyingIRCMessagesHiderPlugin.h"
#import "ESIRCAccount.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>

#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>
#import <Adium/AIChat.h>

@implementation AIAnnoyingIRCMessagesHiderPlugin
- (void)installPlugin
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(willReceiveContent:)
												 name:Content_WillReceiveContent
											   object:nil];
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Content handling
- (void)willReceiveContent:(NSNotification *)notification
{	
	AIContentObject		*contentObject = [[notification userInfo] objectForKey:@"Object"];
	
	if (![contentObject isKindOfClass:[AIContentMessage class]] ||
		![contentObject.chat.account isKindOfClass:[ESIRCAccount class]] ||
		!contentObject.source) {
		return;
	}

	BOOL				hidden = NO;
	
	NSArray *serverMessages = [NSArray arrayWithObjects:
							   @"highest connection count",
							   @"your host is",
							   @"exempt from DNS blacklists",
							   @"motd was last changed",
							   @"please read the motd",
							   @"if you see",
							   @"please disregard them, as they are",
							   @"for more information please visit",
							   nil];
	
	if ([contentObject.source.UID rangeOfString:@"."].location != NSNotFound) {
		for (NSString *message in serverMessages) {
			if ([contentObject.message.string rangeOfString:message options:NSCaseInsensitiveSearch].location != NSNotFound) {
				hidden = YES;
				break;
			}
		}
	} else if ([contentObject.source.UID isEqualToString:@"freenode-connect"]) {
		hidden = YES;
	}
	
	// We use our own "did we hide?" variable, in case something else somewhere has caused this to not display.
	if (hidden) {
		AILogWithSignature(@"Hiding %@", contentObject);
		contentObject.displayContent = NO;
	}
}

@end
