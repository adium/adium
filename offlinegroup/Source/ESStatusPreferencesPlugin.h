//
//  ESStatusPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIPlugin.h>

@class ESStatusPreferences, ESStatusAdvancedPreferences;

@interface ESStatusPreferencesPlugin : AIPlugin {
	ESStatusPreferences			*preferences;
	ESStatusAdvancedPreferences *advancedPreferences;
}

@end
