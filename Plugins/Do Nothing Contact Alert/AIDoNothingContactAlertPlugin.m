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

#import "AIDoNothingContactAlertPlugin.h"
#import <AIUtilities/AIImageAdditions.h>

#define DO_NOTHING_ALERT_SHORT	AILocalizedString(@"Do Nothing", nil)
#define DO_NOTHING_ALERT_LONG	AILocalizedString(@"Do Not perform any further actions", nil)

@implementation AIDoNothingContactAlertPlugin

- (void)installPlugin
{
	[adium.contactAlertsController registerActionID:DO_NOTHING_ALERT_IDENTIFIER withHandler:self];
}

- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return DO_NOTHING_ALERT_SHORT;
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return DO_NOTHING_ALERT_LONG;
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-do-nothing" forClass:[self class]];
}

- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return nil;
}

- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	return YES;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return YES;
}

@end
