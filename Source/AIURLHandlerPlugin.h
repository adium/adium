//
//  AIURLHandlerPlugin.h
//  Adium
//
//  Created by Zachary West on 2009-04-03.
//


#define AIURLHandleNotification			@"AIURLHandleNotification"

#define PREF_KEY_ENFORCE_DEFAULT		@"Enforce Adium as Default"
#define PREF_KEY_SET_DEFAULT_FIRST_TIME @"AdiumURLHandling:CompletedFirstLaunch" // The old variable value, so we don't do this again.
#define ADIUM_BUNDLE_ID					@"com.adiumx.adiumx"
#define GROUP_URL_HANDLING				@"URL Handling Group"

@class AIURLHandlerAdvancedPreferences;
@interface AIURLHandlerPlugin : AIPlugin {
	AIURLHandlerAdvancedPreferences		*preferences;
}

// Enforcement
- (void)setAdiumAsDefault;

// Schemes
- (NSString *)serviceIDForScheme:(NSString *)scheme;
- (NSArray *)allSchemesLikeScheme:(NSString *)scheme;
- (NSArray *)uniqueSchemes;
- (NSArray *)helperSchemes;

// Applications
- (void)setDefaultForScheme:(NSString *)inScheme toBundleID:(NSString *)bundleID;
- (NSString *)defaultApplicationBundleIDForScheme:(NSString *)scheme;

@end
