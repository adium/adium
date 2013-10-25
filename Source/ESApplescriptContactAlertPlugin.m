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

#import "ESApplescriptContactAlertPlugin.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESPanelApplescriptDetailPane.h"
#import "ESApplescriptabilityController.h"
#import <AIUtilities/AIImageAdditions.h>

#define APPLESCRIPT_ALERT_SHORT AILocalizedString(@"Run an AppleScript",nil)
#define APPLESCRIPT_ALERT_LONG AILocalizedString(@"Run the AppleScript \"%@\"","%@ will be replaced by the name of the AppleScript to run.")

/*!
 * @class ESApplescriptContactAlertPlugin
 * @brief Component which provides a "Run an Applescript" Action
 */
@implementation ESApplescriptContactAlertPlugin

- (void)installPlugin
{
    //Install our contact alert
	[adium.contactAlertsController registerActionID:APPLESCRIPT_CONTACT_ALERT_IDENTIFIER withHandler:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return APPLESCRIPT_ALERT_SHORT;
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*scriptName = [[[details objectForKey:KEY_APPLESCRIPT_TO_RUN] lastPathComponent] stringByDeletingPathExtension];
	
	if (scriptName && [scriptName length]) {
		return [NSString stringWithFormat:APPLESCRIPT_ALERT_LONG, scriptName];
	} else {
		return APPLESCRIPT_ALERT_SHORT;
	}
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-applescript-alert" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [ESPanelApplescriptDetailPane actionDetailsPane];
}

/*!
 * @brief Perform an action
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString		*path = [details objectForKey:KEY_APPLESCRIPT_TO_RUN];

	if (path) {
		[adium.applescriptabilityController runApplescriptAtPath:path
														  function:nil
														 arguments:nil
												   notifyingTarget:nil
														  selector:NULL
														  userInfo:nil];
	}

	return (path != nil);
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Allow multiple applescript actions to be taken.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return YES;
}

@end
