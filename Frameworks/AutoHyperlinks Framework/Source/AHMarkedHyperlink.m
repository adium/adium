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

@synthesize range = linkRange, URL = linkURL, parentString = pString, validationStatus = urlStatus;
#pragma mark init and dealloc

+ (id)hyperlinkWithString:(NSString *)inString
	 withValidationStatus:(AH_URI_VERIFICATION_STATUS)status
			 parentString:(NSString *)pInString
				 andRange:(NSRange)inRange
{
	return [[[[self class] alloc] initWithString:inString
							withValidationStatus:status
									parentString:pInString
										andRange:inRange] autorelease];
}

// one really big init method that does it all...
- (id)initWithString:(NSString *)inString
withValidationStatus:(AH_URI_VERIFICATION_STATUS)status
		parentString:(NSString *)pInString
			andRange:(NSRange)inRange
{
	if((self = [self init])) {
		[self setURLFromString:inString];
		self.range = inRange;
		self.parentString = pInString;
		self.validationStatus = status;
	}
	
	return self;
}

- (id)init
{
	if((self = [super init])){
		self.range = NSMakeRange(0, 0);
		self.validationStatus = 0;
		self.parentString = nil;
		self.URL = nil;
	}
	
	return self;
}

- (void)dealloc
{
	self.range = NSMakeRange(0, 0);
	self.validationStatus = 0;
	self.parentString = nil;
	self.URL = nil;
	
	[super dealloc];
}

#pragma mark Transformers

- (void)setURLFromString:(NSString *)inString
{
	NSString	*linkString, *preString;
	
	preString = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, 
																					(CFStringRef)inString, 
																					CFSTR(""), 
																					kCFStringEncodingUTF8);
	
	linkString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																	 preString? (CFStringRef)preString : (CFStringRef)inString,
																	 (CFStringRef)@"#[]",
																	 NULL,
																	 kCFStringEncodingUTF8);
	self.URL = [NSURL URLWithString:linkString];
	// Because -[NSURL URLWithString:(NSString*)inString] fails creating a link with 2 fragment hashes, but we don't want to escape the first one, we esape all '#' to "%23" then unescape the first back to '#'.  rdar://9927055
	if(!self.URL) {
		[preString release]; preString = nil;
		preString = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, 
																						(CFStringRef)preString, 
																						CFSTR(""), 
																						kCFStringEncodingUTF8);
		[linkString release]; linkString = nil;
		linkString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																		 preString? (CFStringRef)preString : (CFStringRef)inString,
																		 (CFStringRef)@"[]",
																		 NULL,
																		 kCFStringEncodingUTF8);
		NSRange fragmentRange = [linkString rangeOfString:@"%23"];
		NSMutableString *mutaLinkString = nil;
		if (fragmentRange.location != NSNotFound) {
			mutaLinkString = [linkString mutableCopy];
			[mutaLinkString replaceOccurrencesOfString:@"%23" withString:@"#" options:0 range:fragmentRange];
		}
		self.URL = [NSURL URLWithString:mutaLinkString];
		[mutaLinkString release];
	}
	
	[linkString release];
	if(preString) [preString release];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	AHMarkedHyperlink   *newLink = [[[self class] alloc] initWithString:[self.URL absoluteString]
	                                                            withValidationStatus:self.validationStatus
	                                                                    parentString:self.parentString
	                                                                        andRange:self.range];
	return newLink;
}

#pragma mark NSComparisonMethods
- (BOOL)doesContain:(id)object
{
	if([object isKindOfClass:[NSURL class]])
		return [(NSURL *)object isEqualTo:self.URL];
	if([object isKindOfClass:[NSString class]])
		return [(NSString *)object isEqualTo:self.parentString];
	
	return NO;
}

- (BOOL)isLike:(NSString *)aString
{
	return [[self.parentString substringWithRange:self.range] isLike:aString] ||
	[[self.URL absoluteString] isLike:aString];
}

- (BOOL)isCaseInsensitiveLike:(NSString *)aString
{
	return [[self.parentString substringWithRange:self.range] isCaseInsensitiveLike:aString] ||
	[[self.URL absoluteString] isCaseInsensitiveLike:aString];
}

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[AHMarkedHyperlink class]] &&
	   ((AHMarkedHyperlink *)object).validationStatus == self.validationStatus &&
	   ((AHMarkedHyperlink *)object).range.location == self.range.location &&
	   ((AHMarkedHyperlink *)object).range.length == self.range.length &&
	   [((AHMarkedHyperlink *)object).parentString isEqualTo:self.parentString] &&
	   [((AHMarkedHyperlink *)object).URL isEqualTo:self.URL])
		return YES;
	return NO;
}

- (BOOL)isGreaterThan:(id)object
{
	if([object isKindOfClass:[AHMarkedHyperlink class]])
		return [[((AHMarkedHyperlink *)object).parentString substringWithRange:((AHMarkedHyperlink *)object).range]
				isGreaterThan:[self.parentString substringWithRange:self.range]];
	return NO;
}

- (BOOL)isLessThan:(id)object
{
	if([object isKindOfClass:[NSURL class]])
		return [(NSURL *)object isLessThan:self.URL];
	if([object isKindOfClass:[NSString class]])
		return [(NSString *)object isLessThan:self.parentString];
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
