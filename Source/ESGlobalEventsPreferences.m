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
#import "Adium/ESContactAlertsViewController.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESGlobalEventsPreferences.h"
#import "ESGlobalEventsPreferencesPlugin.h"
#import <Adium/ESPresetManagementController.h>
#import <Adium/ESPresetNameSheetController.h>
#import <Adium/AISoundSet.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIVariableHeightOutlineView.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>

#define PREF_GROUP_EVENT_PRESETS	@"Event Presets"
#define CUSTOM_TITLE				AILocalizedString(@"Custom",nil)
#define COPY_IN_PARENTHESIS			AILocalizedString(@"(Copy)","Copy, in parenthesis, as a noun indicating that the preceding item is a duplicate")

#define VOLUME_SOUND_PATH   [NSString pathWithComponents:[NSArray arrayWithObjects: \
	@"/", @"System", @"Library", @"LoginPlugins", \
	[@"BezelServices" stringByAppendingPathExtension:@"loginPlugin"], \
	@"Contents", @"Resources", \
	[@"volume" stringByAppendingPathExtension:@"aiff"], \
	nil]]

@interface ESGlobalEventsPreferences ()
- (void)popUp:(NSPopUpButton *)inPopUp shouldShowCustom:(BOOL)showCustom;
- (void)xtrasChanged:(NSNotification *)notification;
- (void)contactAlertsDidChangeForActionID:(NSString *)actionID;
- (NSMenu *)eventPresetsMenu;
- (IBAction)selectSoundSet:(id)sender;
- (NSMenu *)_soundSetMenu;
- (NSString *)_localizedTitle:(NSString *)englishTitle;
- (void)saveCurrentEventPreset;
- (void)setAndConfigureEventPresetsMenu;
- (void)updateSoundSetSelection;
- (void)updateSoundSetSelectionForSoundSet:(AISoundSet *)soundSet;

- (void)selectEventPreset:(id)sender;
- (void)addNewPreset:(id)sender;
- (void)editPresets:(id)sender;
- (void)showPresetCopySheet:(NSString *)originalPresetName;
@end

@implementation ESGlobalEventsPreferences
- (AIPreferenceCategory)category{
	return AIPref_Events;
}
- (NSString *)paneIdentifier
{
	return @"Events";
}
- (NSString *)paneName{	
    return AILocalizedString(@"Events", "Name of preferences and tab for specifying what Adium should do when events occur - for example, display a Growl alert when John signs on.");
}
/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"GlobalEventsPreferences";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-events" forClass:[self class]];
}

- (BOOL)resizableHorizontally
{
	return YES;
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	//Configure our global contact alerts view controller
	[contactAlertsViewController setConfigureForGlobal:YES];
	[contactAlertsViewController setDelegate:self];
	[contactAlertsViewController setShowEventsInEditSheet:NO];
	
	//Observe for installation of new sound sets and set up the sound set menu
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];

	//This will build the sound set menu
	[self xtrasChanged:nil];	

	//Presets menu
	[self setAndConfigureEventPresetsMenu];

	//And event presets to update our presets menu
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_PRESETS];

	//Ensure the correct sound set is selected
	[self updateSoundSetSelection];
	
	//Volume
	[slider_volume setDoubleValue:[[adium.preferenceController preferenceForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
																		   group:PREF_GROUP_SOUNDS] doubleValue]];	
}

- (void)localizePane
{
	[[button_minvolume cell] accessibilitySetOverrideValue:AILocalizedString(@"Set minimum volume", "Accessibility label for button to set to the minimum sound volume")
									   forAttribute:NSAccessibilityDescriptionAttribute];
	[[button_maxvolume cell] accessibilitySetOverrideValue:AILocalizedString(@"Set maximum volume", "Accessibility label for button to set to the maximum sound volume")
									   forAttribute:NSAccessibilityDescriptionAttribute];
	[[slider_volume cell] accessibilitySetOverrideValue:AILocalizedString(@"Volume", "Accessibility label for the sound volume slider")
										   forAttribute:NSAccessibilityDescriptionAttribute];
	 
	[label_eventPreset setLocalizedString:AILocalizedString(@"Event preset:",nil)];
	[label_soundSet setLocalizedString:AILocalizedString(@"Sound set:",nil)];
}

/*!
 * @brief Preference view is closing
 */
- (void)viewWillClose
{
	[contactAlertsViewController viewWillClose];
	contactAlertsViewController = nil;

	[adium.preferenceController unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief PREF_GROUP_CONTACT_ALERTS changed; update our summary data
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_EVENT_PRESETS]) {
		if (!key || [key isEqualToString:@"Event Presets"]) {
			//Update when the available event presets change
			[self setAndConfigureEventPresetsMenu];
		}
	}
}

/*!
 * @brief Set if a popup should have a "Custom" menu item
 */
- (void)popUp:(NSPopUpButton *)inPopUp shouldShowCustom:(BOOL)showCustom
{
	NSMenuItem	*lastItem = [inPopUp lastItem];
	BOOL		customIsShowing = (lastItem && (![lastItem representedObject] &&
												[[lastItem title] isEqualToString:CUSTOM_TITLE]));
	if (showCustom && !customIsShowing) {
		//Add 'custom' then select it
		[[inPopUp menu] addItem:[NSMenuItem separatorItem]];
		[[inPopUp menu] addItemWithTitle:CUSTOM_TITLE
								  target:nil
								  action:nil
						   keyEquivalent:@""];
		[inPopUp selectItem:[inPopUp lastItem]];

	} else if (!showCustom && customIsShowing) {
		//If it currently has a 'custom' item listed, remove it and the separator above it
		[inPopUp removeItemAtIndex:([inPopUp numberOfItems]-1)];
		[inPopUp removeItemAtIndex:([inPopUp numberOfItems]-1)];
	}
}

/*!
 * @brief Update our soundset menu if a new sound set is instaled
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if (!notification || [[notification object] caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame) {		
		//Build the soundset menu
		[popUp_soundSet setMenu:[self _soundSetMenu]];		
	}
}

#pragma mark Event presets

/*!
 * @brief Buld and return the event presets menu
 *
 * The menu will have built in presets, a divider, user-set presets, a divider, and then the preset management item(s)
 */
- (NSMenu *)eventPresetsMenu
{
	NSMenu			*eventPresetsMenu = [[NSMenu alloc] init];
	NSDictionary	*eventPreset;
	NSMenuItem		*menuItem;
	
	//Built in event presets
	for (eventPreset in [plugin builtInEventPresetsArray]) {
		NSString		*name = [eventPreset objectForKey:@"Name"];
		
		//Add a menu item for the set
		menuItem = [[NSMenuItem alloc] initWithTitle:[self _localizedTitle:name]
																		 target:self
																		 action:@selector(selectEventPreset:)
																  keyEquivalent:@""];
		[menuItem setRepresentedObject:eventPreset];
		[eventPresetsMenu addItem:menuItem];
	}
	
	NSArray	*storedEventPresetsArray = [plugin storedEventPresetsArray];
	
	if ([storedEventPresetsArray count]) {
		[eventPresetsMenu addItem:[NSMenuItem separatorItem]];
		
		for (eventPreset in storedEventPresetsArray) {
			NSString		*name = [eventPreset objectForKey:@"Name"];
			
			//Add a menu item for the set
			menuItem = [[NSMenuItem alloc] initWithTitle:name
																			 target:self
																			 action:@selector(selectEventPreset:)
																	  keyEquivalent:@""];
			[menuItem setRepresentedObject:eventPreset];
			[eventPresetsMenu addItem:menuItem];
		}
	}
	
	//Edit Presets
	[eventPresetsMenu addItem:[NSMenuItem separatorItem]];

	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Add New Preset",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(addNewPreset:)
															  keyEquivalent:@""];
	[eventPresetsMenu addItem:menuItem];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Edit Presets",nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(editPresets:)
															  keyEquivalent:@""];
	[eventPresetsMenu addItem:menuItem];
		
	return eventPresetsMenu;
}

- (void)selectActiveEventInPopUp
{
	NSString	*activeEventSetName = [adium.preferenceController preferenceForKey:KEY_ACTIVE_EVENT_SET
																			   group:PREF_GROUP_EVENT_PRESETS];

	//First try to set the localized version
	[popUp_eventPreset selectItemWithTitle:[self _localizedTitle:activeEventSetName]];
	//If that fails, look for one exactly matching
	if (![popUp_eventPreset selectedItem]) [popUp_eventPreset selectItemWithTitle:activeEventSetName];
	//And if that fails, select the first item (something went wrong, we should at least have a selection)
	if (![popUp_eventPreset selectedItem]) [popUp_eventPreset selectItemAtIndex:0];	
}

- (void)setAndConfigureEventPresetsMenu
{
	[popUp_eventPreset setMenu:[self eventPresetsMenu]];
	[self selectActiveEventInPopUp];
}

/*!
 * @brief Selected an event preset
 *
 * Pass it to the plugin, which will perform necessary changes to our contact alerts
 */
- (void)selectEventPreset:(id)sender
{
	NSDictionary	*eventPreset = [sender representedObject];
	[plugin setEventPreset:eventPreset];

	[self updateSoundSetSelection];
}

/*
 * Add a new preset
 *
 * Called by the "Add New preset..." menu item.  Functions the same as duplicate from the preset management, duplicating
 * the current event set with a new name.
 */
- (void)addNewPreset:(id)sender
{
	NSString	*defaultName;
	NSString	*explanatoryText;
	
	defaultName = [NSString stringWithFormat:@"%@ %@",
		[self _localizedTitle:[adium.preferenceController preferenceForKey:KEY_ACTIVE_EVENT_SET
																	   group:PREF_GROUP_EVENT_PRESETS]],
		COPY_IN_PARENTHESIS];
	explanatoryText = AILocalizedString(@"Enter a unique name for this new event set.",nil);

	ESPresetNameSheetController *presetNameSheetController = [[ESPresetNameSheetController alloc] initWithDefaultName:defaultName
																									  explanatoryText:explanatoryText
																									  notifyingTarget:self
																											 userInfo:nil];
	[presetNameSheetController showOnWindow:[[self view] window]];

	//Get our event presets menu back to its proper selection
	[self selectActiveEventInPopUp];
}

/*!
 * @brief Manage presets
 *
 * Called by the "Edit Presets..." menu item
 */
- (void)editPresets:(id)sender
{
	ESPresetManagementController *presentManagementController = [[ESPresetManagementController alloc] initWithPresets:[plugin storedEventPresetsArray]
																										   namedByKey:@"Name"
																										 withDelegate:self];
	[presentManagementController showOnWindow:[[self view] window]];

	//Get our event presets menu back to its proper selection
	[self selectActiveEventInPopUp];
}

- (BOOL)allowDeleteOfPreset:(NSDictionary *)preset
{
	NSString	*name = [preset objectForKey:@"Name"];
	NSString	*localizedTitle;
	
	localizedTitle = [self _localizedTitle:[adium.preferenceController preferenceForKey:KEY_ACTIVE_EVENT_SET
																					group:PREF_GROUP_EVENT_PRESETS]];
	//Don't allow the active preset to be deleted
	return (![localizedTitle isEqualToString:name]);
}

- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)newName inPresets:(NSArray *)presets renamedPreset:(id *)renamedPreset
{
	NSString				*oldPresetName = [preset objectForKey:@"Name"];
	NSMutableDictionary		*newPreset = [preset mutableCopy];
	NSString				*localizedCurrentName = [self _localizedTitle:[adium.preferenceController preferenceForKey:KEY_ACTIVE_EVENT_SET
																												   group:PREF_GROUP_EVENT_PRESETS]];
	[newPreset setObject:newName
				  forKey:@"Name"];

	//Mark the newly created (but still functionally identical) event set as active if the old one was active
	if ([localizedCurrentName isEqualToString:oldPresetName]) {
		[adium.preferenceController setPreference:newName
											 forKey:KEY_ACTIVE_EVENT_SET
											  group:PREF_GROUP_EVENT_PRESETS];
	}
	
	//Remove the original one from the array, and add the newly-renamed one
	[plugin deleteEventPreset:preset];
	[plugin saveEventPreset:newPreset];
	
	if (renamedPreset) *renamedPreset = newPreset;

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset
{
	NSMutableDictionary	*newEventPreset = [preset mutableCopy];
	NSString			*newName = [NSString stringWithFormat:@"%@ %@", [preset objectForKey:@"Name"], COPY_IN_PARENTHESIS];
	[newEventPreset setObject:newName
					   forKey:@"Name"];
	
	//Remove the original preset's order index
	[newEventPreset removeObjectForKey:@"OrderIndex"];
	
	//Now save the new preset
	[plugin saveEventPreset:newEventPreset];

	//Return the created duplicate by reference
	if (duplicatePreset != NULL) *duplicatePreset = newEventPreset;

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets
{
	//Remove the preset
	[plugin deleteEventPreset:preset];
	
	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

- (NSArray *)movePreset:(NSDictionary *)preset toIndex:(NSUInteger)idx inPresets:(NSArray *)presets presetAfterMove:(id *)presetAfterMove
{
	NSMutableDictionary	*newEventPreset = [preset mutableCopy];
	CGFloat newOrderIndex;
	if (idx == 0) {		
		newOrderIndex = (CGFloat)[[[presets objectAtIndex:0] objectForKey:@"OrderIndex"] doubleValue] / 2.0f;

	} else if (idx < [presets count]) {
		CGFloat above = (CGFloat)[[[presets objectAtIndex:idx-1] objectForKey:@"OrderIndex"] doubleValue];
		CGFloat below = (CGFloat)[[[presets objectAtIndex:idx] objectForKey:@"OrderIndex"] doubleValue];
		newOrderIndex = ((above + below) / 2.0f);

	} else {
		newOrderIndex = [plugin nextOrderIndex];
	}
	
	[newEventPreset setObject:[NSNumber numberWithDouble:newOrderIndex]
					   forKey:@"OrderIndex"];
			 
	//Now save the new preset
	[plugin saveEventPreset:newEventPreset];
	if (presetAfterMove != NULL) *presetAfterMove = newEventPreset;

	//Return an updated presets array
	return [plugin storedEventPresetsArray];
}

#pragma mark Contact alerts changed by user
- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   updatedAlert:(NSDictionary *)newAlert
						   oldAlert:(NSDictionary *)oldAlert
{	
	[self contactAlertsDidChangeForActionID:[newAlert objectForKey:KEY_ACTION_ID]];
}

- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   deletedAlert:(NSDictionary *)deletedAlert
{
	[self contactAlertsDidChangeForActionID:[deletedAlert objectForKey:KEY_ACTION_ID]];	
}

/*!
 * @brief Contact alerts were changed by the user
 */
- (void)contactAlertsDidChangeForActionID:(NSString *)actionID
{
	if (!actionID ||
		[actionID isEqualToString:SOUND_ALERT_IDENTIFIER]) {
		
		NSArray			*alertsArray = [adium.contactAlertsController alertsForListObject:nil
																				withEventID:nil
																				   actionID:SOUND_ALERT_IDENTIFIER];
		NSMenuItem		*soundMenuItem;
		
		if (![alertsArray count]) {
			//We can select "None" if there are no sounds
			soundMenuItem = (NSMenuItem *)[popUp_soundSet itemWithTitle:@"None"];

		} else {
			/* Otherwise, check to see if we remain in our proper soundset.
			 * Note that this won't detect if we return to a soundset, but that'd be an expensive search.
			 */
			soundMenuItem = (NSMenuItem *)[popUp_soundSet selectedItem];

			AISoundSet		*soundSet = [soundMenuItem representedObject];
			NSString		*key;
			NSDictionary	*sounds = [soundSet sounds];

			if ([alertsArray count] && ![sounds count]) {
				//If we have one or more sound alerts and there are no sounds in this sound set ("None" sound set), there's no matching soundSetMenuitem.
				soundMenuItem = nil;

			} else {
				//First, check to see if any sounds which are present within this sound set have been changed
				for (key in sounds) {
					NSDictionary *soundAlert = [ESGlobalEventsPreferencesPlugin soundAlertForKey:key
																					inSoundsDict:sounds];
					if (![alertsArray containsObject:soundAlert]) {
						soundMenuItem = nil;
						break;
					}
				}
				
				//Next, see if any sounds not present within this sound set have been added
				if (soundMenuItem) {
					NSDictionary	*alertDict;
					for (alertDict in alertsArray) {
						if ([[alertDict objectForKey:KEY_ACTION_ID] isEqualToString:SOUND_ALERT_IDENTIFIER]) {
							NSString *englishEvent = [adium.contactAlertsController eventIDForEnglishDisplayName:key];
							/*
							 * If the sounds dictionary has no action for this event, or it has one but
							 * it is for a different sound than specified, the sound set has been changed
							 */
							if (![sounds objectForKey:englishEvent] ||
								![[[alertDict objectForKey:KEY_ACTION_DETAILS] objectForKey:KEY_ALERT_SOUND_PATH] isEqualToString:[sounds objectForKey:englishEvent]]) {
								soundMenuItem = nil;
								break;
							}
						}
					}
				}

			}
		}

		[self selectSoundSet:([soundMenuItem representedObject] ? soundMenuItem : nil)];

	} else {
		[self saveCurrentEventPreset];
	}
}

#pragma mark Sound sets
/*!
 * @brief Called when an item in the sound set popUp is selected.
 *
 * Also called after the user changes sounds manually, by -[ESGlobalEventsPreferences contactAlertsDidChangeForActionID].
 */
- (IBAction)selectSoundSet:(id)sender
{
	//Apply the sound set so its events are in the current alerts.
	if (sender) {
		[plugin applySoundSet:[sender representedObject]];
	}

	/* Update the selection, which will select Custom as appropriate.  This must be done before saving the event
	 * preset so the menu is on the correct sound set to save.
	 */
	[self updateSoundSetSelectionForSoundSet:[sender representedObject]];

	/* Save the preset which is now updated to have the appropriate sounds; 
	 * in saving, the name of the soundset, or @"", will also be saved.
	 */
	[self saveCurrentEventPreset];
}

/*!
 * @brief Revert the event set to how it was before the last attempted operation
 */
- (void)revertToSavedEventSet
{
	NSDictionary		*eventPreset;

	[self selectActiveEventInPopUp];
	eventPreset = [[popUp_eventPreset selectedItem] representedObject];

	[plugin setEventPreset:eventPreset];
	
	//Ensure the correct sound set is selected
	[self updateSoundSetSelection];
}

/*!
 * @brief Build and return the event set as it should be saved
 */
- (NSMutableDictionary *)currentEventSetForSaving
{
	NSDictionary		*eventPreset = [[popUp_eventPreset selectedItem] representedObject];
	NSMutableDictionary	*currentEventSetForSaving = [eventPreset mutableCopy];
	
	//Set the sound set, which is just stored here for ease of preference pane display
	NSString			*soundSetName = [[[popUp_soundSet selectedItem] representedObject] name];
	if (soundSetName) {
		[currentEventSetForSaving setObject:soundSetName
									 forKey:KEY_EVENT_SOUND_SET];
	} else {
		[currentEventSetForSaving removeObjectForKey:KEY_EVENT_SOUND_SET];
	}
	
	//Get and store the alerts array
	NSArray				*alertsArray = [adium.contactAlertsController alertsForListObject:nil
																				withEventID:nil
																				   actionID:nil];
	[currentEventSetForSaving setObject:alertsArray forKey:@"Events"];

	//Ensure this set doesn't claim to be built in.
	[currentEventSetForSaving removeObjectForKey:@"Built In"];
	
	return currentEventSetForSaving;
}

#pragma mark Volume
//New value selected on the volume slider or chosen by clicking a volume icon
- (IBAction)selectVolume:(id)sender
{
    CGFloat			volume, oldVolume;
	
	if (sender == slider_volume) {
		volume = (CGFloat)[slider_volume doubleValue];
	} else if (sender == button_maxvolume) {
		volume = (CGFloat)[slider_volume maxValue];
		[slider_volume setDoubleValue:volume];
	} else if (sender == button_minvolume) {
		volume = (CGFloat)[slider_volume minValue];
		[slider_volume setDoubleValue:volume];
	} else {
		volume = 0;
	}
	
	NSNumber *oldVolumeValue = [adium.preferenceController preferenceForKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
																		group:PREF_GROUP_SOUNDS];
	oldVolume = (oldVolumeValue ? (CGFloat)[oldVolumeValue doubleValue] : -1.0f);
	
    //Volume
    if (volume != oldVolume) {
        [adium.preferenceController setPreference:[NSNumber numberWithDouble:volume]
                                             forKey:KEY_SOUND_CUSTOM_VOLUME_LEVEL
                                              group:PREF_GROUP_SOUNDS];
		
		//Play a sample sound
        [adium.soundController playSoundAtPath:VOLUME_SOUND_PATH];
    }
}

#pragma mark Preset saving

/*!
 * @brief Save the current event preset
 *
 * Called after each event change to immediately update the current preset.
 * If a built-in preset is currently selected, this method will prompt for a new name before saving.
 */
- (void)saveCurrentEventPreset
{
	NSDictionary		*eventPreset = [[popUp_eventPreset selectedItem] representedObject];

	if ([eventPreset objectForKey:@"Built In"] && [[eventPreset objectForKey:@"Built In"] boolValue]) {
		/* Perform after a delay so that if we got here as a result of a sheet-based add or edit of an event
		 * the sheet will close before we try to open a new one. */
		[self performSelector:@selector(showPresetCopySheet:)
				   withObject:[self _localizedTitle:[eventPreset objectForKey:@"Name"]]
				   afterDelay:0];
	} else {	
		//Now save the current settings
		[plugin saveEventPreset:[self currentEventSetForSaving]];
	}		
}

/*!
 * @brief Show the sheet for naming the preset created by an attempt to modify a built-in set
 *
 * @param originalPresetName The name of the original set, used as a base for the new name.
 */
- (void)showPresetCopySheet:(NSString *)originalPresetName
{
	NSString	*defaultName;
	NSString	*explanatoryText;
	
	defaultName = [NSString stringWithFormat:@"%@ %@", originalPresetName, COPY_IN_PARENTHESIS];
	explanatoryText = AILocalizedString(@"You are editing a default event set.  Please enter a unique name for your modified set.",nil);
	
	ESPresetNameSheetController *presetNameSheetController = [[ESPresetNameSheetController alloc] initWithDefaultName:defaultName
													explanatoryText:explanatoryText
													notifyingTarget:self
														   userInfo:nil];
	[presetNameSheetController showOnWindow:[[self view] window]];
}

- (BOOL)presetNameSheetController:(ESPresetNameSheetController *)controller
			  shouldAcceptNewName:(NSString *)newName
						 userInfo:(id)userInfo
{
	return (![[[plugin builtInEventPresets] allKeys] containsObject:newName] &&
		   ![[[plugin storedEventPresets] allKeys] containsObject:newName]);
}
	
- (void)presetNameSheetControllerDidEnd:(ESPresetNameSheetController *)controller 
							 returnCode:(ESPresetNameSheetReturnCode)returnCode
								newName:(NSString *)newName
							   userInfo:(id)userInfo
{
	switch (returnCode) {
		case ESPresetNameSheetOkayReturn:
		{
			//XXX error if overwriting existing set?
			NSMutableDictionary	*newEventPreset = [self currentEventSetForSaving];
			[newEventPreset setObject:newName
							   forKey:@"Name"];
			
			//Now save the current settings
			[plugin saveEventPreset:newEventPreset];
			
			//Presets menu
			[adium.preferenceController setPreference:newName
												 forKey:KEY_ACTIVE_EVENT_SET
												  group:PREF_GROUP_EVENT_PRESETS];
			[popUp_eventPreset setMenu:[self eventPresetsMenu]];
			[popUp_eventPreset selectItemWithTitle:newName];
			
			break;
		}
		case ESPresetNameSheetCancelReturn:
		{
			[self revertToSavedEventSet];
			break;
		}
	}
}
		
/*!
 * @brief Called when the OK button on the preset copy sheet is pressed
 *
 * Save the current event set under the name specified by [textField_name stringValue].
 * Set the name of the active event set to this new name, and ensure our menu is up to date.
 *
 * Also, close the sheet.
 */
- (IBAction)selectedNameForPresetCopy:(id)sender
{
	
}

- (void)updateSoundSetSelectionForSoundSet:(AISoundSet *)soundSet
{
	if (soundSet) {
		[popUp_soundSet selectItemWithRepresentedObject:soundSet];
		
		[self popUp:popUp_soundSet shouldShowCustom:NO];
		
	} else {
		[self popUp:popUp_soundSet shouldShowCustom:YES];
	}
}

- (void)updateSoundSetSelection
{
    AISoundSet		*soundSet;
	NSString		*name;

	name = [[[popUp_eventPreset selectedItem] representedObject] objectForKey:KEY_EVENT_SOUND_SET];
	name = [[name lastPathComponent] stringByDeletingPathExtension];

    for (soundSet in [adium.soundController soundSets]) {
		if ([[soundSet name] isEqualToString:name]) break;
	}

	[self updateSoundSetSelectionForSoundSet:soundSet];
}

#define NONE AILocalizedString(@"None",nil)
/*!
 * @brief Build and return a menu of sound set choices
 *
 * The menu items have an action of -[self selectSoundSet:].
 */
- (NSMenu *)_soundSetMenu
{
    NSMenu			*soundSetMenu = [[NSMenu alloc] init];
	NSMutableArray	*menuItemArray = [NSMutableArray array];
    NSMenuItem		*menuItem, *noneMenuItem = nil;

    for (AISoundSet *soundSet in [adium.soundController soundSets]) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[self _localizedTitle:[soundSet name]]
											  target:self
											  action:@selector(selectSoundSet:)
									   keyEquivalent:@""
								   representedObject:soundSet];
		
		if ([[menuItem title] isEqualToString:NONE]) {
			noneMenuItem = menuItem;

		} else {
			[menuItemArray addObject:menuItem];
		}
	}
	
	[menuItemArray sortUsingSelector:@selector(titleCompare:)];
	
	for (menuItem in menuItemArray) {
		[soundSetMenu addItem:menuItem];
	}

	if (noneMenuItem) {
		[soundSetMenu addItem:[NSMenuItem separatorItem]];
		[soundSetMenu addItem:noneMenuItem];
	}
	
    return soundSetMenu;
}

#pragma mark Common menu methods
/*!
 * @brief Localized a menu item title for global events preferences
 *
 * @result The equivalent localized title if available; otherwise, the passed English title
 */
- (NSString *)_localizedTitle:(NSString *)englishTitle
{
	NSString	*localizedTitle = nil;
	
	if ([englishTitle isEqualToString:@"None"])
		localizedTitle = NONE;
	else if ([englishTitle isEqualToString:@"Default Notifications"])
		localizedTitle = AILocalizedString(@"Default Notifications",nil);
	else if ([englishTitle isEqualToString:@"Visual Notifications"])
		localizedTitle = AILocalizedString(@"Visual Notifications",nil);
	else if ([englishTitle isEqualToString:@"Audio Notifications"])
		localizedTitle = AILocalizedString(@"Audio Notifications",nil);

	return (localizedTitle ? localizedTitle : englishTitle);
}

@end
