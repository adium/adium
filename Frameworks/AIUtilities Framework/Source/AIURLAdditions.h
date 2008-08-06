//
//  AIURLAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <AIUtilities/AITigerCompatibility.h>

/*!
 * Provides some additional functionality when working with \c NSURL objects.
 */
@interface NSURL (AIURLAdditions)

/**
 * @brief Gets the length of the URL.
 *
 * @return The length (number of characters) of the URL.
 */
- (NSUInteger)length;

/*!
 * @brief Returns the argument for the specified key in the query string component of
 * the URL.
 *
 * The search is case-sensitive, and the caller is responsible for removing any
 * percent escapes, as well as "+" escapes, too.
 *
 * @param key The key whose value should be located and returned.
 * @return The argument for the specified key, or \c nil if the key could not
 *   be found in the query string.
 */
- (NSString *)queryArgumentForKey:(NSString *)key;

@end
