//
//  AIAdvancedPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

#import "AIAdvancedPreferencesPlugin.h"
#import "AIAdvancedPreferences.h"

@implementation AIAdvancedPreferencesPlugin

- (void)installPlugin
{
	[AIAdvancedPreferences preferencePane];
}

@end
