/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "GetMetadataForHTMLLog-Additions.h"

//From LMX. Included under the BSD license. http://trac.adium.im/wiki/LMXParser
static BOOL getSurrogatesForUnicodeScalarValue(const UTF32Char scalar, unichar *outHigh, unichar *outLow);

/*
 * @brief These additions are all from AIUtilities
 *
 * The spotlight importer should include this file to get these specific additions.
 * If the GetMetadataForHTMLLog class is used in a situation in which AIUtilities is linked in already, it is
 * not necessary to include this implementation file.
 */
@implementation NSScanner (AdiumSpotlightImporterAdditions)

- (BOOL)scanUnsignedInt:(unsigned int *)unsignedIntValue
{
	//skip characters if necessary
	NSCharacterSet *skipSet = [self charactersToBeSkipped];
	[self setCharactersToBeSkipped:nil];
	[self scanCharactersFromSet:skipSet intoString:NULL];
	[self setCharactersToBeSkipped:skipSet];
	
	NSString *string = [self string];
	NSRange range = NSMakeRange([self scanLocation], 0);
	register NSUInteger length = [string length] - range.location; //register because it is used in the loop below.
	range.length = length;
	
	unichar *buf = malloc(length * sizeof(unichar));
	[string getCharacters:buf range:range];
	
	register unsigned i = 0;
	
	if (length && (buf[i] == '+')) {
		++i;
	}
	if (i >= length) { free(buf); return NO; }
	if ((buf[i] < '0') || (buf[i] > '9')) { free(buf); return NO; }
	
	unsigned total = 0;
	while (i < length) {
		if ((buf[i] >= '0') && (buf[i] <= '9')) {
			total *= 10;
			total += buf[i] - '0';
			++i;
		} else {
			break;
		}
	}
	[self setScanLocation:i];
	*unsignedIntValue = total;
	free(buf);
	return YES;
}

@end

//From AIUtilities
@implementation NSString (AdiumSpotlightImporterAdditions)

/*
 * @brief Read a string from a file, assuming it to be UTF8
 *
 * If it can not be read as UTF8, it will be read as ASCII.
 */
+ (NSString *)stringWithContentsOfUTF8File:(NSString *)path
{
	NSString	*string;
	
	if ((floor(kCFCoreFoundationVersionNumber) > kCFCoreFoundationVersionNumber10_3)) {
		NSError	*error = nil;
		
		string = [NSString stringWithContentsOfFile:path
										   encoding:NSUTF8StringEncoding 
											  error:&error];
		
		if (error) {
			BOOL	handled = NO;
			
			if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
				NSInteger		errorCode = [error code];
				
				//XXX - I'm sure these constants are defined somewhere, but I can't find them. -eds
				if (errorCode == 260) {
					//File not found.
					string = nil;
					handled = YES;
					
				} else if (errorCode == 261) {
					/* Reason: File could not be opened using text encoding Unicode (UTF-8).
					* Description: Text encoding Unicode (UTF-8) is not applicable.
					*
					* We couldn't read the file as UTF8.  Let the system try to determine the encoding.
					*/
					NSError				*newError = nil;
					
					string = [NSString stringWithContentsOfFile:path
													   encoding:NSASCIIStringEncoding
														  error:&newError];
					
					//If there isn't a new error, we recovered reasonably successfully...
					if (!newError) {
						handled = YES;
					}
				}
			}
			
			if (!handled) {
				NSLog(@"Error reading %@:\n%@; %@.",path,
					  [error localizedDescription], [error localizedFailureReason]);
			}
		}
		
	} else {
		NSData	*data = [NSData dataWithContentsOfFile:path];
		
		if (data) {
			string = [[[NSString alloc] initWithData:data
											encoding:NSUTF8StringEncoding] autorelease];
			if (!string) {
				string = [[[NSString alloc] initWithData:data
												encoding:NSASCIIStringEncoding] autorelease];			
			}
			
			if (!string) {
				NSLog(@"Error reading %@",path);
			}
		} else {
			//File not found
			string = nil;
		}
	}
	
	return string;
}

//stringByUnescapingFromXMLWithEntities: was written by Peter Hosey and is explicitly released under the BSD license.
/*
 Copyright ¬© 2006 Peter Hosey
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of Peter Hosey nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
- (NSString *)stringByUnescapingFromXMLWithEntities:(NSDictionary *)entities
{
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_3) {
		return [(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)self, (CFDictionaryRef)entities) autorelease];
	} else {
		//COMPAT 10.3
		
		if (!entities) {
			static const unichar nbsp = 0xa0;
			entities = [NSDictionary dictionaryWithObjectsAndKeys:
				@"&",  @"amp",
				@"<",  @"lt",
				@">",  @"gt",
				@"\"", @"quot",
				@"'",  @"apos",
				[NSString stringWithCharacters:&nbsp length:1], @"nbsp",
				nil];
		}
		
		NSUInteger len = [self length];
		NSMutableString *result = [NSMutableString stringWithCapacity:len];
		NSScanner *scanner = [NSScanner scannerWithString:self];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithRange:(NSRange){ 0, 0 }]];
		
		NSString *chunk = nil;
		while (YES) { //Actual condition is below.
			chunk = nil;
			if ([scanner scanUpToString:@"&" intoString:&chunk]) {
				[result appendString:chunk];
			}
			[scanner scanString:@"&" intoString:NULL];
			
			//Condition is here.
			if ([scanner scanLocation] >= len)
				break;
			
			if ([scanner scanString:@"#" intoString:NULL]) {
				NSString *hexIdentifier = nil;
				if ([scanner scanString:@"x" intoString:&hexIdentifier] || [scanner scanString:@"X" intoString:&hexIdentifier]) {
					//Probably hex.
					unsigned unichar32 = 0xffff;
					if (![scanner scanHexInt:&unichar32]) {
						[result appendFormat:@"&#%@", hexIdentifier];
					} else if (![scanner scanString:@";" intoString:NULL]) {
						[result appendFormat:@"&#%@%u", hexIdentifier, unichar32];
					} else {
						unichar high, low;
						if (getSurrogatesForUnicodeScalarValue(unichar32, &high, &low)) {
							[result appendFormat:@"%C%C", high, low];
						} else {
							[result appendFormat:@"%C", low];
						}
					}
				} else {
					//Not hex. Hopefully decimal.
					int unichar32 = 65535; //== 0xffff
					if (![scanner scanInt:&unichar32]) {
						[result appendString:@"&#"];
					} else if (![scanner scanString:@";" intoString:NULL]) {
						[result appendFormat:@"&#%i", unichar32];
					} else {
						unichar high, low;
						if (getSurrogatesForUnicodeScalarValue(unichar32, &high, &low)) {
							[result appendFormat:@"%C%C", high, low];
						} else {
							[result appendFormat:@"%C", low];
						}
					}
				}
			} else {
				//Not a numeric entity. Should be a named entity.
				NSString *entityName = nil;
				if (![scanner scanUpToString:@";" intoString:&entityName]) {
					[result appendString:@"&"];
				} else {
					//Strip the semicolon.
					NSString *entity = [entities objectForKey:entityName];
					if (entity) {
						[result appendString:entity];
						
					} else {
						NSLog(@"-[NSString(AIStringAdditions) stringByUnescapingFromXMLWithEntities]: Named entity %@ unknown.", entityName);
					}
					[scanner scanString:@";" intoString:NULL];
				}
			}
		}
		
		return [NSString stringWithString:result];
	}
}

@end

static BOOL getSurrogatesForUnicodeScalarValue(const UTF32Char scalar, unichar *outHigh, unichar *outLow) {
	if(scalar <= 0xffff) {
		if(outHigh)
			*outHigh = 0x0000;
		if(outLow)
			*outLow  = scalar;
		return NO;
	}

	//note: names uuuuu, wwww, and xxxxx+ are taken from the Unicode book (section 3.9, table 3-4).
	union {
		UTF32Char scalar;
		struct {
			unsigned unused:     11;
			unsigned uuuuu:       5;
			unsigned xxxxxx:      6;
			unsigned xxxxxxxxxx: 10;
		} components;
	} componentsUnion = {
		.scalar = scalar
	};

	if(outHigh) {
		union {
			struct {
				unsigned highPrefix: 6;
				unsigned wwww:       4;
				unsigned xxxxxx:     6;
			} highComponents;
			unichar codeUnit;
		} highUnion = {
			.highComponents = {
				.highPrefix = 0x36, //0b110110
				.wwww   = componentsUnion.components.uuuuu - 1,
				.xxxxxx = componentsUnion.components.xxxxxx,
			}
		};
		*outHigh = highUnion.codeUnit;
	}

	if(outLow) {
		union {
			struct {
				unsigned lowPrefix:   6;
				unsigned xxxxxxxxxx: 10;
			} lowComponents;
			unichar codeUnit;
		} lowUnion = {
			.lowComponents = {
				.lowPrefix = 0x37, //0b110111
				.xxxxxxxxxx = componentsUnion.components.xxxxxxxxxx,
			}
		};
		*outLow = lowUnion.codeUnit;
	};

	return YES;
}
