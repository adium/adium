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

#define OFFLINE_IMAGE_OPACITY	0.5f
#define FULL_IMAGE_OPACITY		1.0f
#define	OPACITY_REFRESH			0.2f

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
						 KEY_TYPING, KEY_UNVIEWED_CONTENT,  @"listObjectStatusType", @"isIdle",
						 @"isOnline", @"signedOn",  @"signedOff", @"isMobile", nil];

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

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    NSSet		*modifiedAttributes = nil;

	if ([inObject isKindOfClass:[AIListContact class]] || [inObject isKindOfClass:[AIListBookmark class]]) {
		if (inModifiedKeys == nil || [inModifiedKeys intersectsSet:interestedKeysSet]) {
			//Update the contact's text color
			[self _applyColorToContact:(AIListContact *)inObject];
			modifiedAttributes = [NSSet setWithObjects:@"textColor", @"invertedTextColor", @"labelColor", nil];
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
	// Only in the case the other contact is typing or has unread contact should we apply it to the meta contact as well
	BOOL			applyToMetaToo = NO;

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
			applyToMetaToo = YES;
        }
    }

    //Offline, Signed off, signed on, or typing
    if ((!color && !labelColor)) {
		if (offlineEnabled && (!inContact.online &&
							  ![inContact boolValueForProperty:@"signedOff"])) {
			color = offlineColor;
			invertedColor = offlineInvertedColor;
			labelColor = offlineLabelColor;
			if (offlineImageFading) opacity = OFFLINE_IMAGE_OPACITY;			
			
		} else if (signedOffEnabled && [inContact boolValueForProperty:@"signedOff"]) {
            color = signedOffColor;
            invertedColor = signedOffInvertedColor;
            labelColor = signedOffLabelColor;
			isEvent = YES;

        } else if (signedOnEnabled && [inContact boolValueForProperty:@"signedOn"]) {
			color = signedOnColor;
            invertedColor = signedOnInvertedColor;
            labelColor = signedOnLabelColor;
			isEvent = YES;
			
        } else if (typingEnabled && ([inContact intValueForProperty:KEY_TYPING] == AITyping)) {
            color = typingColor;
            invertedColor = typingInvertedColor;
            labelColor = typingLabelColor;
			isEvent = YES;
			applyToMetaToo = YES;
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
			forProperty:@"textColor"
				 notify:NotifyNever];
    [inContact setValue:invertedColor
			forProperty:@"invertedTextColor"
				 notify:NotifyNever];
    [inContact setValue:labelColor
			forProperty:@"labelColor"
				 notify:NotifyNever];
	[inContact setValue:[NSNumber numberWithDouble:opacity]
			forProperty:@"imageOpacity"
				 notify:NotifyNever];
	[inContact setValue:[NSNumber numberWithBool:isEvent]
			forProperty:@"isEvent"
				 notify:NotifyNever];
	
	if (applyToMetaToo && [inContact metaContact]) {
		[[inContact metaContact] setValue:color
							  forProperty:@"textColor"
								   notify:NotifyNever];
		[[inContact metaContact] setValue:invertedColor
							  forProperty:@"invertedTextColor"
								   notify:NotifyNever];
		[[inContact metaContact] setValue:labelColor
							  forProperty:@"labelColor"
								   notify:NotifyNever];
		[[inContact metaContact] setValue:[NSNumber numberWithDouble:opacity]
							  forProperty:@"imageOpacity"
								   notify:NotifyNever];
		[[inContact metaContact] setValue:[NSNumber numberWithBool:isEvent]
							  forProperty:@"isEvent"
								   notify:NotifyNever];
	}
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    AIListContact	*object;

	NSSet *modifiedKeys = [NSSet setWithObjects:@"Text Color", @"Label Color", @"Inverted Text Color", nil];
	
    for (object in flashingListObjects) {
        [self _applyColorToContact:object];
        
		[[AIContactObserverManager sharedManager] listObjectAttributesChanged:object
																 modifiedKeys:modifiedKeys];
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

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_LIST_THEME]) {
		//Release the old values..
		signedOffColor = nil;
		signedOnColor = nil;
		awayColor = nil;
		idleColor = nil;
		typingColor = nil;
		unviewedContentColor = nil;
		onlineColor = nil;
		awayAndIdleColor = nil;
		offlineColor = nil;
		mobileColor = nil;
		
		signedOffInvertedColor = nil;
		signedOnInvertedColor = nil;
		awayInvertedColor = nil;
		idleInvertedColor = nil;
		typingInvertedColor = nil;
		unviewedContentInvertedColor = nil;
		onlineInvertedColor = nil;
		awayAndIdleInvertedColor = nil;
		offlineInvertedColor = nil;
		mobileInvertedColor = nil;
		
		awayLabelColor = nil;
		idleLabelColor = nil;
		signedOffLabelColor = nil;
		signedOnLabelColor = nil;
		typingLabelColor = nil;
		unviewedContentLabelColor = nil;
		onlineLabelColor = nil;
		awayAndIdleLabelColor = nil;
		offlineLabelColor = nil;
		mobileLabelColor = nil;
		
		if ((awayEnabled = [[prefDict objectForKey:KEY_AWAY_ENABLED] boolValue])) {
			awayColor = [[prefDict objectForKey:KEY_AWAY_COLOR] representedColor];
			awayLabelColor = [[prefDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor];
			awayInvertedColor = [awayColor colorWithInvertedLuminance];
		}
	
		if ((idleEnabled = [[prefDict objectForKey:KEY_IDLE_ENABLED] boolValue])) {
			idleColor = [[prefDict objectForKey:KEY_IDLE_COLOR] representedColor];
			idleLabelColor = [[prefDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor];
			idleInvertedColor = [idleColor colorWithInvertedLuminance];
		}

		if ((signedOnEnabled = [[prefDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue])) {
			signedOnColor = [[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor];	
			signedOnLabelColor = [[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor];
			signedOnInvertedColor = [signedOnColor colorWithInvertedLuminance];
		}
		
		if ((signedOffEnabled = [[prefDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue])) {
			signedOffColor = [[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor];
			signedOffLabelColor = [[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor];
			signedOffInvertedColor = [signedOffColor colorWithInvertedLuminance];
		}		
		
		if ((typingEnabled = [[prefDict objectForKey:KEY_TYPING_ENABLED] boolValue])) {
			typingColor = [[prefDict objectForKey:KEY_TYPING_COLOR] representedColor];
			typingLabelColor = [[prefDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor];			
			typingInvertedColor = [typingColor colorWithInvertedLuminance];
		}
		
		if ((unviewedContentEnabled = [[prefDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue])) {
			unviewedContentColor = [[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor];
			unviewedContentLabelColor = [[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor];
			unviewedContentInvertedColor = [unviewedContentColor colorWithInvertedLuminance];			
		}
		
		if ((onlineEnabled = [[prefDict objectForKey:KEY_ONLINE_ENABLED] boolValue])) {
			onlineColor = [[prefDict objectForKey:KEY_ONLINE_COLOR] representedColor];
			onlineLabelColor = [[prefDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor];
			onlineInvertedColor = [onlineColor colorWithInvertedLuminance];
		}

		if ((awayAndIdleEnabled = [[prefDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue])) {
			awayAndIdleColor = [[prefDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor];
			awayAndIdleLabelColor = [[prefDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor];
			awayAndIdleInvertedColor = [awayAndIdleColor colorWithInvertedLuminance];			
		}
		
		if ((offlineEnabled = [[prefDict objectForKey:KEY_OFFLINE_ENABLED] boolValue])) {
			offlineColor = [[prefDict objectForKey:KEY_OFFLINE_COLOR] representedColor];
			offlineLabelColor = [[prefDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColor];
			offlineInvertedColor = [offlineColor colorWithInvertedLuminance];			
		}
		
		if ((mobileEnabled = [[prefDict objectForKey:KEY_MOBILE_ENABLED] boolValue])) {
			mobileColor = [[prefDict objectForKey:KEY_MOBILE_COLOR] representedColor];		
			mobileLabelColor = [[prefDict objectForKey:KEY_LABEL_MOBILE_COLOR] representedColor];
			mobileInvertedColor = [mobileColor colorWithInvertedLuminance];			
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
			for (AIListContact *listContact in [flashingListObjects copy]) {
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
