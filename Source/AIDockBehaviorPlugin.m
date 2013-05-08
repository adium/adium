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

#import "AIDockBehaviorPlugin.h"
#import "AIDockController.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESDockAlertDetailPane.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChat.h>
#import <AIUtilities/AIImageAdditions.h>

#define AIDockBehavior_ALERT_SHORT	AILocalizedString(@"Bounce the dock icon",nil)
#define AIDockBehavior_ALERT_LONG	AILocalizedString(@"Bounce the dock icon %@","%@ will be repalced with a string like 'one time' or 'repeatedly'.")

@interface AIDockBehaviorPlugin ()
- (void)observeToStopBouncingForChat:(AIChat *)chat;
- (void)stopBouncing:(NSNotification *)inNotification;
@end

/*!
 * @class AIDockBehaviorPlugin
 * @brief Bounce Dock action component
 */
@implementation AIDockBehaviorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Install our contact alert
	[adium.contactAlertsController registerActionID:AIDockBehavior_ALERT_IDENTIFIER withHandler:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return AIDockBehavior_ALERT_SHORT;
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	AIDockBehavior behavior = [[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue];
	return [NSString stringWithFormat:AIDockBehavior_ALERT_LONG, [[adium.dockController descriptionForBehavior:behavior] lowercaseString]];
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-dock-alert" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [ESDockAlertDetailPane actionDetailsPane];
}

/*!
 * @brief Perform an action
 *
 * Bounce the dock icon
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	if ([adium.dockController performBehavior:[[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue]]) {
		//The behavior will continue into the future
		if ([adium.contactAlertsController isMessageEvent:eventID]) {
			AIChat *chat = [userInfo objectForKey:@"AIChat"];
			
			if (chat == adium.interfaceController.activeChat) {
				//If this is the active chat, stop the bouncing immediately
				[self stopBouncing:nil];
	
			} else {
				[self observeToStopBouncingForChat:chat];
			}
		}
	}
	
	return YES;
}

/*!
 * @brief Begin watching for this chat to close or become active so we'll know to stop bouncing
 */
- (void)observeToStopBouncingForChat:(AIChat *)chat
{
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(stopBouncing:)
									   name:Chat_WillClose
									 object:chat];

	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(stopBouncing:)
									   name:Chat_BecameActive
									 object:chat];
}

/*!
 * @brief Remove our observers and stop bouncing
 *
 * We remove all observers because no matter how many chats we were watching, we will stop bouncing; subsequently, stopping a bounce
 * would be inappropriate as it would not be associated with the chat or event which triggered a later bounce.
 */
- (void)stopBouncing:(NSNotification *)inNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:Chat_WillClose
										object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:Chat_BecameActive
										object:nil];

	[adium.dockController performBehavior:AIDockBehaviorStopBouncing];
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Don't allow multiple dock actions to occur.  While a series of "Bounce every 5 seconds," "Bounce every 10 seconds,"
 * and so on actions could be combined sanely, a series of "Bounce once" would make the dock go crazy.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

@end

