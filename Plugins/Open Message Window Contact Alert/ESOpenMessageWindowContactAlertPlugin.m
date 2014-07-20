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

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESOpenMessageWindowContactAlertPlugin.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListContact.h>

#define OPEN_MESSAGE_ALERT_SHORT	AILocalizedString(@"Open a message window",nil)
#define OPEN_MESSAGE_ALERT_LONG		OPEN_MESSAGE_ALERT_SHORT

@implementation ESOpenMessageWindowContactAlertPlugin

- (void)installPlugin
{
	[adium.contactAlertsController registerActionID:@"OpenMessageWindow" withHandler:self];
}


//Open Message Alert ---------------------------------------------------------------------------------------------------
#pragma mark Play Sound Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return OPEN_MESSAGE_ALERT_SHORT;
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return OPEN_MESSAGE_ALERT_LONG;
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-window-alert" forClass:[self class]];
}

- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return nil;
}

- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	if ([listObject isKindOfClass:[AIListContact class]]) {
		[adium.chatController openChatWithContact:(AIListContact *)listObject
								 onPreferredAccount:YES];
	}
	
	return YES;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

@end
