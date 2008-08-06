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

#import "AIDLLinkScanner.h"
#import "AIDLLexer.h"

@interface AIDLLinkScanner (PRIVATE)
- (AHMarkedHyperlink *)nextURLFromString:(NSString *)inString;
@end

@implementation AIDLLinkScanner

#pragma mark utility

- (AI_DEV_LINK_VERIFICATION_STATUS)validationStatus
{
	return validStatus;
}

#pragma mark primitive methods

- (BOOL)isStringValidURL:(NSString *)inString
{
    AIDL_BUFFER_STATE buf;  // buffer for flex to scan from
	const char		*inStringUTF8;
    unsigned		utf8Length;
    
	validStatus = AIDL_URL_INVALID; // assume the URL is invalid

	if (!(inStringUTF8 = [inString UTF8String])) {
		return NO;
	}

	utf8Length = strlen(inStringUTF8); // length of the string in utf-8
    
	// initialize the buffer (flex automatically switches to the buffer in this function)
    buf = AIDL_scan_string(inStringUTF8);

    // call flex to parse the input
    validStatus = AIDLlex();

    // condition for valid URI's
    if(validStatus == AIDL_REVISION || validStatus == AIDL_CHANGESET || validStatus == AIDL_TICKET){
        AIDL_delete_buffer(buf); //remove the buffer from flex.
        buf = NULL; //null the buffer pointer for safty's sake.
        
        // check that the whole string was matched by flex.
        // this prevents silly things like "blah...com" from being seen as links
        if(AIDLleng == utf8Length){
            return YES;
        }
	}else{
        AIDL_delete_buffer(buf);
        buf = NULL;
        return NO;
    }
    // default case, if the range checking above fails.
    return NO;
}

/*!
 * @brief Retreives the next URL from the given string
 * 
 * Private to AIDLLinkScanner.  Calling on this externally could create some weird results.
 *
 * @return a AHMarkedHyperlink representing the given URL or nil, if there are no more hyperlinks. 
 */
- (AHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSString    *scanString = nil;

	//get our location from AIDLStringOffset, so we can pick up where we left off
    int			location = AIDLStringOffset;

	static NSCharacterSet *skipSet = nil;
    if (!skipSet) {
        NSMutableCharacterSet *mutableSkipSet = [[NSMutableCharacterSet alloc] init];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
        [mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
		skipSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableSkipSet bitmapRepresentation]] retain];
		[mutableSkipSet release];
    }

	static NSCharacterSet *endSet = nil;
    if (!endSet) {
        endSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"',:;>)}.?!"] retain];
    }
	
	static NSCharacterSet *startSet = nil;
    if (!startSet) {
        NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [mutableStartSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"\"',:;<.?!-"]];
		startSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableStartSet bitmapRepresentation]] retain];
		[mutableStartSet release];
    }

	static NSCharacterSet *hostnameComponentSeparatorSet = nil;	
   	if (!hostnameComponentSeparatorSet) {
   		hostnameComponentSeparatorSet = [[NSCharacterSet characterSetWithCharactersInString:@"./"] retain];
   	}

	static NSArray *enclosureStartArray;
	if(!enclosureStartArray){
		enclosureStartArray = [[NSArray arrayWithObjects:@"(",@"{",nil] retain];
	}

	static NSCharacterSet *enclosureSet;
	if(!enclosureSet){
#define URL_ENCLOSURE_CHARACTERS @"(){}"
		enclosureSet = [[NSCharacterSet characterSetWithCharactersInString:URL_ENCLOSURE_CHARACTERS] retain];
	}
		
	static NSArray *enclosureStopArray;
	if(!enclosureStopArray){
		enclosureStopArray = [[NSArray arrayWithObjects:@")",@"}",nil] retain];
	}
	
#define ENC_INDEX_KEY @"encIndex"
#define ENC_CHAR_KEY @"encChar"
	static NSArray *encKeys;
	if(!encKeys){
		encKeys = [[NSArray arrayWithObjects:ENC_INDEX_KEY, ENC_CHAR_KEY, nil] retain];
	}
    // scan upto the next whitespace char so that we don't unnecessarity confuse flex
    // otherwise we end up validating urls that look like this "http://www.adiumx.com/ <--cool"
    NSScanner *preScanner = [[[NSScanner alloc] initWithString:inString] autorelease];
    [preScanner setCharactersToBeSkipped:skipSet];
    [preScanner setScanLocation:location];

    [preScanner scanCharactersFromSet:startSet intoString:nil];

    while([preScanner scanUpToCharactersFromSet:skipSet intoString:&scanString]) {
        unsigned int scannedLocation = [preScanner scanLocation];
		if([enclosureSet characterIsMember:[scanString characterAtIndex:0]]){
			unsigned int encIdx = [enclosureStartArray indexOfObject:[scanString substringWithRange:NSMakeRange(0, 1)]];
			NSRange encRange;
			if(NSNotFound != encIdx) {
				encRange = [scanString rangeOfString:[enclosureStopArray objectAtIndex:encIdx] options:NSBackwardsSearch];
				if(NSNotFound != encRange.location){
					scannedLocation -= [scanString length] - encRange.location;
					scanString = [scanString substringWithRange:NSMakeRange(1, encRange.location-1)];
				}else{
					scanString = [scanString substringWithRange:NSMakeRange(1, [scanString length]-1)];
				}
			}
		}
		if(![scanString length]) break;
		
		unsigned int localStringLen = [scanString length];
		unsigned int finalStringLen = localStringLen;
		
		// Find balanced enclosure chars
		NSMutableArray	*enclosureStack = [NSMutableArray arrayWithCapacity:2]; // totally arbitrary.
		NSMutableArray	*enclosureArray = [NSMutableArray arrayWithCapacity:2];
		NSString  *matchChar = nil;
		NSScanner *enclosureScanner = [[[NSScanner alloc] initWithString:scanString] autorelease];
		NSDictionary *encDict;
		
		unsigned int encScanLocation = 0;
		
		while(encScanLocation < [[enclosureScanner string] length]) {
			[enclosureScanner scanUpToCharactersFromSet:enclosureSet intoString:nil];
			encScanLocation = [enclosureScanner scanLocation];
			
			if(encScanLocation >= [[enclosureScanner string] length]) break;
			matchChar = [scanString substringWithRange:NSMakeRange(encScanLocation, 1)];
			if([enclosureStartArray containsObject:matchChar]) {
				encDict = [NSDictionary	dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:encScanLocation], matchChar, nil]
													  forKeys:encKeys];
				[enclosureStack addObject:encDict];
			}else if([enclosureStopArray containsObject:matchChar]) {
				NSEnumerator *encEnumerator = [enclosureStack objectEnumerator];
				while ((encDict = [encEnumerator nextObject])) {
					unsigned int encTagIndex = [(NSNumber *)[encDict objectForKey:ENC_INDEX_KEY] unsignedIntValue];
					unsigned int encStartIndex = [enclosureStartArray indexOfObjectIdenticalTo:[encDict objectForKey:ENC_CHAR_KEY]];
					if([enclosureStopArray indexOfObjectIdenticalTo:matchChar] == encStartIndex) {
						NSRange encRange = NSMakeRange(encTagIndex, encScanLocation - encTagIndex);
						[enclosureStack removeObject:encDict];
						[enclosureArray addObject:NSStringFromRange(encRange)];
						break;
					}
				}
			}
			if(encScanLocation < [[enclosureScanner string] length])
				[enclosureScanner setScanLocation:encScanLocation+1];
		}
		NSRange lastEnclosureRange = NSMakeRange(0, 0);
		if([enclosureArray count]) lastEnclosureRange = NSRangeFromString([enclosureArray lastObject]);
		while (finalStringLen > 2 && [endSet characterIsMember:[scanString characterAtIndex:finalStringLen - 1]]) {
			if((lastEnclosureRange.location + lastEnclosureRange.length + 1) < finalStringLen){
				scanString = [scanString substringToIndex:finalStringLen - 1];
				finalStringLen--;
			}else break;
		}

        AIDLStringOffset = scannedLocation - finalStringLen;

        // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
        // this way, we can preserve things like the matched string (to be converted to a NSURL),
        // parent string, it's validation status (valid, file, degenerate, etc), and it's range in the parent string
        if((finalStringLen > 0) && [self isStringValidURL:scanString]){
            AHMarkedHyperlink	*markedLink;
			NSRange				urlRange;
			
			urlRange = NSMakeRange(scannedLocation - localStringLen, finalStringLen);

            // make the nice URLs
			NSString	*numString;
            switch(validStatus) {
                case AIDL_REVISION:
					numString = [scanString substringFromIndex:1];
					scanString = [@"http://trac.adiumx.com/changeset/" stringByAppendingString:numString];
                    break;
				
				case AIDL_CHANGESET:
					numString = [scanString substringWithRange:NSMakeRange(1, [scanString length] - 2)];
					scanString = [@"http://trac.adiumx.com/changeset/" stringByAppendingString:numString];
                    break;

                case AIDL_TICKET:
					numString = [scanString substringFromIndex:1];
					scanString = [@"http://trac.adiumx.com/ticket/" stringByAppendingString:numString];
                    break;
                default:
                    break;
            }
            
            //make a marked link
            markedLink = [[AHMarkedHyperlink alloc] initWithString:scanString
											  withValidationStatus:validStatus
													  parentString:inString
														  andRange:urlRange];
            return [markedLink autorelease];
        }
		
        //step location after scanning a string
		NSRange startRange = [scanString rangeOfCharacterFromSet:startSet];
		if (startRange.location != NSNotFound) {
			location += startRange.location;
		}else{
			location += [scanString length];
			if(location >= [inString length])
				location--;
		}
		[preScanner setScanLocation:location++];
    }
	
    // if we're here, then NSScanner hit the end of the string
    // set AIDLStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    AIDLStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing


-(NSArray *)allURLsFromString:(NSString *)inString
{
    AIDLStringOffset = 0; //set the offset to 0.
    NSMutableArray		*rangeArray = nil;
    AHMarkedHyperlink	*markedLink;
    
    //build an array of marked links.
    while([inString length] > AIDLStringOffset){
        if((markedLink = [self nextURLFromString:inString])){
			if(!rangeArray) rangeArray = [NSMutableArray array];
            [rangeArray addObject:markedLink];
        }
    }
    
	return rangeArray;
}


-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    // since a NSTextView is really just a glorified NSMutableAttributedString,
    // we can take the string and send it out to allURLsFromString:
    return [self allURLsFromString:[inView string]];
}


-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    //build an array from the input string and get its obj. enumerator
    NSArray				*rangeArray = [self allURLsFromString:[inString string]];

	if([rangeArray count]){
		NSMutableAttributedString	*linkifiedString;
		NSEnumerator				*enumerator;
		AHMarkedHyperlink			*markedLink;
		
		linkifiedString = [[inString mutableCopy] autorelease];

		//for each SHMarkedHyperlink, add the proper URL to the proper range in the string.
		enumerator = [rangeArray objectEnumerator];
		while((markedLink = [enumerator nextObject])){
			NSURL *markedLinkURL;
			
			if((markedLinkURL = [markedLink URL])){
				[linkifiedString addAttribute:NSLinkAttributeName
										value:markedLinkURL
										range:[markedLink range]];
			}
		}
		
		return linkifiedString;

    }else{
		//If no links were found, just return the string we were passed
		return [[inString retain] autorelease];
	}
}


- (void)linkifyTextView:(NSTextView *)inView
{
	NSAttributedString *newAttributedString;

	// like allURLsFromTextView before it, we can just call the linkifyString: method here
	// then replace the NSTextView's contents with it.
	newAttributedString = [self linkifyString:[inView attributedSubstringFromRange:NSMakeRange(0,[[inView string] length])]];

	[[inView textStorage] setAttributedString:newAttributedString];
}

@end
