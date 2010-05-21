//
//  ESStatusPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESStatusPreferencesPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "ESStatusPreferences.h"
#import <Adium/AIMenuControllerProtocol.h>
#import "AIStatusController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define	STATUS_DEFAULT_PREFS @"StatusDefaults"

@interface ESStatusPreferencesPlugin ()
- (void)showStatusPreferences:(id)sender;
@end

/*!
 * @class ESStatusPreferencesPlugin
 * @brief Component to install our status preferences pane
 */
@implementation ESStatusPreferencesPlugin

/*!
 * @brief Install
 *
 * Install our preference pane, and add a menu item to the Status menu which opens it.
 */
- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	//Install our preference view
    preferences = [[ESStatusPreferences preferencePaneForPlugin:self] retain];
	advancedPreferences = [[ESStatusAdvancedPreferences preferencePaneForPlugin:self] retain];

	//Add our menu item
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Edit Status Menu",nil) stringByAppendingEllipsis]
																	target:self
																	action:@selector(showStatusPreferences:)
															 keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Status_Additions];
	
	//Register defaults
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:STATUS_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_STATUS_PREFERENCES];	
	
}

/*!
 * Open the preferences to the status pane
 */
- (void)showStatusPreferences:(id)sender
{
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Status"];
}

@end
