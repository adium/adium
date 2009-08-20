//
//  ESPersonalPreferencesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 12/18/05.
//

#import "ESPersonalPreferencesPlugin.h"
#import "ESPersonalPreferences.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIDictionaryAdditions.h>

@implementation ESPersonalPreferencesPlugin

/*!
 * @brief Install the plugin
 */
- (void)installPlugin
{
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"PersonalPreferencesDefaults" 
																		forClass:[self class]]  
										  forGroup:GROUP_ACCOUNT_STATUS];

    [[ESPersonalPreferences preferencePaneForPlugin:self] retain];	
}

@end
