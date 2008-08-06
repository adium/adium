/*
 *  AIDockControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

#define PREF_GROUP_APPEARANCE		@"Appearance"

#define KEY_ACTIVE_DOCK_ICON		@"Dock Icon"
#define FOLDER_DOCK_ICONS			@"Dock Icons"

#define KEY_ANIMATE_DOCK_ICON		@"Animate Dock Icon on Unread Messages"
#define KEY_BADGE_DOCK_ICON			@"Badge Dock Icon on Unread Messages"

@class AIIconState;

typedef enum {
    AIDockBehaviorStopBouncing = 0,
    AIDockBehaviorBounceOnce,
    AIDockBehaviorBounceRepeatedly,
    AIDockBehaviorBounceDelay_FiveSeconds,
    AIDockBehaviorBounceDelay_TenSeconds,
    AIDockBehaviorBounceDelay_FifteenSeconds,
    AIDockBehaviorBounceDelay_ThirtySeconds,
    AIDockBehaviorBounceDelay_OneMinute
} AIDockBehavior;

@protocol AIDockController <AIController>
//Icon animation & states
- (void)setIconStateNamed:(NSString *)inName;
- (void)removeIconStateNamed:(NSString *)inName;
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName;
- (CGFloat)dockIconScale;
- (NSImage *)baseApplicationIconImage;

//Special access to icon pack loading
- (NSArray *)availableDockIconPacks;
- (BOOL)currentIconSupportsIconStateNamed:(NSString *)inName;;
- (NSMutableDictionary *)iconPackAtPath:(NSString *)folderPath;
- (void)getName:(NSString **)outName previewState:(AIIconState **)outIconState forIconPackAtPath:(NSString *)folderPath;
- (AIIconState *)previewStateForIconPackAtPath:(NSString *)folderPath;

//Bouncing & behavior
- (BOOL)performBehavior:(AIDockBehavior)behavior;
- (NSString *)descriptionForBehavior:(AIDockBehavior)behavior;
@end
