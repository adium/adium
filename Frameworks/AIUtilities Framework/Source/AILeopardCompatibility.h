/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
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

@interface NSMenu (NewSnowLeopardMethods)
- (BOOL)popUpMenuPositioningItem:(NSMenuItem *)item atLocation:(NSPoint)location inView:(NSView *)view;
@end

@protocol NSToolbarDelegate
@end
@protocol NSSplitViewDelegate
@end
@protocol NSTextViewDelegate
@end
@protocol NSMenuDelegate
@end
@protocol NSOutlineViewDelegate
@optional
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object;
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item;
@end
@protocol NSOutlineViewDataSource
@end
@protocol NSWindowDelegate
@end
@protocol NSXMLParserDelegate
@end
@protocol NSTableViewDelegate
@end
@protocol NSTableViewDataSource
@end
@protocol NSTextFieldDelegate
@end
@protocol NSAnimationDelegate
@end
@protocol NSSpeechSynthesizerDelegate
@end

#endif

enum { NSWindowCollectionBehaviorStationary = 1 << 4 };

#else //Not compiling for 10.6

#endif //MAC_OS_X_VERSION_10_6

#endif //AILeopardCompatibility
