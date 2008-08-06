//
//  AIApplicationAdditions.h
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface NSApplication (AIApplicationAdditions)

- (BOOL)isOnTigerOrBetter;
- (BOOL)isOnLeopardOrBetter;
- (BOOL)isTiger;

- (BOOL)isWebKitAvailable;

- (NSString *)applicationVersion;

@end
