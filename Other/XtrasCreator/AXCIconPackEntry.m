//
//  AXCIconPackEntry.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCIconPackEntry.h"

@implementation AXCIconPackEntry

+ (id) entryWithKey:(NSString *)newKey path:(NSString *)newPath
{
	return [[[self alloc] initWithKey:newKey path:newPath] autorelease];
}

- (id) initWithKey:(NSString *)newKey path:(NSString *)newPath
{
	if((self = [super init])) {
		key = [newKey copy];
		path = [newPath copy];
	}
	return self;
}

#pragma mark -

- (NSString *) key
{
	return key;
}

- (NSString *) path
{
	return path;
}
- (void) setPath:(NSString *)newPath
{
	[path release];
	path = [newPath copy];
}

#pragma mark -

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@ %p key:%@ path:%@>", [self class], self, key, path];
}

@end
