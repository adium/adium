/*
 *	LMXMutableDataAdditions.h
 *	LMX
 *
 *	Created by Peter Hosey on 2005-10-23.
 *	Copyright 2005 Peter Hosey. All rights reserved.
 */

@interface NSMutableData (LMXMutableDataAdditions)

//insert the given data before all the bytes in the receiver.
- (void)prependData:(NSData *)data;

@end
