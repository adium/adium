//
//  AIAdvancedPreferencesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

@class AIMessageAlertsAdvancedPreferences, AIConfirmationsAdvancedPreferences;

@interface AIAdvancedPreferencesPlugin : AIPlugin {
	AIMessageAlertsAdvancedPreferences *messageAlertsPreferences;
	AIConfirmationsAdvancedPreferences *confirmationsPreferences;
}

@end
