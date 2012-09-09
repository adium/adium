//
//  Presentity.m
//  Logtastic
//
//  Created by Ladd Van Tol on Fri Mar 28 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import "Presentity.h"


@implementation Presentity

- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSLog(@"encodeWithCoder called on %@", [self class]);
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ([decoder allowsKeyedCoding])
	{
		service = [decoder decodeObjectForKey:@"ServiceName"];
		senderID = [decoder decodeObjectForKey:@"ID"];
	}
	else
	{
		service = [decoder decodeObject];
		senderID = [decoder decodeObject];
	}
	
	return self;
}

- (NSString *) senderID
{
	return senderID;
}

@end
