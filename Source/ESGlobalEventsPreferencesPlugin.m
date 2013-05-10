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

#import "AISoundController.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESGlobalEventsPreferences.h"
#import "ESGlobalEventsPreferencesPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AISoundSet.h>

#define	NEW_PRESET_NAME				AILocalizedString(@"New Event Set",nil)

#define KEY_STORED_EVENT_PRESETS	@"Event Presets"
#define	KEY_EVENT_SET_NAME			@"Name"
#define KEY_ORDER_INDEX				@"OrderIndex"
#define KEY_NEXT_ORDER_INDEX		@"NextOrderIndex"

#define EVENT_SOUNDS_DEFAULT_PREFS	@"EventSoundDefaults"

@interface ESGlobalEventsPreferencesPlugin ()
- (void)_activateSet:(NSArray *)setArray withActionID:(NSString *)actionID alertGenerationSelector:(SEL)selector;

- (void)adiumFinishedLaunching:(NSNotification *)notification;
@end

@implementation ESGlobalEventsPreferencesPlugin

- (void)installPlugin
{
	NSString	*activeEventSet;
	
	builtInEventPresets = [[NSDictionary dictionaryNamed:@"BuiltInEventPresets" forClass:[self class]] retain];
	storedEventPresets = [[adium.preferenceController preferenceForKey:KEY_STORED_EVENT_PRESETS
																   group:PREF_GROUP_EVENT_PRESETS] mutableCopy];
	if (!storedEventPresets) storedEventPresets = [[NSMutableDictionary alloc] init];

	/* If there is no active event set, or the active event set is not present in our built in or stored event sets
	 * then we are in one of two conditions: either this is a first-launch, or the user has deleted the event preferences.
	 * Either way, we want to set ourselves to the default notification set before proceeding.
	 */
	activeEventSet = [adium.preferenceController preferenceForKey:KEY_ACTIVE_EVENT_SET
															  group:PREF_GROUP_EVENT_PRESETS];
	if (!activeEventSet || (![builtInEventPresets objectForKey:activeEventSet] &&
						   ![storedEventPresets objectForKey:activeEventSet])) {
		[self setEventPreset:[builtInEventPresets objectForKey:@"Default Notifications"]];		
	}

	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:EVENT_SOUNDS_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_SOUNDS];

	//Install our preference view
    preferences = [(ESGlobalEventsPreferences *)[ESGlobalEventsPreferences preferencePaneForPlugin:self] retain];

	//Wait for Adium to finish launching before we perform further actions
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:AIApplicationDidFinishLoadingNotification
									 object:nil];	
}

- (void)uninstallPlugin
{
    //Uninstall our observers
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:AIApplicationDidFinishLoadingNotification
										object:nil];
}


//Called when the preferences change, reregister for the notifications
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{

}

#pragma mark Sound Sets
+ (NSDictionary *)soundAlertForKey:(NSString *)key inSoundsDict:(NSDictionary *)sounds
{
	NSDictionary	*soundAlert = nil;
	NSString		*event;

	if (key &&
		(event = [adium.contactAlertsController eventIDForEnglishDisplayName:key])) {
		soundAlert = [NSDictionary dictionaryWithObjectsAndKeys:event, KEY_EVENT_ID,
			SOUND_ALERT_IDENTIFIER, KEY_ACTION_ID, 
			[NSDictionary dictionaryWithObject:[sounds objectForKey:key] forKey: KEY_ALERT_SOUND_PATH], KEY_ACTION_DETAILS,
			nil];
	}
	
	return soundAlert;
}

/*!
* @brief Apply a sound set
 */
- (void)applySoundSet:(AISoundSet *)soundSet
{
	[adium.preferenceController delayPreferenceChangedNotifications:YES];
	
	//Clear out old global sound alerts
	[adium.contactAlertsController removeAllGlobalAlertsWithActionID:SOUND_ALERT_IDENTIFIER];

	AILog(@"Applying sound set %@",soundSet);

	//
	NSDictionary *sounds = [soundSet sounds];
	for (NSString *key in sounds) {
		NSDictionary *soundAlert = [ESGlobalEventsPreferencesPlugin soundAlertForKey:key
																		inSoundsDict:sounds];
		if (soundAlert) {
			[adium.contactAlertsController addGlobalAlert:soundAlert];
		}
	}
	
	[adium.preferenceController delayPreferenceChangedNotifications:NO];
}

#pragma mark All simple presets

- (void)_activateSet:(NSArray *)setArray withActionID:(NSString *)actionID alertGenerationSelector:(SEL)selector
{
	NSDictionary	*dictionary;
	
	//Clear out old global dock behavior alerts
	[adium.contactAlertsController removeAllGlobalAlertsWithActionID:actionID];
	
	//
	for (dictionary in setArray) {
		[adium.contactAlertsController addGlobalAlert:[self performSelector:selector
																   withObject:dictionary]];
	}
}

- (void)setEventPreset:(NSDictionary *)eventPreset
{
	[adium.preferenceController delayPreferenceChangedNotifications:YES];

	[adium.contactAlertsController setAllGlobalAlerts:[eventPreset objectForKey:@"Events"]];
	
	/* For a built in set, we now should apply the sound set it specified. User-created sets already include the
	 * soundset as individual events.
	 */
	if ([eventPreset objectForKey:@"Built In"] && [[eventPreset objectForKey:@"Built In"] boolValue]) {
		NSString	*soundSet = [eventPreset objectForKey:KEY_EVENT_SOUND_SET];
		[self applySoundSet:(soundSet ? [AISoundSet soundSetWithContentsOfFile:[soundSet stringByExpandingBundlePath]] : nil)];
	}
	
	[adium.preferenceController delayPreferenceChangedNotifications:NO];

	//Set the name of the now-active event set, which includes sounds and all other events
	[adium.preferenceController setPreference:[eventPreset objectForKey:KEY_EVENT_SET_NAME]
										 forKey:KEY_ACTIVE_EVENT_SET
										  group:PREF_GROUP_EVENT_PRESETS];
}

- (CGFloat)nextOrderIndex
{
	NSNumber *nextOrderIndexNumber = [adium.preferenceController preferenceForKey:KEY_NEXT_ORDER_INDEX
																			  group:PREF_GROUP_EVENT_PRESETS];
	CGFloat	nextOrderIndex;
	
	nextOrderIndex = (nextOrderIndexNumber ? (CGFloat)[nextOrderIndexNumber doubleValue] : 1.0f);
	
	[adium.preferenceController setPreference:[NSNumber numberWithDouble:(nextOrderIndex + 1)]
										 forKey:KEY_NEXT_ORDER_INDEX
										  group:PREF_GROUP_EVENT_PRESETS];	

	return nextOrderIndex;
}

/*!
 * @brief Save an event preset
 *
 * This will assign an order index to the preset if necessary and then save it to the stored event presets dictionary.
 * If a preset with the same name exists, it will be overwritten
 */
- (void)saveEventPreset:(NSMutableDictionary *)eventPreset
{
	NSString	*name = [eventPreset objectForKey:KEY_EVENT_SET_NAME];
	//Assign the next order index to this preset if it doesn't have one yet
	if (![eventPreset objectForKey:KEY_ORDER_INDEX]) {
		[eventPreset setObject:[NSNumber numberWithDouble:[self nextOrderIndex]]
						forKey:KEY_ORDER_INDEX];
	}

	//If we don't have a name at this point, simply assign one
	if (!name) {
		name = NEW_PRESET_NAME;
		
		//Make sure we're not using a name which is already in use
		if ([storedEventPresets objectForKey:name]) {
			NSUInteger i = 1;
			name = [NEW_PRESET_NAME stringByAppendingFormat:@" (%lu)",i];
			
			while ([storedEventPresets objectForKey:name] != nil) {
				i++;
				name = [NEW_PRESET_NAME stringByAppendingFormat:@" (%lu)",i];
			}
		}
		
		NSAssert(name != nil, @"name is nil");
		[eventPreset setObject:name
						forKey:KEY_EVENT_SET_NAME];
	}
	
	NSAssert(eventPreset != nil, @"eventPreset is nil");
	[storedEventPresets setObject:eventPreset
						   forKey:name];

	[adium.preferenceController setPreference:storedEventPresets
										 forKey:KEY_STORED_EVENT_PRESETS
										  group:PREF_GROUP_EVENT_PRESETS];
}

/*!
 * @brief Delete an event preset
 */
- (void)deleteEventPreset:(NSDictionary *)eventPreset
{
	[storedEventPresets removeObjectForKey:[eventPreset objectForKey:KEY_EVENT_SET_NAME]];
	
	[adium.preferenceController setPreference:storedEventPresets
										 forKey:KEY_STORED_EVENT_PRESETS
										  group:PREF_GROUP_EVENT_PRESETS];	
}

- (NSDictionary *)builtInEventPresets
{
	return builtInEventPresets;
}

- (NSDictionary *)storedEventPresets
{
	return storedEventPresets;
}

NSInteger eventPresetsSort(id eventPresetA, id eventPresetB, void *context)
{
	CGFloat orderIndexA = (CGFloat)[[eventPresetA objectForKey:KEY_ORDER_INDEX] doubleValue];
	CGFloat orderIndexB = (CGFloat)[[eventPresetB objectForKey:KEY_ORDER_INDEX] doubleValue];
	
	if (orderIndexA > orderIndexB) {
		return NSOrderedDescending;
	} else if (orderIndexA < orderIndexB) {
		return NSOrderedAscending;
	} else {
		return [[eventPresetA objectForKey:KEY_EVENT_SET_NAME] caseInsensitiveCompare:[eventPresetB objectForKey:KEY_EVENT_SET_NAME]];
	}
}

- (NSArray *)storedEventPresetsArray
{
	return [[storedEventPresets allValues] sortedArrayUsingFunction:eventPresetsSort
															 context:nil];
}

- (NSArray *)builtInEventPresetsArray
{
	return [[builtInEventPresets allValues] sortedArrayUsingFunction:eventPresetsSort
															 context:nil];
}

@end
