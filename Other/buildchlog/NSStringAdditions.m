//
//  NSStringAdditions.m
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import "NSStringAdditions.h"


@implementation NSString (DPExtensions)

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)enc {
	return [[[NSString alloc] initWithData:data
								  encoding:enc] autorelease];
}

- (NSString *)absolutePath {
	self = [self stringByStandardizingPath];
	if (![self hasPrefix:@"/"])
		self = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:self];
	
	return self;
}

@end
