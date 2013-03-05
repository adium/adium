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

#import "SMContactListShowBehaviorPlugin.h"
#import "SMContactListShowDetailsPane.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "AICoreComponentLoader.h"
#import "AISCLViewPlugin.h"
#import "AIListWindowController.h"
#import <AIUtilities/AIImageAdditions.h>

#define SHOW_CONTACT_LIST_BEHAVIOR_ALERT_SHORT	AILocalizedString(@"Show the contact list window",nil)
#define SHOW_CONTACT_LIST_BEHAVIOR_ALERT_LONG	AILocalizedString(@"Show the contact list window for %.1f seconds",nil)

@interface SMContactListShowBehaviorPlugin ()
- (void)hideContactList:(NSTimer *)timer;
@end

/*!
 * @class SMContactListShowBehaviorPlugin
 * @brief Show hidden contact list action component
 */
@implementation SMContactListShowBehaviorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Install our contact alert
	[adium.contactAlertsController registerActionID:SHOW_CONTACT_LIST_BEHAVIOR_ALERT_IDENTIFIER withHandler:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return SHOW_CONTACT_LIST_BEHAVIOR_ALERT_SHORT;
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	double seconds = [[details objectForKey:KEY_SECONDS_TO_SHOW_LIST] doubleValue];
	return [NSString stringWithFormat:SHOW_CONTACT_LIST_BEHAVIOR_ALERT_LONG, seconds];
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"pref-contact-list" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [SMContactListShowDetailsPane actionDetailsPane];
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
	NSTimeInterval secondsToShow = [[details objectForKey:KEY_SECONDS_TO_SHOW_LIST] doubleValue];
	AISCLViewPlugin *contactListViewPlugin = (AISCLViewPlugin *)[[adium componentLoader] pluginWithClassName:@"AISCLViewPlugin"];
	AIListWindowController *windowController = [contactListViewPlugin contactListWindowController];

	[windowController setPreventHiding:YES];
	
	if ([windowController windowShouldHideOnDeactivate]) {
		[[windowController window] setHidesOnDeactivate:NO];
		[[windowController window] orderFront:self];
	} else {
		[windowController slideWindowOnScreen];
	}

	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(hideContactList:)
											   object:nil];
	[self performSelector:@selector(hideContactList:)
			   withObject:nil
			   afterDelay:secondsToShow];
	
	return YES;
}


/*!
 * @brief Show the contact list after the time specified has elapsed
 */
- (void)hideContactList:(NSTimer *)timer {
	AISCLViewPlugin			*contactListViewPlugin = (AISCLViewPlugin *)[[adium componentLoader] pluginWithClassName:@"AISCLViewPlugin"];
	AIListWindowController	*windowController = [contactListViewPlugin contactListWindowController];
	
	[windowController setPreventHiding:NO];

	if ([windowController windowShouldHideOnDeactivate] && ![NSApp isActive]) {
		[[windowController window] orderOut:self];

	} else if ([windowController shouldSlideWindowOffScreen]) {
		[windowController slideWindowOffScreenEdges:[windowController slidableEdgesAdjacentToWindow]];
	}
}


/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Don't allow multiple dock actions to occur.  The contact list can only show itself once.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

@end
