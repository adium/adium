//
//  Presentity.h
//  Logtastic
//
//  Created by Ladd Van Tol on Fri Mar 28 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Presentity : NSObject <NSCoding>
{
	NSString *service;
	NSString *senderID;
	
	id myPerson;
}

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

- (NSString *) senderID;

@end
