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

#import "AIDockBadger.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import "AIDockController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIIconState.h>

@interface AIDockBadger ()
- (void)removeOverlay;
- (void)_setOverlay;
@end

@implementation AIDockBadger

#pragma mark Birth and death

/*!
 * @brief Install
 */
- (void)installPlugin
{
	overlayState = nil;

	//Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"BadgerDefaults"
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_APPEARANCE];

	//Observe pref changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	
	// Register as an observer of the status preferences for unread conversation count
	[adium.preferenceController registerPreferenceObserver:self
													forGroup:PREF_GROUP_STATUS_PREFERENCES];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

#pragma mark Signals to update

/*!
 * @brief Update our overlay when a chat updates with a relevant key
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (!inModifiedKeys || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		[self performSelector:@selector(_setOverlay)
				   withObject:nil
				   afterDelay:0];
	}
	
	return nil;
}

/*!
 * @brief Update our overlay when a chat closes
 */
- (void)chatClosed:(NSNotification *)notification
{	
	[self performSelector:@selector(_setOverlay)
			   withObject:nil
			   afterDelay:0];
}

#pragma mark Preference observing
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_APPEARANCE] && (!key || [key isEqualToString:KEY_BADGE_DOCK_ICON])) {
		BOOL	newShouldBadge = [[prefDict objectForKey:KEY_BADGE_DOCK_ICON] boolValue];
		if (newShouldBadge != shouldBadge) {
			shouldBadge = newShouldBadge;
			
			if (shouldBadge) {
				//Register as a chat observer (for unviewed content). If there is any unviewed content, our overlay will be set.
				[adium.chatController registerChatObserver:self];
				
				[[NSNotificationCenter defaultCenter] addObserver:self
											   selector:@selector(chatClosed:)
												   name:Chat_WillClose
												 object:nil];
			} else {
				//Remove any existing overlay
				[self removeOverlay];
				
				//Stop observing
				[adium.chatController unregisterChatObserver:self];
				[[NSNotificationCenter defaultCenter] removeObserver:self];
			}
		}
	}
	
	if ([group isEqualToString:PREF_GROUP_STATUS_PREFERENCES]) {
		showConversationCount = [[prefDict objectForKey:KEY_STATUS_CONVERSATION_COUNT] boolValue];
		
		[self _setOverlay];
	}
}	

#pragma mark Work methods

- (NSImage *)numberedBadge:(NSInteger)count
{
	if(!badgeTwoDigits) {
		badgeTwoDigits = [[NSImage imageNamed:@"newContentTwoDigits"] retain];
		badgeThreeDigits = [[NSImage imageNamed:@"newContentThreeDigits"] retain];
	}

	NSImage		*badge = nil, *badgeToComposite = nil;
	NSString	*numString = nil;

	//999 unread messages should be enough for anyone
	if (count >= 1000) {
		count = 999;
	}

	badgeToComposite = ((count < 10) ? badgeTwoDigits : badgeThreeDigits);
	numString = [[NSNumber numberWithInteger:count] description];

	NSRect rect = { NSZeroPoint, [badgeToComposite size] };
	NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:24];
	
	if (!font) font = [NSFont systemFontOfSize:24];
	
	NSDictionary *atts = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor whiteColor], NSForegroundColorAttributeName,
		font, NSFontAttributeName,
		nil];
	
	NSSize numSize = [numString sizeWithAttributes:atts];
	rect.origin.x = (rect.size.width / 2) - (numSize.width / 2);
	rect.origin.y = (rect.size.height / 2) - (numSize.height / 2);

	badge = [[NSImage alloc] initWithSize:rect.size];
	[badge setFlipped:YES];
	[badge lockFocus];
	[badgeToComposite compositeToPoint:NSMakePoint(0, rect.size.height) operation:NSCompositeSourceOver];

	[numString drawInRect:rect
		   withAttributes:atts];
	
	[badge unlockFocus];
		
	return [badge autorelease];
}

/*!
 * @brief Remove any existing dock overlay
 */
- (void)removeOverlay
{
	if (overlayState) {
		[adium.dockController removeIconStateNamed:@"UnviewedContentCount"];
		[overlayState release]; overlayState = nil;
	}
}

/*!
 * @brief Update our overlay to the current unviewed content count
 */
- (void)_setOverlay
{
	NSInteger contentCount = (showConversationCount ?
					   [adium.chatController unviewedConversationCount] : [adium.chatController unviewedContentCount]);

	if (contentCount != lastUnviewedContentCount) {
		//Remove & release the current overlay state
		[self removeOverlay];

		//Create & set the new overlay state
		if (contentCount > 0) {
			//Set the state
			overlayState = [[AIIconState alloc] initWithImage:[self numberedBadge:contentCount] 
													  overlay:YES];
			[adium.dockController setIconState:overlayState named:@"UnviewedContentCount"];
		}

		lastUnviewedContentCount = contentCount;
	}
}

@end
