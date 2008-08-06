/*
 *  AITigerCompatibility.h
 *  AIUtilities.framework
 *
 *  Created by David Smith on 10/28/07.
 *  Copyright 2007 The Adium Team. All rights reserved.
 *
 */
#ifndef AITigerCompatibility

#define AITigerCompatibility

#import <AvailabilityMacros.h>

#ifndef MAC_OS_X_VERSION_10_5
#define MAC_OS_X_VERSION_10_5 1050
#endif //ndef MAC_OS_X_VERSION_10_5

#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
#define NS_REQUIRES_NIL_TERMINATION

#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef double CGFloat;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;
#endif

#define NSIntegerMax    LONG_MAX
#define NSIntegerMin    LONG_MIN
#define NSUIntegerMax   ULONG_MAX

#define NSINTEGER_DEFINED 1

#define NSDownloadsDirectory 15

typedef NSUInteger NSWindowCollectionBehavior;
#define NSWindowCollectionBehaviorDefault 0
#define NSWindowCollectionBehaviorCanJoinAllSpaces 1 << 0

#define NSCellHitContentArea 1 << 0

#ifdef __OBJC__
@interface NSWindow (NSWindowTigerMethods)
- (void)setCollectionBehavior:(NSWindowCollectionBehavior)behavior;
@end

@interface NSTextView (NSTextViewTigerMethods)
- (void)setGrammarCheckingEnabled:(BOOL)flag;
- (BOOL)isGrammarCheckingEnabled;
- (void)toggleGrammarChecking:(id)sender;
@end

@interface NSSplitView (NSScrollViewTigerMethods)
- (void)setPosition:(float)position ofDividerAtIndex:(NSInteger)dividerIndex;
@end

@interface NSNumber (NSNumber64BitCompat)
- (NSInteger)integerValue;
- (NSUInteger)unsignedIntegerValue;
+ (NSNumber *)numberWithInteger:(NSInteger)value;
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value;
@end

@interface NSControl (NSControl64BitCompat)
- (NSInteger)integerValue;
- (void)setIntegerValue:(NSInteger)anInteger;
- (void)takeIntegerValueFrom:(id)sender;
@end

@interface NSString (NSString64BitCompat)
- (NSInteger)integerValue;
@end;

#endif

#else //Not compiling for 10.5

#if !defined(NS_REQUIRES_NIL_TERMINATION)
    #define NS_REQUIRES_NIL_TERMINATION __attribute__((sentinel))
#endif

#endif //MAC_OS_X_VERSION_10_5

#endif //AITigerCompatibility
