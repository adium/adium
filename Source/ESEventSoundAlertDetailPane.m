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
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AISoundSet.h>
#import <Adium/AILocalizationTextField.h>

#define PLAY_A_SOUND			AILocalizedString(@"Play a sound",nil)
#define KEY_DEFAULT_SOUND_DICT	@"Default Sound Dict"

@interface ESEventSoundAlertDetailPane ()
- (NSMenu *)soundListMenu;
- (void)addSound:(NSString *)soundPath toMenu:(NSMenu *)soundMenu;
- (IBAction)selectSound:(id)sender;
@end

/*!
 * @class ESEventSoundAlertDetailPane
 * @brief Details pane for the Play Sound action
 */
@implementation ESEventSoundAlertDetailPane

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"EventSoundContactAlert";    
}

/*!
 * @brief Configure the detail view
 */
- (void)viewDidLoad
{
	[label_sound setLocalizedString:AILocalizedString(@"Sound:",nil)];

	/* Loading and using the real file icons is slow, and all the sound files should have the same icons anyway.  So
	 * we can cheat and load a sound icon from our bundle here (for all the menu items) for a nice speed boost. */
	if (!soundFileIcon) soundFileIcon = [[NSImage imageNamed:@"SoundFileIcon" forClass:[self class]] retain];
	
	//Prepare our sound menu
    [popUp_actionDetails setMenu:[self soundListMenu]];
	
	[super viewDidLoad];
}

/*!
 * @brief View will close
 */
- (void)viewWillClose
{
	//The user probably does not want the sound to continue playing (especially if it's long), so stop it.
	NSString		*soundPath = [[popUp_actionDetails selectedItem] representedObject];
	[adium.soundController stopPlayingSoundAtPath:soundPath];

	[soundFileIcon release]; soundFileIcon = nil;
	[super viewWillClose];
}

/*!
 * @brief Configure for the action
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	NSString	*selectedSound;
	NSInteger			soundIndex;
	
	if (!inDetails) inDetails = [adium.preferenceController preferenceForKey:KEY_DEFAULT_SOUND_DICT
																		group:PREF_GROUP_SOUNDS];

	//If the user has a custom sound selected, we need to create an entry in the menu for it
	selectedSound = [inDetails objectForKey:KEY_ALERT_SOUND_PATH];
	if (selectedSound) {
		if ([[popUp_actionDetails menu] indexOfItemWithRepresentedObject:selectedSound] == -1) {
			[self addSound:selectedSound toMenu:[popUp_actionDetails menu]];
		}
		
		//Set the menu to its previous setting if the stored event matches
		soundIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:[inDetails objectForKey:KEY_ALERT_SOUND_PATH]];
		if (soundIndex >= 0 && soundIndex < [popUp_actionDetails numberOfItems]) {
			[popUp_actionDetails selectItemAtIndex:soundIndex];        
		}
		
	} else {
		[popUp_actionDetails selectItemAtIndex:-1];
	}	
}

/*!
 * @brief Return our current configuration
 */
- (NSDictionary *)actionDetails
{
	NSString		*soundPath = [[popUp_actionDetails selectedItem] representedObject];
	NSDictionary	*actionDetails = nil;

	if (soundPath && [soundPath length]) {
		actionDetails = [NSDictionary dictionaryWithObject:soundPath forKey:KEY_ALERT_SOUND_PATH];
	}

	//Save the preferred settings for future use as defaults
	[adium.preferenceController setPreference:actionDetails
										 forKey:KEY_DEFAULT_SOUND_DICT
										  group:PREF_GROUP_SOUNDS];
	
	return actionDetails;
}


//Sound Menu -----------------------------------------------------------------------------------------------------------
#pragma mark Sound Menu
/*!
 * @brief Builds and returns a sound list menu
 *
 * The menu is organized by sound set.
 */
- (NSMenu *)soundListMenu
{
	NSMenu			*soundMenu = [[NSMenu alloc] init];
	NSMenuItem		*menuItem;
	
	//Add all soundsets to our menu
	for (AISoundSet *soundSet in adium.soundController.soundSets) {
		NSString        *soundSetName = nil;
		NSArray         *soundSetContents = nil;
		NSString        *soundPath;

		soundSetName = [soundSet name];
		soundSetContents = [[soundSet sounds] allValues];

		NSAssert1(soundSetName != nil, @"Sound set does not have a name: %@", soundSet);
		
		if (soundSetContents && [soundSetContents count]) {
			NSMenu	*soundsetMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];

			//Add an item for the set
			menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundSetName
																			 target:nil
																			 action:nil
																	  keyEquivalent:@""] autorelease];
			
			//Add an item for each sound
			for (soundPath in soundSetContents) {
				[self addSound:soundPath toMenu:soundsetMenu];
			}
			
			[menuItem setSubmenu:soundsetMenu];
			[soundsetMenu release];

			[soundMenu addItem:menuItem];
		}
	}

	//Add a divider between the sets and Other...
	[soundMenu addItem:[NSMenuItem separatorItem]];

	//Add the "Other..." item
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER_ELLIPSIS
																	 target:self
																	 action:@selector(selectSound:)
															  keyEquivalent:@""] autorelease];            
	[soundMenu addItem:menuItem];
	[soundMenu setAutoenablesItems:NO];
	
    return [soundMenu autorelease];
}

/*!
 * @brief Add a sound menu item to a menu
 */
- (void)addSound:(NSString *)soundPath toMenu:(NSMenu *)soundMenu
{
	NSString	*soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
	NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
																				  target:self
																				  action:@selector(selectSound:)
																		   keyEquivalent:@""] autorelease];
	
	[menuItem setRepresentedObject:[soundPath stringByCollapsingBundlePath]];
	[menuItem setImage:soundFileIcon];
	[soundMenu addItem:menuItem];
}

/*!
 * @brief Add a soundPath to the menu root if it is not yet present, then select it
 *
 * @param The soundPath, which should have a collapsed bundle path (to match menuItem represented objects)
 */
- (void)addAndSelectSoundPath:(NSString *)soundPath
{
	NSMenu	*rootMenu = [popUp_actionDetails menu];
	NSInteger		menuIndex;
	
	//Check for it currently being present in the root menu
	menuIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:soundPath];
	if (menuIndex == -1) {
		//Add it if it wasn't found
		[self addSound:soundPath toMenu:rootMenu];
		menuIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:soundPath];			
	}
	
	if (menuIndex != -1) {
		[popUp_actionDetails selectItemAtIndex:menuIndex];
	}
}

/*!
 * @brief A sound was selected from a sound popUp menu
 *
 * Update our header and play the sound.  If "Other..." is selected, allow selection of a file.
 */
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];
    
    if (soundPath != nil && [soundPath length] != 0) {
        [adium.soundController playSoundAtPath:[soundPath stringByExpandingBundlePath]]; //Play the sound

		//Update the menu and and the selection
		[self addAndSelectSoundPath:soundPath];

		[self detailsForHeaderChanged];
    } else { //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.allowedFileTypes = [NSSound soundUnfilteredTypes]; //allow all the sounds NSSound understands
		[openPanel beginSheetModalForWindow:[view window] completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				NSString *path = openPanel.URL.path;
				
				[adium.soundController playSoundAtPath:path]; //Play the sound
				
				//Update the menu and and the selection
				[self addAndSelectSoundPath:[path stringByCollapsingBundlePath]];
				
				[self detailsForHeaderChanged];
			}
		}];
    }
}

@end
