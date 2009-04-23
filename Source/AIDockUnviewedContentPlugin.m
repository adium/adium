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

#import "AIDockUnviewedContentPlugin.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIDockControllerProtocol.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>

@interface AIDockUnviewedContentPlugin ()
- (void)removeAlert;
@end

/*!
 * @class AIDockUnviewedContentPlugin
 * @brief Component responsible for triggering and removing the Alert dock icon state for unviewed content
 */
@implementation AIDockUnviewedContentPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //init
    unviewedState = NO;

	//Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"DockUnviewedContentDefaults"
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_APPEARANCE];
	
	//Observe pref changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Preference observing
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!key || [key isEqualToString:KEY_ANIMATE_DOCK_ICON]) {
		BOOL newAnimateDockIcon = [[prefDict objectForKey:KEY_ANIMATE_DOCK_ICON] boolValue];

		if (newAnimateDockIcon != animateDockIcon) {
			animateDockIcon = newAnimateDockIcon;
			
			if (animateDockIcon) {
				//Register as a chat observer (So we can catch the unviewed content status flag)
				[adium.chatController registerChatObserver:self];
				
				[[NSNotificationCenter defaultCenter] addObserver:self
											   selector:@selector(chatWillClose:)
												   name:Chat_WillClose object:nil];
				
			} else {
				[self removeAlert];

				[adium.chatController unregisterChatObserver:self];
				[[NSNotificationCenter defaultCenter] removeObserver:self];
			}
		}
	}
}
/*!
 * @brief Chat was updated
 *
 * Check for whether inModifiedKeys contains a change to unviewed content. If so, put the dock in the Alert state
 * if it isn't already and there is unviewed content, or take it out of the Alert state if it is and there is none.
 *
 * The alert state, in the default dock icon set, is the Adium duck flapping its wings.
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if ([inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
        if (adium.chatController.unviewedContentCount) {
            //If this is the first contact with unviewed content, animate the dock
            if (!unviewedState) {
				NSString *iconState;

				if (([adium.statusController.activeStatusState statusType] == AIInvisibleStatusType) &&
					[adium.dockController currentIconSupportsIconStateNamed:@"InvisibleAlert"]) {
					iconState = @"InvisibleAlert";					
				} else {
					iconState = @"Alert";
				}

                [adium.dockController setIconStateNamed:iconState];
                unviewedState = YES;
            }
        } else if (unviewedState) {
			//If there are no more contacts with unviewed content, stop animating the dock
			[self removeAlert];
        }
    }

    return nil;
}

/*!
 * @brief Remove any existing alert state
 */
- (void)removeAlert
{
	[adium.dockController removeIconStateNamed:@"Alert"];
	[[adium dockController] removeIconStateNamed:@"InvisibleAlert"];
	unviewedState = NO;
}

/*!
 * @brief Respond to a chat closing
 *
 * Ensure that when a chat closes we remove the Alert state if necessary.
 */
- (void)chatWillClose:(NSNotification *)notification
{
	if (!adium.chatController.unviewedContentCount && unviewedState) {
		//If there are no more contacts with unviewed content, stop animating the dock
		[self removeAlert];
	}
}

@end
