//
//  NSStringAdditions.h
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (DPExtensions)

/*!
 * @abstract A convenient methods for creating an autoreleased string
 * from an NSData instance.
 *
 * @discussion This is the equivalent to <code>[[[NSString alloc] initWithData:data encoding:enc] autorelease]</code>.
 */
+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)enc;

/*!
 * @abstract Returns an absolute path from the receiver.
 * @discussion The path is made by standardizing the receiver and appending it to the current directory if needed.
 */
- (NSString *)absolutePath;

@end
