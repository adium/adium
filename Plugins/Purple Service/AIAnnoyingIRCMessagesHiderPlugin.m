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

#import "AIAnnoyingIRCMessagesHiderPlugin.h"
#import "ESIRCAccount.h"
#import <Adium/AIContentControllerProtocol.h>

#import <Adium/AIContentMessage.h>

@interface AIAnnoyingIRCMessagesHiderPlugin()
- (void)willReceiveContent:(NSNotification *)notification;
@end

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
							   @"runs an open proxy monitor to prevent abuse",
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
