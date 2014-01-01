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


#ifndef AICompatibility
#define AICompatibility

#import <AvailabilityMacros.h>

#ifndef MAC_OS_X_VERSION_10_9
#define MAC_OS_X_VERSION_10_9 1090
#endif //ndef MAC_OS_X_VERSION_10_9

#ifndef MAC_OS_X_VERSION_10_7
#define MAC_OS_X_VERSION_10_7 1070
#endif //ndef MAC_OS_X_VERSION_10_7

#if MAC_OS_X_VERSION_10_9 > MAC_OS_X_VERSION_MAX_ALLOWED

#ifdef __OBJC__

@interface NSScreen (NewMavericksMethods)
+ (BOOL)screensHaveSeparateSpaces;
@end

#endif
#endif //MAC_OS_X_VERSION_10_9

#if MAC_OS_X_VERSION_10_7 > MAC_OS_X_VERSION_MAX_ALLOWED

#ifdef __OBJC__

@interface NSScrollView (NewLionMethods)
- (void)setVerticalScrollElasticity:(NSInteger)elasticity;
@end

@interface NSWindow (NewLionMethods)
- (void)setRestorable:(BOOL)flag;
@end

@protocol NSDraggingDestination <NSObject>
@end
@protocol NSURLDownloadDelegate <NSObject>
@end

#endif
#endif //MAC_OS_X_VERSION_10_7

#endif
