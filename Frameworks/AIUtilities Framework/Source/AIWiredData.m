/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */
//
//  AIWiredData.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-15.
//

#import "AIWiredData.h"
#import "AIFunctions.h"
#import "AITigerCompatibility.h"
#include <stdlib.h>
#include <string.h>
#include <sys/errno.h>
#include <sys/types.h>
#include <sys/mman.h>

@implementation AIWiredData

#pragma mark Class factories

+ (id)data
{
	return [[[self alloc] init] autorelease];
}

+ (id)dataWithBytes:(const void *)inBytes length:(NSUInteger)inLength
{
	return [[[self alloc] initWithBytes:inBytes length:inLength] autorelease];
}

#pragma mark Inits; dealloc

//we can't do [super init] because NSData stops it (class cluster).
//this is the Next Best Thing.
- (id)superInit
{
	SEL initSelector = @selector(init);
	IMP superInit = [[NSData superclass] instanceMethodForSelector:initSelector];
	return superInit(self, initSelector);
}

- (id)init
{
	if ((self = [self superInit])) {
		backing = valloc(0);
		if (!backing) {
			[self release];
			self = nil;
		} else {
			int mlock_retval = mlock(backing, length);
			if (mlock_retval < 0) {
				NSLog(@"in AIWiredData: mlock returned %i: %s", mlock_retval, strerror(errno));
				[self release];
				self = nil;
			}
		}
	}
	return self;
}

- (id)initWithBytes:(const void *)inBytes length:(NSUInteger)inLength
{
	NSParameterAssert(inBytes != NULL);
	if ((self = [self superInit])) {
		length = inLength;
		backing = valloc(length);
		if (!backing) {
			NSLog(@"in AIWiredData: could not valloc %llu bytes", (unsigned long long)length);
			[self release];
			self = nil;
		} else {
			int mlock_retval = mlock(backing, length);
			if (mlock < 0) {
				NSLog(@"in AIWiredData: mlock returned %i: %s", mlock_retval, strerror(errno));
				[self release];
				self = nil;
			} else {
				memcpy(backing, inBytes, length);
			}
		}
	}
	return self;
}

- (void)dealloc {
	AIWipeMemory(backing, length);
	munlock(backing, length);
	free(backing);
	[super dealloc];
}

#pragma mark Range-checking (private)

- (void) assertValidRange:(NSRange)range
{
	NSParameterAssert(range.location < length);
	if (range.length > 0)
		NSParameterAssert(((range.location + range.length) - 1) < length);
}

#pragma mark Working with other datas

- (id)initWithData:(NSData *)data
{
	return [self initWithBytes:[data bytes] length:[data length]];
}

- (id)subdataWithRange:(NSRange)range {
	[self assertValidRange:range];
	return [[[[self class] alloc] initWithBytes:([self bytes] + range.location) length:range.length] autorelease];
}

#pragma mark Copying backing

- (void)getBytes:(void *)output
{
	[self getBytes:output length:length];
}
- (void)getBytes:(void *)output length:(NSUInteger)copyLength
{
	NSRange range = {
		.location = 0,
		.length = copyLength,
	};
	[self getBytes:output range:range];
}
- (void)getBytes:(void *)output range:(NSRange)range
{
	NSParameterAssert(output != NULL);
	[self assertValidRange:range];

	const char *from = backing;
	char       *to   = output;

	unsigned long i = range.location;
	unsigned long j = 0, j_max =     range.length;
	while (j < j_max) {
		to[j] = from[i];
		++i; ++j;
	}
}

#pragma mark Working with files

//XXX - needed: everything.
//+ (id)dataWithContentsOfFile:(NSString *)path
//+ (id)dataWithContentsOfMappedFile:(NSString *)path
//+ (id)dataWithContentsOfURL:(NSURL *)url
//- (id)initWithContentsOfFile:(NSString *)path
//- (id)initWithContentsOfMappedFile:(NSString *)path
//- (id)initWithContentsOfURL:(NSURL *)url
//- (id)writeToFile:(NSString *)path atomically:(BOOL)flag
//- (id)writeToURL:(NSURL *)url atomically:(BOOL)flag

#pragma mark Accessors

- (const void *)bytes
{
	return backing;
}
- (NSUInteger)length
{
	return length;
}

#pragma mark Container methods

- (BOOL)isEqualToData:(NSData *)other {
	if (!other)
		return NO;

	if (length != [other length])
		return NO;

	return (memcmp([self bytes], [other bytes], length) == 0);
}
- (BOOL)isEqual:(id)other {
	return other && [other isKindOfClass:[NSData class]] && [self isEqualToData:other];
}

#pragma mark Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"<AIWiredData %p whose backing is %p and contains %llu bytes>", self, backing, (unsigned long long)length];
}

@end
