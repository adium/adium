//
//  NSString-FBAdditions.h
//  FriBidi
//
//  Created by Ofri Wolfus on 22/08/06.
//  Copyright 2006 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (FBAdditions)

/*!
 * @abstract Retusn the base writing direction of the receiver.
 * @discussion Returns <code>NSWritingDirectionNatural</code> if the writing direction is not fixed.
 */
- (NSWritingDirection)baseWritingDirection;

@end
