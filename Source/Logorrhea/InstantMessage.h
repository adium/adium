//
//  InstantMessage.h
//  Logtastic
//
//  Created by Ladd Van Tol on Fri Mar 28 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Presentity.h"

@interface InstantMessage : NSObject <NSCoding>
{
	Presentity *sender;
	NSDate *date;
	NSAttributedString *text;
	NSUInteger flags; 
}

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

- (Presentity *)sender;
- (NSDate *)date;
- (NSAttributedString *)text;


@end
