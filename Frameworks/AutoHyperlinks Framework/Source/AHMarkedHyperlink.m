/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AHMarkedHyperlink.h"

@implementation AHMarkedHyperlink

#pragma mark init and dealloc

// one really big init method that does it all...
- (id)initWithString:(NSString *)inString withValidationStatus:(AH_URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange
{
	if((self = [self init])) {
		[self setURLFromString:inString];
		linkRange = inRange;
		[self setParentString:pInString];
		urlStatus = status;
	}

	return self;
}

- (id)init
{
	if((self = [super init])){
		linkURL = nil;
		pString = nil;
	}

	return self;
}

- (void)dealloc
{
	[linkURL release];
	[pString release];

	[super dealloc];
}

#pragma mark Accessors

- (NSRange)range
{
	return linkRange;
}

- (NSString *)parentString
{
	return pString;
}

- (NSURL *)URL
{
	return linkURL;
}

- (AH_URI_VERIFICATION_STATUS)validationStatus
{
	return urlStatus;
}

#pragma mark Transformers

- (void)setRange:(NSRange)inRange
{
	linkRange = inRange;
}

- (void)setURL:(NSURL *)inURL
{
	if(linkURL != inURL){
		[linkURL release];
		linkURL = [inURL retain];
	}
}

- (void)setURLFromString:(NSString *)inString
{
	NSString	*linkString;

	linkString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
	                                        (CFStringRef)inString,
	                                        (CFStringRef)@"#%",
	                                        NULL,
	                                        kCFStringEncodingUTF8); // kCFStringEncodingISOLatin1 );

	[linkURL release];
	linkURL = [[NSURL alloc] initWithString:linkString];

	[linkString release];
}

- (void)setValidationStatus:(AH_URI_VERIFICATION_STATUS)status
{
	urlStatus = status;
}

- (void)setParentString:(NSString *)pInString
{
	if(pString != pInString){
		[pString release];
		pString = [pInString retain];
	}
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	AHMarkedHyperlink   *newLink = [[[self class] allocWithZone:zone] initWithString:[[self URL] absoluteString]
	                                                            withValidationStatus:[self validationStatus]
	                                                                    parentString:[self parentString]
	                                                                        andRange:[self range]];
	return newLink;
}

#pragma mark NSComparisonMethods
- (BOOL)doesContain:(id)object
{
	if([object isKindOfClass:[NSURL class]])
		return [(NSURL *)object isEqualTo:[self URL]]? YES : NO;
	if([object isKindOfClass:[NSString class]])
		return [(NSString *)object isEqualTo:[self parentString]]? YES : NO;
	
	return NO;
}

- (BOOL)isLike:(NSString *)aString
{
	return [[[self parentString] substringWithRange:[self range]] isLike:aString] ||
			[[[self URL] absoluteString] isLike:aString];
}

- (BOOL)isCaseInsensitiveLike:(NSString *)aString
{
	return [[[self parentString] substringWithRange:[self range]] isCaseInsensitiveLike:aString] ||
			[[[self URL] absoluteString] isCaseInsensitiveLike:aString];
}

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[AHMarkedHyperlink class]] &&
	   [(AHMarkedHyperlink *) object validationStatus] == [self validationStatus] &&
	   [(AHMarkedHyperlink *)object range].location == [self range].location &&
	   [(AHMarkedHyperlink *)object range].length == [self range].length &&
	   [[(AHMarkedHyperlink *)object parentString] isEqualTo:[self parentString]] &&
	   [[(AHMarkedHyperlink *)object URL] isEqualTo:[self URL]])
		return YES;
	return NO;
}

- (BOOL)isGreaterThan:(id)object
{
	if([object isKindOfClass:[AHMarkedHyperlink class]])
		return [[[object parentString] substringWithRange:[object range]]
				isGreaterThan:[[self parentString] substringWithRange:[self range]]]? YES : NO;
	return NO;
}

- (BOOL)isLessThan:(id)object
{
	if([object isKindOfClass:[NSURL class]])
		return [(NSURL *)object isLessThan:[self URL]]? YES : NO;
	if([object isKindOfClass:[NSString class]])
		return [(NSString *)object isLessThan:[self parentString]]? YES : NO;
	return NO;
}

- (BOOL)isGreaterThanOrEqualTo:(id)object
{
	return [self isGreaterThan:object] || [self isEqualTo:object];
}

- (BOOL)isLessThanOrEqualTo:(id)object
{
	return [self isLessThan:object] || [self isEqualTo:object];
}
@end
