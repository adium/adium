/*
 *  AIPreferenceControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

//Preference groups
#define PREF_GROUP_GENERAL              @"General"
#define PREF_GROUP_ACCOUNTS             @"Accounts"
#define PREF_GROUP_TOOLBARS 			@"Toolbars"
#define PREF_GROUP_WINDOW_POSITIONS     @"Window Positions"
#define PREF_GROUP_SPELLING 			@"Spelling"
#define OBJECT_PREFS_PATH               @"ByObject"			//Path to object specific preference folder
#define ACCOUNT_PREFS_PATH              @"Accounts"			//Path to account specific preference folder

//Preference Categories
typedef enum {
	AIPref_General= 0,
	AIPref_Accounts,
	AIPref_Personal,
	AIPref_Appearance,
	AIPref_Messages,
	AIPref_Status,
	AIPref_Events,
	AIPref_FileTransfer,
	AIPref_Advanced
} AIPreferenceCategory;

@class AIAdium, AIListObject;
@class AIPreferencePane, AIAdvancedPreferencePane;

@protocol AIPreferenceController <AIController>
//Preference Window
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)closePreferenceWindow:(id)sender;
- (void)openPreferencesToCategoryWithIdentifier:(NSString *)identifier;
- (void)addPreferencePane:(AIPreferencePane *)inPane;
- (void)removePreferencePane:(AIPreferencePane *)inPane;
- (NSArray *)paneArray;
- (void)addAdvancedPreferencePane:(AIAdvancedPreferencePane *)inPane;
- (NSArray *)advancedPaneArray;

//Observing
- (void)registerPreferenceObserver:(id)observer forGroup:(NSString *)group;
- (void)unregisterPreferenceObserver:(id)observer;

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath ofObject:(AIListObject *)listObject options:(NSKeyValueObservingOptions)options context:(void *)context;

- (void)informObserversOfChangedKey:(NSString *)key inGroup:(NSString *)group object:(AIListObject *)object;
- (void)delayPreferenceChangedNotifications:(BOOL)inDelay;

//Setting Preferences
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group;
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)group object:(AIListObject *)object;
- (void)setPreferences:(NSDictionary *)inPrefDict inGroup:(NSString *)group;
- (void)setPreferences:(NSDictionary *)inPrefDict inGroup:(NSString *)group object:(AIListObject *)object;

//Retrieving Preferences
- (id)preferenceForKey:(NSString *)key group:(NSString *)group;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object;
- (id)preferenceForKey:(NSString *)key group:(NSString *)group objectIgnoringInheritance:(AIListObject *)object;
- (NSDictionary *)preferencesForGroup:(NSString *)group;
- (id)defaultPreferenceForKey:(NSString *)key group:(NSString *)group object:(AIListObject *)object;

//Defaults
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group;
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)group object:(AIListObject *)object;

//Default download location
- (NSString *)userPreferredDownloadFolder;
- (void)setUserPreferredDownloadFolder:(NSString *)path;
@end

@interface NSObject (AIPreferenceObserver)
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
@end
