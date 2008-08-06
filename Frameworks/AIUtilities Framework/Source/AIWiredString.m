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
//  AIWiredString.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-16.
//

#import "AIWiredString.h"
#import "AIWiredData.h"
#import "AIFunctions.h"
#import "AITigerCompatibility.h"
#include <sys/types.h>
#include <sys/mman.h>
#include <unistd.h>

@interface AIWiredString (PRIVATE)

//creates a UTF-8 representation of the input.
//XXX - currently does not know about BOMs.
//you must free the output buffer with free(3).
//returns the total size of the buffer (which may be longer than the length of the UTF-8 data).
//the extraBytes are not counted in the outputLength, but they are counted in the return value.
- (size_t)makeUTF8:(out UTF8Char **)output length:(out size_t *)outputLength extraBytes:(const size_t)numExtraBytes forUTF16:(const UTF16Char *)input length:(size_t)inputLength;

@end

@implementation AIWiredString

#pragma mark Class factories

+ (id)string
{
	return [[[self alloc] init] autorelease];
}

+ (id)stringWithCharacters:(const unichar *)inChars length:(NSUInteger)inLength
{
	return [[[self alloc] initWithCharacters:inChars length:inLength] autorelease];
}

+ (id)stringWithUTF8String:(const char *)utf8
{
	return [[[self alloc] initWithUTF8String:utf8] autorelease];
}

+ (id)stringWithString:(NSString *)other
{
	return [[[self alloc] initWithString:other] autorelease];
}

#pragma mark Inits and dealloc

//we can't do [super init] because NSString stops it (class cluster).
//this is the Next Best Thing.
- (id)superInit
{
	SEL initSelector = @selector(init);
	IMP superInit = [[NSString superclass] instanceMethodForSelector:initSelector];
	return superInit(self, initSelector);
}

- (id)init
{
	if ((self = [self superInit])) {
		backing = malloc(0);
		if (!backing) {
			NSLog(@"in -[AIWiredString init]: could not malloc %llu bytes", (unsigned long long)length);
			[self release];
			self = nil;
		} else {
			int retval = mlock(backing, length);
			if (retval < 0) {
				NSLog(@"in -[AIWiredString init]: mlock returned %i: %s", retval, strerror(errno));
				[self release];
				self = nil;
			}
		}
	}
	return self;
}

- (id)initWithCharacters:(const unichar *)inChars length:(NSUInteger)inLength
{
	if (inLength) NSParameterAssert(inChars != NULL);
	if ((self = [self superInit])) {
		length = inLength;
		backing = malloc(sizeof(unichar) * length);
		if (!backing) {
			NSLog(@"in -[AIWiredString initWithCharacters:length:]: could not malloc %llu bytes", (unsigned long long)length);
			[self release];
			self = nil;
		} else {
			int retval = mlock(backing, length);
			if (retval < 0) {
				NSLog(@"in -[AIWiredString initWithCharacters:length:]: mlock returned %i: %s", retval, strerror(errno));
				[self release];
				self = nil;
			} else {
				memcpy(backing, inChars, length * sizeof(unichar));
			}
		}
	}
	return self;
}

- (id)initWithBytes:(const void *)inBytes length:(NSUInteger)inLength encoding:(NSStringEncoding)inEncoding
{
	if (inLength) NSParameterAssert(inBytes != NULL);
	if (inEncoding == NSUnicodeStringEncoding) {
		return [self initWithCharacters:inBytes length:(inLength / sizeof(unichar))];
	}

	OSStatus err;
	CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(inEncoding);
	//TEC encodings approx. == CFString encodings.
	TECObjectRef converter = NULL;
	err = TECCreateConverter(&converter, encoding, kCFStringEncodingUnicode);
	if (err != noErr) {
		[self release];
		self = nil;
	} else {
		ByteCount outputLength = 0;
		ByteCount bufferSize = 0;
		ByteCount bufferSizeIncrement = getpagesize();

		do {
			backing = AIReallocWired(backing, bufferSize += bufferSizeIncrement);
			if (!backing) {
				[self release];
				self = nil;
				break;
			}
			ByteCount nobodyCares;
			err = TECConvertText(converter,
								 //input
								 inBytes, inLength, /*actualInputLength*/ &nobodyCares,
								 //output
								 (TextPtr)backing, bufferSize, &outputLength);
			TECClearConverterContextInfo(converter);
		} while (err == kTECOutputBufferFullStatus);

		TECDisposeConverter(converter);

		length = outputLength / sizeof(unichar);
	}
	return self;
}

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)inEncoding
{
	NSParameterAssert(data != nil);
	return [self initWithBytes:[data bytes] length:[data length] encoding:inEncoding];
}

- (id)initWithUTF8String:(const char *)utf8
{
	NSParameterAssert(utf8 != NULL);
	unsigned utf8Length = strlen(utf8);
	return [self initWithBytes:utf8 length:utf8Length encoding:NSUTF8StringEncoding];
}

- (id)initWithString:(NSString *)other
{
	NSParameterAssert(other != nil);
	unsigned otherLength = [other length];
	if (!otherLength) {
		self = [self init];
	} else if ((self = [self superInit])) {
		length = otherLength;
		backing = malloc(length * sizeof(unichar));
		if (!backing) {
			NSLog(@"in -[AIWiredString initWithString:]: could not malloc %llu bytes", (unsigned long long)length);
			[self release];
			self = nil;
		} else {
			int retval = mlock(backing, length);
			if (retval < 0) {
				NSLog(@"in -[AIWiredString initWithString:]: mlock returned %i: %s", retval, strerror(errno));
				[self release];
				self = nil;
			}
			[other getCharacters:backing];
		}
	}
	return self;
}

- (void)dealloc
{
	AIWipeMemory(backing, length);
	munlock(backing, length);
	free(backing);
	[super dealloc];
}

#pragma mark Accessing characters

- (NSUInteger)length
{
	return length;
}

- (void)getCharacters:(out unichar *)outBuf
{
	NSRange extent = {
		.location = 0,
		.length = length,
	};
	[self getCharacters:outBuf range:extent];
}
- (void)getCharacters:(out unichar *)outBuf range:(NSRange)range
{
	NSParameterAssert(outBuf != NULL);
	if (length) {
		//neither of these assertions is valid for empty strings.
		NSParameterAssert(range.location < length);
		NSParameterAssert(((range.location + range.length) - 1) <= length);
	
		unsigned i = range.location;
		unsigned j = 0, j_max = range.length;
		while (j < j_max) {
			outBuf[j] = backing[i];
			++i; ++j;
		}
	}
}

#pragma mark Getting other representations

- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding allowLossyConversion:(BOOL)allowLossyConversion nulTerminate:(BOOL)nulTerminate
{
	if (inEncoding == NSUnicodeStringEncoding) {
		//We don't need to convert, so just make a copy of our backing store.
		size_t numBytes = length * sizeof(unichar);
		if (!nulTerminate) {
			return [AIWiredData dataWithBytes:backing length:numBytes];
		} else {
			AIWiredData *result = nil;

			//Add the NUL terminator in our byte-count.
			size_t numBytesWithNUL = numBytes + sizeof(unichar);
			unichar *buffer = AIReallocWired(NULL, numBytesWithNUL);
			if (buffer) {
				//Copy the string.
				memcpy(buffer, backing, numBytes);
				//NUL-terminate.
				buffer[length] = '\0';

				result = [AIWiredData dataWithBytes:buffer length:numBytesWithNUL];

				//Clean up after ourselves.
				AIWipeMemory(buffer, numBytesWithNUL);
				munlock(buffer, numBytesWithNUL);
				free(buffer);
			}

			return result;
		}
	}

	if (inEncoding == NSUTF8StringEncoding) {
		//Unicode Converter can't convert to UTF-8, so we have to do that ourselves.
		nulTerminate = nulTerminate != NO; //this makes it either 1 or 0
		UTF8Char *UTF8 = NULL;
		size_t UTF8Length = 0;
		size_t UTF8Size = [self makeUTF8:&UTF8 length:&UTF8Length extraBytes:nulTerminate forUTF16:backing length:length];
		if (nulTerminate) UTF8[UTF8Length] = '\0';
		AIWiredData *data = [AIWiredData dataWithBytes:UTF8 length:(UTF8Length + nulTerminate)];
		AIWipeMemory(UTF8, UTF8Size);
		munlock(UTF8, UTF8Size);
		free(UTF8);
		return data;
	}

	struct UnicodeMapping mapping = {
		.unicodeEncoding = kTextEncodingUnicodeDefault,
		.otherEncoding = CFStringConvertNSStringEncodingToEncoding(inEncoding),
		.mappingVersion = kUnicodeUseLatestMapping,
	};
	OptionBits controlFlags = 0;
	if (allowLossyConversion)
		controlFlags |= (kUnicodeUseFallbacksMask | kUnicodeLooseMappingsMask);
	OSStatus err;
	UnicodeToTextInfo converter = NULL; 

	AIWiredData *result = nil;

	err = CreateUnicodeToTextInfo(&mapping, &converter);
	if (err != noErr) {
		NSLog(@"[AIWiredString dataUsingEncoding:\"%@\" allowLossyConversion:%u nulTerminate:%u] got error %li creating Unicode converter object to convert from encoding 0x%08x to encoding 0x%08x", [NSString localizedNameOfStringEncoding:inEncoding], allowLossyConversion, nulTerminate, (long)err, mapping.unicodeEncoding, mapping.otherEncoding);
		return result;
	}

	char *outputBuffer = NULL;
	ByteCount outputLength = 0;
	ByteCount bufferSize = 0;
	ByteCount bufferSizeIncrement = getpagesize();

	do {
		outputBuffer = AIReallocWired(outputBuffer, bufferSize += bufferSizeIncrement);
		if (!outputBuffer) {
			[self release];
			self = nil;
			break;
		}

		ByteCount numBytesRead_nobodyCares;
		err = ConvertFromUnicodeToText(converter,
								 //input
								 length * sizeof(unichar), backing,
								 controlFlags,
								 //Unicode offsets (means something but I don't know what)
								 /*iOffsetCount*/ 0,    /*iOffsetArray*/ NULL,
								 /*oOffsetCount*/ NULL, /*oOffsetArray*/ NULL,
								 //output
								 /*iOutputBufLen*/ bufferSize,
								 /*oInputRead*/ &numBytesRead_nobodyCares, //number of bytes read from input by the converter
								 &outputLength, outputBuffer);
		if (nulTerminate && (bufferSize == outputLength)) {
			//do one more pass so we have room for the nul terminator
			continue;
		}
	} while (err == kTECOutputBufferFullStatus);

	//If we've allowed lossy conversion, then ConvertFromUnicodeToText may return kTECUsedFallbacksStatus. In such cases, we don't care, so hide the error under a nearby coffee table.
	if (allowLossyConversion && (err == kTECUsedFallbacksStatus))
		err = noErr;

	if (err != noErr) {
		NSLog(@"[AIWiredString dataUsingEncoding:%@ allowLossyConversion:%u nulTerminate:%u] got error %li converting text from UTF-16", [NSString localizedNameOfStringEncoding:inEncoding], allowLossyConversion, nulTerminate, (long)err);
	} else {
		if (nulTerminate) outputBuffer[outputLength++] = '\0';
		result = [AIWiredData dataWithBytes:outputBuffer length:outputLength];
	}

	AIWipeMemory(outputBuffer, bufferSize);
	munlock(outputBuffer, bufferSize);
	free(outputBuffer);
	DisposeUnicodeToTextInfo(&converter);

	return result;
}
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding allowLossyConversion:(BOOL)flag
{
	return [self dataUsingEncoding:inEncoding allowLossyConversion:flag nulTerminate:NO];
}
- (AIWiredData *)dataUsingEncoding:(NSStringEncoding)inEncoding
{
	return [self dataUsingEncoding:inEncoding allowLossyConversion:NO];
}

- (const char *)UTF8String
{
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO nulTerminate:YES] bytes];
}

#pragma mark Container methods

- (BOOL)isEqualToString:(NSString *)other
{
	size_t otherLength = [other length];

	size_t otherSize = otherLength * sizeof(unichar);
	unichar *otherBuf = malloc(otherSize);
	NSAssert1(otherBuf != NULL, @"in -[AIWiredString isEqualToString:]: Could not allocate %u bytes to compare strings' equality", otherSize);
	int mlock_retval = mlock(otherBuf, otherSize);
	NSAssert1(mlock_retval == 0, @"in -[AIWiredString isEqualToString:]: Could not wire %u bytes in memory to compare strings' equality", otherSize);

	[other getCharacters:otherBuf];

	Boolean isEquivalent = NO;
	OSStatus err = UCCompareTextDefault(kUCCollateStandardOptions | kUCCollatePunctuationSignificantMask,
										//our data
										backing, length,
										//their data
										otherBuf, otherLength,
										//output
										&isEquivalent,
										/*order*/ NULL);
	NSAssert2(err == noErr, @"in -[AIWiredString isEqualToString:]: UCCompareTextDefault with options %lu returned error %li", (unsigned long)(kUCCollateStandardOptions | kUCCollatePunctuationSignificantMask), (long)err);

	AIWipeMemory(otherBuf, otherSize);
	munlock(otherBuf, otherSize);
	free(otherBuf);

	return isEquivalent;
}
- (BOOL)isEqual:(id)other {
	return [other isKindOfClass:[NSString class]] && [self isEqualToString:other];
}

#pragma mark Description

- (NSString *)description
{
	return [[self retain] autorelease];
}

@end

@implementation AIWiredString (PRIVATE)

- (size_t)makeUTF8:(out UTF8Char **)output length:(out size_t *)outputLength extraBytes:(const size_t)numExtraBytes forUTF16:(const UTF16Char *)input length:(size_t)inputLength
{
	UTF8Char *outBuf = NULL;
	size_t outSize = 0;
	unsigned long j = 0;
	if (!inputLength) {
		//for an empty input string, provide an empty (but valid) input buffer
		outBuf = AIReallocWired(NULL, j = numExtraBytes);
		bzero(outBuf, j);
	} else {
		const size_t outSizeIncrement = getpagesize();
		unsigned long i;

		UnicodeScalarValue scalar;
		UTF16Char surrogateHigh = kUnicodeNotAChar;

		for (i = 0; i < inputLength; ++i) {
#define OUTPUT_BOUNDARY_GUARD \
			if ((!outSize) || (j >= (outSize - numExtraBytes))) { \
				outBuf = AIReallocWired(outBuf, outSize += outSizeIncrement); \
				if (!outBuf) break; \
			}

			OUTPUT_BOUNDARY_GUARD;

			if (surrogateHigh != kUnicodeNotAChar) {
				scalar = UCGetUnicodeScalarValueForSurrogatePair(surrogateHigh, input[i]);
				surrogateHigh = kUnicodeNotAChar;
			} else if (UCIsSurrogateHighCharacter(input[i])) {
				surrogateHigh = input[i];
				continue;
			} else {
				scalar = input[i];
			}

			if (scalar < 0x80) {
				outBuf[j++] = scalar;
			} else {
				u_int8_t xxxxxx =  scalar        & 0x7f;
				u_int8_t yyyyyy = (scalar >>  6) & 0x7f; 
				u_int8_t   zzzz = (scalar >> 12) & 0x0f;
				u_int8_t  uuuuu = (scalar >> 16) & 0x1f;

				if (uuuuu) {
					outBuf[j++] = 0x240 | (uuuuu >> 2);
					OUTPUT_BOUNDARY_GUARD;
					outBuf[j++] =  0x80 | ((uuuuu  & 3) << 4) | zzzz;
					OUTPUT_BOUNDARY_GUARD;
					outBuf[j++] =  0x80 | yyyyyy;
					OUTPUT_BOUNDARY_GUARD;
				} else if (zzzz) {
					outBuf[j++] = 0xe0 | zzzz;
					OUTPUT_BOUNDARY_GUARD;
					outBuf[j++] = 0x80 | yyyyyy;
					OUTPUT_BOUNDARY_GUARD;
				} else if (yyyyyy) {
					outBuf[j++] = 0xc0 | yyyyyy;
					OUTPUT_BOUNDARY_GUARD;
				}
				outBuf[j++] = 0x80 | xxxxxx;
			}
	#undef OUTPUT_BOUNDARY_GUARD
		}

		AISetRangeInMemory(outBuf, NSMakeRange(j, outSize - j), '\0');
	}

	if (output) *output = outBuf;
	else {
		munlock(outBuf, outSize);
		free(outBuf);
	}

	if (outputLength) *outputLength = j;

	return outSize;
}

@end
