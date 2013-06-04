//
//  InstantMessage.m
//  Logtastic
//
//  Created by Ladd Van Tol on Fri Mar 28 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import "InstantMessage.h"


@implementation InstantMessage

- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSLog(@"encodeWithCoder called on %@", [self class]);
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ([decoder allowsKeyedCoding])
	{
		sender = [[decoder decodeObjectForKey:@"Sender"] retain];
		text = [[decoder decodeObjectForKey:@"MessageText"] retain];
		date = [[decoder decodeObjectForKey:@"Time"] retain];
		flags = [decoder decodeInt32ForKey:@"Flags"];
	}
	else
	{
		sender = [[decoder decodeObject] retain];
		date = [[decoder decodeObject] retain];
		text = [[decoder decodeObject] retain];
		[decoder decodeValueOfObjCType:@encode(unsigned) at:&flags];
	}
	
	return self;
}

- (Presentity *)sender
{
	return sender;
}

- (NSDate *)date
{
	return date;
}

- (NSAttributedString *)text
{
	return text;
}

@end
