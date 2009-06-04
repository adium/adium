//
//  ESStatusPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//


@class ESStatusPreferences, ESStatusAdvancedPreferences;

@interface ESStatusPreferencesPlugin : AIPlugin {
	ESStatusPreferences			*preferences;
	ESStatusAdvancedPreferences *advancedPreferences;
}

@end
