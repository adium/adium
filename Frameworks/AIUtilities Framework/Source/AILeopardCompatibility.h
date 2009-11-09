/*
 *  AILeopardCompatibility.h
 *  Adium
 *
 *  Created by Zachary West on 2009-08-29.
 *  Copyright 2009  . All rights reserved.
 *
 */

#ifndef AILeopardCompatibility
#define AILeopardCompatibility

#import <AvailabilityMacros.h>

#ifndef MAC_OS_X_VERSION_10_6
#define MAC_OS_X_VERSION_10_6 1060
#endif //ndef MAC_OS_X_VERSION_10_6

#if MAC_OS_X_VERSION_10_6 > MAC_OS_X_VERSION_MAX_ALLOWED

#ifdef __OBJC__
@interface NSTextView(NSTextViewLeopardMethods)
- (void)setAutomaticDataDetectionEnabled:(BOOL)flag;
- (BOOL)isAutomaticDataDetectionEnabled;
- (void)toggleAutomaticDataDetection:(id)sender;

- (void)setAutomaticDashSubstitutionEnabled:(BOOL)flag;
- (BOOL)isAutomaticDashSubstitutionEnabled;
- (void)toggleAutomaticDashSubstitution:(id)sender;

- (void)setAutomaticTextReplacementEnabled:(BOOL)flag;
- (BOOL)isAutomaticTextReplacementEnabled;
- (void)toggleAutomaticTextReplacement:(id)sender;

- (void)setAutomaticSpellingCorrectionEnabled:(BOOL)flag;
- (BOOL)isAutomaticSpellingCorrectionEnabled;
- (void)toggleAutomaticSpellingCorrection:(id)sender;
@end

@interface NSSpellChecker(NSSpellCheckerLeopardMethods)
- (NSArray *)userPreferredLanguages;
@end

@interface NSOperationQueue(NSOperationQueueLeopardMethods)
- (void)setName:(NSString *)newName;
@end

@interface NSWindow(NSWindowLeopardMethods)
- (BOOL)isOnActiveSpace;
@end

#endif

enum { NSWindowCollectionBehaviorStationary = 1 << 4 };

#else //Not compiling for 10.6

#endif //MAC_OS_X_VERSION_10_6

#endif //AILeopardCompatibility
