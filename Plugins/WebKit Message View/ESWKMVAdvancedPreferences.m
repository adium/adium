//
//  ESWKMVAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESWKMVAdvancedPreferences.h"
#import "AIWebKitMessageViewPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@implementation ESWKMVAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced_Messages;
}
- (NSString *)label{
    return AILocalizedString(@"Messages","Message Display Options advanced preferences label");
}
- (NSString *)nibName{
    return @"WebKitAdvancedPreferencesView";
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	return defaultsDict;
}

//Configure the preference view
- (void)viewDidLoad
{

	[self configureControlDimming];
}

- (IBAction)changePreference:(id)sender
{

}



@end
