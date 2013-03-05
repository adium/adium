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

#import "AIEventSoundsPlugin.h"
#import "AISoundController.h"
#import "ESEventSoundAlertDetailPane.h"
#import <Adium/AIListObject.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

#define EVENT_SOUNDS_ALERT_SHORT	AILocalizedString(@"Play a sound",nil)
#define EVENT_SOUNDS_ALERT_LONG		AILocalizedString(@"Play the sound \"%@\"",nil)

#define SOUND_ALERT_IDENTIFIER		@"PlaySound"

/*!
 * @class AIEventSoundsPlugin
 *
 * @brief Component for the Play Sound action
 */
@implementation AIEventSoundsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our contact alert
	[adium.contactAlertsController registerActionID:SOUND_ALERT_IDENTIFIER withHandler:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return EVENT_SOUNDS_ALERT_SHORT;
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*fileName = [[[details objectForKey:KEY_ALERT_SOUND_PATH] lastPathComponent] stringByDeletingPathExtension];
	
	if (fileName && [fileName length]) {
		return [NSString stringWithFormat:EVENT_SOUNDS_ALERT_LONG, fileName];
	} else {
		return EVENT_SOUNDS_ALERT_SHORT;
	}
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-sound-alert" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [ESEventSoundAlertDetailPane actionDetailsPane];
}

/*!
 * @brief Perform an action
 *
 * Play a sound
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	BOOL shouldPlay = ![listObject soundsAreMuted];
	if (shouldPlay) {
		NSString	*soundPath = [[details objectForKey:KEY_ALERT_SOUND_PATH] stringByExpandingBundlePath];
		[adium.soundController playSoundAtPath:soundPath];
	}
	
	return shouldPlay;
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Don't allow multiple sounds to be played for a single event.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

/*!
 * @brief Alert was selected in the preferences
 *
 *  Play the sound for this alert when the alert is selected
 */
- (void)performPreviewForAlert:(NSDictionary *)alert
{
	NSString	*soundPath = [[[alert objectForKey:KEY_ACTION_DETAILS] objectForKey:KEY_ALERT_SOUND_PATH] stringByExpandingBundlePath];
	[adium.soundController playSoundAtPath:soundPath];
}

@end

