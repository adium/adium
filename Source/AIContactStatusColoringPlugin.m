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

#import "AIAbstractListController.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIContactStatusColoringPlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIListThemeWindowController.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListBookmark.h>

@interface AIContactStatusColoringPlugin ()
- (void)addToFlashSet:(AIListObject *)inObject;
- (void)removeFromFlashSet:(AIListObject *)inObject;
- (void)_applyColorToContact:(AIListContact *)inObject;
@end

@implementation AIContactStatusColoringPlugin

#define OFFLINE_IMAGE_OPACITY	0.5
#define FULL_IMAGE_OPACITY		1.0
#define	OPACITY_REFRESH			0.2

#define CONTACT_STATUS_COLORING_DEFAULT_PREFS	@"ContactStatusColoringDefaults"

- (void)installPlugin
{
    //init
    flashingListObjects = [[NSMutableSet alloc] init];
    awayColor = nil;
    idleColor = nil;
    signedOffColor = nil;
    signedOnColor = nil;
    typingColor = nil;
    unviewedContentColor = nil;
    onlineColor = nil;
    awayAndIdleColor = nil;
	offlineColor = nil;
	
    awayInvertedColor = nil;
    idleInvertedColor = nil;
    signedOffInvertedColor = nil;
    signedOnInvertedColor = nil;
    typingInvertedColor = nil;
    unviewedContentInvertedColor = nil;
    onlineInvertedColor = nil;
    awayAndIdleInvertedColor = nil;
	offlineInvertedColor = nil;
	
    awayLabelColor = nil;
    idleLabelColor = nil;
    signedOffLabelColor = nil;
    signedOnLabelColor = nil;
    typingLabelColor = nil;
    unviewedContentLabelColor = nil;
    onlineLabelColor = nil;
    awayAndIdleLabelColor = nil;
	offlineLabelColor = nil;
	
	offlineImageFading = NO;
	
		
	interestedKeysSet = [[NSSet alloc] initWithObjects:
						 KEY_TYPING, KEY_UNVIEWED_CONTENT,  @"StatusType", @"IsIdle",
						 @"Online", @"Signed On",  @"Signed Off", @"IsMobile", nil];

	id<AIPreferenceController> preferenceController = adium.preferenceController;

    //Setup our preferences
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTACT_STATUS_COLORING_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_LIST_THEME];
    
    //Observe preferences and list objects
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.interfaceController unregisterFlashObserver:self];	
}

- (void)dealloc
{
	[flashingListObjects release];
	[interestedKeysSet release];
	
	[super dealloc];
}

//
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;

	if ([inObject isKindOfClass:[AIListContact class]] || [inObject isKindOfClass:[AIListBookmark class]]) {
		if (inModifiedKeys == nil || [inModifiedKeys intersectsSet:interestedKeysSet]) {
			//Update the contact's text color
			[self _applyColorToContact:(AIListContact *)inObject];
			modifiedAttributes = [NSSet setWithObjects:@"Text Color", @"Inverted Text Color", @"Label Color", nil];
		}
		
		//Update our flash set
		if (flashUnviewedContentEnabled &&
			(inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT])) {
			NSInteger unviewedContent = [inObject integerValueForProperty:KEY_UNVIEWED_CONTENT];
			
			if (unviewedContent && ![flashingListObjects containsObject:inObject]) { //Start flashing
				[self addToFlashSet:inObject];
			} else if (!unviewedContent && [flashingListObjects containsObject:inObject]) { //Stop flashing
				[self removeFromFlashSet:inObject];
			}
		}
	}

    return modifiedAttributes;
}

//Applies the correct color to the passed object
- (void)_applyColorToContact:(AIListContact *)inContact
{
    NSColor			*color = nil, *invertedColor = nil, *labelColor = nil;
    NSInteger				unviewedContent;
	CGFloat			opacity = FULL_IMAGE_OPACITY;
	BOOL			isEvent = NO;

    //Prefetch the value for unviewed content, we need it multiple times below
    unviewedContent = [inContact integerValueForProperty:KEY_UNVIEWED_CONTENT];

    //Unviewed content
    if ((!color && !labelColor) && (unviewedContentEnabled && unviewedContent)) {
		/* Use the unviewed content settings if:
		 *	- we aren't flashing or
		 *  - every other flash. */
        if (!flashUnviewedContentEnabled || ([adium.interfaceController flashState] % 2)) {
            color = unviewedContentColor;
            invertedColor = unviewedContentInvertedColor;
            labelColor = unviewedContentLabelColor;
			isEvent = YES;
        }
    }

    //Offline, Signed off, signed on, or typing
    if ((!color && !labelColor)) {
		if (offlineEnabled && (!inContact.online &&
							  ![inContact boolValueForProperty:@"Signed Off"])) {
			color = offlineColor;
			invertedColor = offlineInvertedColor;
			labelColor = offlineLabelColor;
			if (offlineImageFading) opacity = OFFLINE_IMAGE_OPACITY;			
			
		} else if (signedOffEnabled && [inContact boolValueForProperty:@"Signed Off"]) {
            color = signedOffColor;
            invertedColor = signedOffInvertedColor;
            labelColor = signedOffLabelColor;
			isEvent = YES;

        } else if (signedOnEnabled && [inContact boolValueForProperty:@"Signed On"]) {
			color = signedOnColor;
            invertedColor = signedOnInvertedColor;
            labelColor = signedOnLabelColor;
			isEvent = YES;
			
        } else if (typingEnabled && ([inContact integerValueForProperty:KEY_TYPING] == AITyping)) {
            color = typingColor;
            invertedColor = typingInvertedColor;
            labelColor = typingLabelColor;
			isEvent = YES;
			
        }
    }

	if ((!color && !labelColor) && mobileEnabled && inContact.isMobile) {
		color = mobileColor;
		invertedColor = mobileInvertedColor;
		labelColor = mobileLabelColor;		
	}

    if ((!color && !labelColor)) {
		AIStatusSummary statusSummary = [inContact statusSummary];

        //Idle And Away, Away, or Idle
        if (awayAndIdleEnabled && (statusSummary == AIAwayAndIdleStatus)) {
            color = awayAndIdleColor;
            invertedColor = awayAndIdleInvertedColor;
            labelColor = awayAndIdleLabelColor;
        } else if (awayEnabled && ((statusSummary == AIAwayStatus) || (statusSummary == AIAwayAndIdleStatus))) {
            color = awayColor;
            invertedColor = awayInvertedColor;
            labelColor = awayLabelColor;
        } else if (idleEnabled && ((statusSummary == AIIdleStatus) || (statusSummary == AIAwayAndIdleStatus))) {
            color = idleColor;
            invertedColor = idleInvertedColor;
            labelColor = idleLabelColor;
        }
    }

    //Online
    if ((!color && !labelColor) && onlineEnabled && inContact.online) {
        color = onlineColor;
        invertedColor = onlineInvertedColor;
        labelColor = onlineLabelColor;
    }

    //Apply the color and opacity
    [inContact setValue:color
			forProperty:@"Text Color"
				 notify:NotifyNever];
    [inContact setValue:invertedColor
			forProperty:@"Inverted Text Color"
				 notify:NotifyNever];
    [inContact setValue:labelColor
			forProperty:@"Label Color"
				 notify:NotifyNever];
	[inContact setValue:[NSNumber numberWithDouble:opacity]
			forProperty:@"Image Opacity"
				 notify:NotifyNever];
	[inContact setValue:(isEvent ? [NSNumber numberWithBool:YES] : nil)
			forProperty:@"Is Event"
				 notify:NotifyNever];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    AIListContact	*object;

    for (object in flashingListObjects) {
        [self _applyColorToContact:object];
        
        //Force a redraw
        [adium.notificationCenter postNotificationName:ListObject_AttributesChanged 
												  object:object
												userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:@"Text Color", @"Label Color", @"Inverted Text Color", nil] forKey:@"Keys"]];
    }
}

/*!
 * @brief Add a handle to the flash set
 */
- (void)addToFlashSet:(AIListObject *)inObject
{
    //Ensure that we're observing the flashing
    if ([flashingListObjects count] == 0) {
        [adium.interfaceController registerFlashObserver:self];
    }

    //Add the contact to our flash set
    [flashingListObjects addObject:inObject];
    [self flash:[adium.interfaceController flashState]];
}

/*!
 * @brief Remove a contact from the flash set
 */
- (void)removeFromFlashSet:(AIListObject *)inObject
{
    //Remove the contact from our flash set
    [flashingListObjects removeObject:inObject];

    //If we have no more flashing contacts, stop observing the flashes
    if ([flashingListObjects count] == 0) {
        [adium.interfaceController unregisterFlashObserver:self];
    }
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_LIST_THEME]) {
		//Release the old values..
		[signedOffColor release]; signedOffColor = nil;
		[signedOnColor release]; signedOnColor = nil;
		[awayColor release]; awayColor = nil;
		[idleColor release]; idleColor = nil;
		[typingColor release]; typingColor = nil;
		[unviewedContentColor release]; unviewedContentColor = nil;
		[onlineColor release]; onlineColor = nil;
		[awayAndIdleColor release]; awayAndIdleColor = nil;
		[offlineColor release]; offlineColor = nil;
		[mobileColor release]; mobileColor = nil;
		
		[signedOffInvertedColor release]; signedOffInvertedColor = nil;
		[signedOnInvertedColor release]; signedOnInvertedColor = nil;
		[awayInvertedColor release]; awayInvertedColor = nil;
		[idleInvertedColor release]; idleInvertedColor = nil;
		[typingInvertedColor release]; typingInvertedColor = nil;
		[unviewedContentInvertedColor release]; unviewedContentInvertedColor = nil;
		[onlineInvertedColor release]; onlineInvertedColor = nil;
		[awayAndIdleInvertedColor release]; awayAndIdleInvertedColor = nil;
		[offlineInvertedColor release]; offlineInvertedColor = nil;
		[mobileInvertedColor release]; mobileInvertedColor = nil;
		
		[awayLabelColor release]; awayLabelColor = nil;
		[idleLabelColor release]; idleLabelColor = nil;
		[signedOffLabelColor release]; signedOffLabelColor = nil;
		[signedOnLabelColor release]; signedOnLabelColor = nil;
		[typingLabelColor release]; typingLabelColor = nil;
		[unviewedContentLabelColor release]; unviewedContentLabelColor = nil;
		[onlineLabelColor release]; onlineLabelColor = nil;
		[awayAndIdleLabelColor release]; awayAndIdleLabelColor = nil;
		[offlineLabelColor release]; offlineLabelColor = nil;
		[mobileLabelColor release]; mobileLabelColor = nil;
		
		if ((awayEnabled = [[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue])) {
			awayColor = [[[prefDict objectForKey:KEY_AWAY_COLOR] representedColor] retain];
			awayLabelColor = [[[prefDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor] retain];
			awayInvertedColor = [[awayColor colorWithInvertedLuminance] retain];
		}
	
		if ((idleEnabled = [[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue])) {
			idleColor = [[[prefDict objectForKey:KEY_IDLE_COLOR] representedColor] retain];
			idleLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor] retain];
			idleInvertedColor = [[idleColor colorWithInvertedLuminance] retain];
		}

		if ((signedOnEnabled = [[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue])) {
			signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];	
			signedOnLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor] retain];
			signedOnInvertedColor = [[signedOnColor colorWithInvertedLuminance] retain];
		}
		
		if ((signedOffEnabled = [[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue])) {
			signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
			signedOffLabelColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor] retain];
			signedOffInvertedColor = [[signedOffColor colorWithInvertedLuminance] retain];
		}		
		
		if ((typingEnabled = [[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue])) {
			typingColor = [[[prefDict objectForKey:KEY_TYPING_COLOR] representedColor] retain];
			typingLabelColor = [[[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor] retain];			
			typingInvertedColor = [[typingColor colorWithInvertedLuminance] retain];
		}
		
		if ((unviewedContentEnabled = [[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue])) {
			unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
			unviewedContentLabelColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor] retain];
			unviewedContentInvertedColor = [[unviewedContentColor colorWithInvertedLuminance] retain];			
		}
		
		if ((onlineEnabled = [[prefDict objectForKey:KEY_ONLINE_ENABLED] boolValue])) {
			onlineColor = [[[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor] retain];
			onlineLabelColor = [[[prefDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor] retain];
			onlineInvertedColor = [[onlineColor colorWithInvertedLuminance] retain];
		}

		if ((awayAndIdleEnabled = [[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue])) {
			awayAndIdleColor = [[[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor] retain];
			awayAndIdleLabelColor = [[[prefDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor] retain];
			awayAndIdleInvertedColor = [[awayAndIdleColor colorWithInvertedLuminance] retain];			
		}
		
		if ((offlineEnabled = [[prefDict objectForKey:KEY_OFFLINE_ENABLED] boolValue])) {
			offlineColor = [[[prefDict objectForKey:KEY_OFFLINE_COLOR] representedColor] retain];
			offlineLabelColor = [[[prefDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColor] retain];
			offlineInvertedColor = [[offlineColor colorWithInvertedLuminance] retain];			
		}
		
		if ((mobileEnabled = [[prefDict objectForKey:KEY_MOBILE_ENABLED] boolValue])) {
			mobileColor = [[[prefDict objectForKey:KEY_MOBILE_COLOR] representedColor] retain];		
			mobileLabelColor = [[[prefDict objectForKey:KEY_LABEL_MOBILE_COLOR] representedColor] retain];
			mobileInvertedColor = [[mobileColor colorWithInvertedLuminance] retain];			
		}

		offlineImageFading = [[prefDict objectForKey:KEY_LIST_THEME_FADE_OFFLINE_IMAGES] boolValue];

		//Update all objects
		if (!firstTime) {
			[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
		}

	} else if ([group isEqualToString:PREF_GROUP_CONTACT_LIST]) {
		BOOL oldFlashUnviewedContentEnabled = flashUnviewedContentEnabled;
		
		flashUnviewedContentEnabled = [[prefDict objectForKey:KEY_CL_FLASH_UNVIEWED_CONTENT] boolValue];

		if (oldFlashUnviewedContentEnabled && !flashUnviewedContentEnabled) {
			//Clear our flash set if we aren't flashing for unviewed content now but we were before
			for (AIListContact *listContact in [[flashingListObjects copy] autorelease]) {
				[self removeFromFlashSet:listContact];
			}
			
			//Make our colors end up right (if we were on an off-flash) by updating all list objects
			[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
		} else if (!oldFlashUnviewedContentEnabled && flashUnviewedContentEnabled) {
			if (!firstTime) {
				//Update all list objects so we start flashing
				[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
			}
		}
	}
}

@end
