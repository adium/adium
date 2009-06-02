//
//  AIAdvancedPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

#import "AIAdvancedPreferencesPlugin.h"
#import "AIAdvancedPreferences.h"
#import "AIMessageAlertsAdvancedPreferences.h"
#import "AIConfirmationsAdvancedPreferences.h"

@implementation AIAdvancedPreferencesPlugin

- (void)installPlugin
{
	[AIAdvancedPreferences preferencePane];
	
	// Generic advanced panes with no specific plugins.
	messageAlertsPreferences = [[AIMessageAlertsAdvancedPreferences preferencePane] retain];
	confirmationsPreferences = [[AIConfirmationsAdvancedPreferences preferencePane] retain];
}

@end
