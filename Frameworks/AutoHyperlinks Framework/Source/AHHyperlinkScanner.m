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

#import "AHHyperlinkScanner.h"
#import "AHMarkedHyperlink.h"

#define DEFAULT_URL_SCHEME @"http://"
#define ENC_INDEX_KEY @"encIndex"
#define ENC_CHAR_KEY @"encChar"

#define MIN_LINK_LENGTH 4

@interface AHHyperlinkScanner (PRIVATE)
- (AHMarkedHyperlink *)nextURIFromLocation:(unsigned long *)_scanLocation;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSString *)_createLinkifiedString;
#else
- (NSAttributedString *)_createLinkifiedString;
#endif
- (NSRange)_longestBalancedEnclosureInRange:(NSRange)inRange;
- (BOOL)_scanString:(NSString *)inString upToCharactersFromSet:(NSCharacterSet *)inCharSet intoRange:(NSRange *)outRangeRef fromIndex:(unsigned long *)idx;
- (BOOL)_scanString:(NSString *)inString charactersFromSet:(NSCharacterSet *)inCharSet intoRange:(NSRange *)outRangeRef fromIndex:(unsigned long *)idx;
@end

@implementation AHHyperlinkScanner
#pragma mark static variables
	static NSCharacterSet	*skipSet = nil;
	static NSCharacterSet	*endSet = nil;
	static NSCharacterSet	*startSet = nil;
	static NSCharacterSet	*puncSet = nil;
	static NSCharacterSet	*hostnameComponentSeparatorSet = nil;
	static NSArray			*enclosureStartArray = nil;
	static NSCharacterSet	*enclosureSet = nil;
	static NSArray			*enclosureStopArray = nil;
	static NSArray			*encKeys = nil;

@synthesize scanLocation = m_scanLocation;
@dynamic linkifiedString;

#pragma mark runtime initialization
+ (void)initialize
{
	if (self == [AHHyperlinkScanner class]){
		NSMutableCharacterSet *mutableSkipSet = [[NSMutableCharacterSet alloc] init];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		[mutableSkipSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
		skipSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableSkipSet bitmapRepresentation]] retain];
		[mutableSkipSet release];
		
		endSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"'“”‘’,:;>)]}–—.…?!@"] retain];
		
		NSMutableCharacterSet *mutableStartSet = [[NSMutableCharacterSet alloc] init];
		[mutableStartSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[mutableStartSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'“”‘’.…,:;<?!-–—@"]];
		startSet = [[NSCharacterSet characterSetWithBitmapRepresentation:[mutableStartSet bitmapRepresentation]] retain];
		[mutableStartSet release];
		
		puncSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"'“”‘’.…,:;–—<?!"] retain];
		hostnameComponentSeparatorSet = [[NSCharacterSet characterSetWithCharactersInString:@"./"] retain];
		enclosureStartArray = [[NSArray arrayWithObjects:@"(",@"[",@"{",nil] retain];
		enclosureSet = [[NSCharacterSet characterSetWithCharactersInString:@"()[]{}"] retain];
		enclosureStopArray = [[NSArray arrayWithObjects:@")",@"]",@"}",nil] retain];
		encKeys = [[NSArray arrayWithObjects:ENC_INDEX_KEY, ENC_CHAR_KEY, nil] retain];
	}
}

#pragma mark Class Methods
+ (id)hyperlinkScannerWithString:(NSString *)inString
{
	return [[[[self class] alloc] initWithString:inString usingStrictChecking:NO] autorelease];
}

+ (id)strictHyperlinkScannerWithString:(NSString *)inString
{
	return [[[[self class] alloc] initWithString:inString usingStrictChecking:YES] autorelease];
}

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
+ (id)hyperlinkScannerWithAttributedString:(NSAttributedString *)inString
{
	return [[[[self class] alloc] initWithAttributedString:inString usingStrictChecking:NO] autorelease];
}

+ (id)strictHyperlinkScannerWithAttributedString:(NSAttributedString *)inString
{
	return [[[[self class] alloc] initWithAttributedString:inString usingStrictChecking:NO] autorelease];
}
#endif

#pragma mark Init/Dealloc
- (id)init
{
	if((self = [super init])){
		self.scanLocation = 0;
		m_linkifiedString = nil;
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
		m_scanAttrString = nil;
#endif
        m_openEnclosureStack = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithString:(NSString *)inString usingStrictChecking:(BOOL)flag
{
	if((self = [self init])){
		m_scanString = [inString retain];
		m_urlSchemes = [[NSDictionary alloc] initWithObjectsAndKeys:
						@"ftp://", @"ftp",
						nil];
		m_strictChecking = flag;
		m_scanStringLength = [m_scanString length];
	}
	return self;
}

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
- (id)initWithAttributedString:(NSAttributedString *)inString usingStrictChecking:(BOOL)flag
{
	if((self = [self init])){
		m_scanString = [[inString string] retain];
		m_scanAttrString = [inString retain];
		m_urlSchemes = [[NSDictionary alloc] initWithObjectsAndKeys:
						@"ftp://", @"ftp",
						nil];
		m_strictChecking = flag;
		m_scanStringLength = [m_scanString length];
	}
	return self;
}
#endif

- (void)dealloc
{
	self.scanLocation = 0;
	[m_linkifiedString release];
	[m_scanString release];
	[m_urlSchemes release];
    [m_openEnclosureStack release];
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
	if(m_scanAttrString) [m_scanAttrString release];
#endif
	[super dealloc];
}

#pragma mark URI Verification

- (BOOL)isValidURI
{
	return [AHHyperlinkScanner isStringValidURI:m_scanString usingStrict:m_strictChecking fromIndex:nil withStatus:nil schemeLength:nil];
}

+ (BOOL)isStringValidURI:(NSString *)inString usingStrict:(BOOL)useStrictChecking fromIndex:(unsigned long *)sIndex withStatus:(AH_URI_VERIFICATION_STATUS *)validStatus schemeLength:(unsigned long *)schemeLength
{
    AH_BUFFER_STATE	 buf;  // buffer for flex to scan from
	yyscan_t		 scanner; // pointer to the flex scanner opaque type
	const char		*inStringEnc;
    unsigned long	 encodedLength;
	
	if(!validStatus){
		AH_URI_VERIFICATION_STATUS newStatus = AH_URL_INVALID;
		validStatus = &newStatus;
	}
	
	*validStatus = AH_URL_INVALID; // assume the URL is invalid
	
	// Find the fastest 8-bit wide encoding possible for the c string
	NSStringEncoding stringEnc = [inString fastestEncoding];
	if([@" " lengthOfBytesUsingEncoding:stringEnc] > 1U)
		stringEnc = NSUTF8StringEncoding;
	
	if (!(inStringEnc = [inString cStringUsingEncoding:stringEnc])) {
		return NO;
	}
	
	
	encodedLength = strlen(inStringEnc); // length of the string in utf-8
    
	// initialize the buffer (flex automatically switches to the buffer in this function)
	AHlex_init(&scanner);
    buf = AH_scan_string(inStringEnc, scanner);
	
    // call flex to parse the input
    *validStatus = (AH_URI_VERIFICATION_STATUS)AHlex(scanner);
	if(sIndex) *sIndex += AHget_leng(scanner);
	if(schemeLength) *schemeLength = AHget_extra(scanner).schemeLength;
	
    // condition for valid URI's
    if(*validStatus == AH_URL_VALID || *validStatus == AH_MAILTO_VALID || *validStatus == AH_FILE_VALID){
        AH_delete_buffer(buf, scanner); //remove the buffer from flex.
        buf = NULL; //null the buffer pointer for safty's sake.
        
        // check that the whole string was matched by flex.
        // this prevents silly things like "blah...com" from being seen as links
        if(AHget_leng(scanner) == encodedLength){
			AHlex_destroy(scanner);
            return YES;
        }
		// condition for degenerate URL's (A.K.A. URI's sans specifiers), requres strict checking to be NO.
    }else if((*validStatus == AH_URL_DEGENERATE || *validStatus == AH_MAILTO_DEGENERATE || *validStatus == AH_URL_TENTATIVE) && !useStrictChecking){
        AH_delete_buffer(buf, scanner);
        buf = NULL;
        if(AHget_leng(scanner) == encodedLength){
			AHlex_destroy(scanner);
            return YES;
        }
		// if it ain't vaild, and it ain't degenerate, then it's invalid.
    }else{
        AH_delete_buffer(buf, scanner);
        buf = NULL;
		AHlex_destroy(scanner);
        return NO;
    }
    // default case, if the range checking above fails.
	AHlex_destroy(scanner);
    return NO;
}

#pragma mark Accessors

- (AHMarkedHyperlink *)nextURI
{
	NSRange	scannedRange;
	unsigned long scannedLocation = m_scanLocation;
	
    // scan upto the next whitespace char so that we don't unnecessarity confuse flex
    // otherwise we end up validating urls that look like this "http://www.adium.im/ <--cool"
	[self _scanString:m_scanString charactersFromSet:startSet intoRange:nil fromIndex:&scannedLocation];
	
	// main scanning loop
	while([self _scanString:m_scanString upToCharactersFromSet:skipSet intoRange:&scannedRange fromIndex:&scannedLocation]) {
        if (MIN_LINK_LENGTH < scannedRange.length) {
            // Check for and filter  enclosures.  We can't add (, [, etc. to the skipSet as they may be in a URI
            NSString *topEncChar = [m_openEnclosureStack lastObject];
            if(topEncChar || [enclosureSet characterIsMember:[m_scanString characterAtIndex:scannedRange.location]]){
                unsigned long encIdx = [enclosureStartArray indexOfObject:topEncChar? topEncChar : [m_scanString substringWithRange:NSMakeRange(scannedRange.location, 1)]];
                NSRange encRange;
                if(NSNotFound != encIdx) {
                    encRange = [m_scanString rangeOfString:[enclosureStopArray objectAtIndex:encIdx] options:NSBackwardsSearch range:scannedRange];
                    if(NSNotFound != encRange.location){
                         scannedRange.length--;
                        if (topEncChar) {
                            [m_openEnclosureStack removeLastObject];
                        } else {
                            scannedRange.location++;
                            scannedRange.length--;
                        }
                    } else {
                        [m_openEnclosureStack addObject:[enclosureStartArray objectAtIndex:encIdx]];
                    }
                }
            }
            if(!scannedRange.length) break;
            
            // Find balanced enclosure chars
            NSRange longestEnclosure = [self _longestBalancedEnclosureInRange:scannedRange];
            while (scannedRange.length > 2 && [endSet characterIsMember:[m_scanString characterAtIndex:(scannedRange.location + scannedRange.length - 1)]]) {
                if((longestEnclosure.location + longestEnclosure.length) < scannedRange.length){
                    scannedRange.length--;
                }else break;
            }
            
            // Update the scan location
            m_scanLocation = scannedRange.location;
            
            // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
            // this way, we can preserve things like the matched string (to be converted to a NSURL),
            // parent string, its validation status (valid, file, degenerate, etc), and its range in the parent string
            AH_URI_VERIFICATION_STATUS	 validStatus;
            NSString					*_scanString = nil;
            unsigned long				 schemeLength = 0;
            if(MIN_LINK_LENGTH < scannedRange.length) _scanString = [m_scanString substringWithRange:scannedRange];
            if((MIN_LINK_LENGTH < scannedRange.length) && [[self class] isStringValidURI:_scanString usingStrict:m_strictChecking fromIndex:&m_scanLocation withStatus:&validStatus schemeLength:&schemeLength]){
                AHMarkedHyperlink	*markedLink;
                BOOL				 makeLink = TRUE;
                //insert typical specifiers if the URL is degenerate
                switch(validStatus){
                    case AH_URL_DEGENERATE:
                    {
                        NSString *scheme = DEFAULT_URL_SCHEME;
                        unsigned long i = 0;
                        
                        NSRange  firstComponent;
                        [self		  _scanString:_scanString
                       upToCharactersFromSet:hostnameComponentSeparatorSet
                                   intoRange:&firstComponent
                                   fromIndex:&i];
                        
                        if(NSNotFound != firstComponent.location) {
                            NSString *hostnameScheme = [m_urlSchemes objectForKey:[_scanString substringWithRange:firstComponent]];
                            if(hostnameScheme) scheme = hostnameScheme;
                        }
                        
                        _scanString = [scheme stringByAppendingString:_scanString];
                        
                        break;
                    }
                        
                    case AH_MAILTO_DEGENERATE:
                        _scanString = [@"mailto:" stringByAppendingString:_scanString];
                        break;
                    case AH_URL_TENTATIVE:
                    {
                        NSString *scheme = [_scanString substringToIndex:schemeLength];
                        NSArray *apps = (NSArray *)LSCopyAllHandlersForURLScheme((CFStringRef)scheme);

                        if(!apps.count)
                            makeLink = FALSE;
                        [apps release];
                        break;
                    }
                    default:
                        break;
                }
                
                if(makeLink){
                    //make a marked link
                    markedLink = [[AHMarkedHyperlink alloc] initWithString:_scanString
                                                      withValidationStatus:validStatus
                                                              parentString:m_scanString
                                                                  andRange:scannedRange];
                    return [markedLink autorelease];
                }
            }
            
            //step location after scanning a string
            NSRange startRange = [m_scanString rangeOfCharacterFromSet:puncSet options:NSLiteralSearch range:scannedRange];
            if (startRange.location != NSNotFound)
                m_scanLocation = startRange.location + startRange.length;
            else
                m_scanLocation += scannedRange.length;
            
            scannedLocation = m_scanLocation;
        }
    }
	
    // if we're here, then NSScanner hit the end of the string
    // set AHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    m_scanLocation = m_scanStringLength;
    return nil;
}

-(NSArray *)allURIs
{
    NSMutableArray		*rangeArray = [NSMutableArray array];
    AHMarkedHyperlink	*markedLink;
	unsigned long		 _holdOffset = m_scanLocation; // store location for later restoration;
	m_scanLocation = 0; //set the offset to 0.
    
    //build an array of marked links.
	while((markedLink = [self nextURI])){
		[rangeArray addObject:markedLink];
	}
    m_scanLocation = _holdOffset; // reset scanLocation
	return rangeArray;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
-(NSString *)_createLinkifiedString
{
	NSMutableString       *_linkifiedString;
	AHMarkedHyperlink     *markedLink;
	unsigned long          _scanLocationCache = self.scanLocation;
	NSEnumerator          *linkEnumerator = [[self allURIs] reverseObjectEnumerator];
	
	_linkifiedString = [[NSMutableString alloc] initWithString:m_scanString];
	
	while ((markedLink = [linkEnumerator nextObject])) {
		[_linkifiedString replaceCharactersInRange:markedLink.range
		                                withString:[NSString stringWithFormat:@"<a href=\"%@\">%@</a>",
		                                                                      markedLink.URL,
		                                                                      [m_scanString substringWithRange:markedLink.range]]];
	}
	
	self.scanLocation = _scanLocationCache;
	return [_linkifiedString copy];
}

-(NSString *)linkifiedString
{
	if(!m_linkifiedString){
		NSString *newLinkifiedString = [self _createLinkifiedString];
		// compare the old object to nil, and swap in the new value if they match.
		// if the old object (m_linkifiedString) already has a value, release the duplicated new object
		if(OSAtomicCompareAndSwapPtrBarrier(nil, newLinkifiedString, (void *)&m_linkifiedString))
			[m_linkifiedString retain];
	}
	return m_linkifiedString;
}
#else
-(NSAttributedString *)_createLinkifiedString
{
	NSMutableAttributedString	*_linkifiedString;
	AHMarkedHyperlink			*markedLink;
	BOOL						_didFindLinks = NO;
	unsigned long _scanLocationCache = self.scanLocation;
	
	if(m_scanAttrString) {
		_linkifiedString = [m_scanAttrString mutableCopy];
	} else {
		_linkifiedString = [[NSMutableAttributedString alloc] initWithString:m_scanString];
	}
	
	//for each SHMarkedHyperlink, add the proper URL to the proper range in the string.
	for(markedLink in self) {
		NSURL *markedLinkURL;
		_didFindLinks = YES;
		if((markedLinkURL = markedLink.URL)) {
			[_linkifiedString addAttribute:NSLinkAttributeName
									 value:markedLinkURL
									 range:markedLink.range];
		}
	}
	
	self.scanLocation = _scanLocationCache;
	return _didFindLinks? _linkifiedString :
	m_scanAttrString ? [m_scanAttrString retain] : [[NSMutableAttributedString alloc] initWithString:m_scanString];
}

-(NSAttributedString *)linkifiedString
{
	if(!m_linkifiedString){
		NSAttributedString *newLinkifiedString = [self _createLinkifiedString];
		// compare the old object to nil, and swap in the new value if they match.
		// if the old object (m_linkifiedString) already has a value, release the duplicated new object
		if(OSAtomicCompareAndSwapPtrBarrier(nil, newLinkifiedString, (void *)&m_linkifiedString))
			[m_linkifiedString retain];
	}
	return m_linkifiedString;
}
#endif

#pragma mark NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	AHMarkedHyperlink	*currentLink = nil;
	
	NSUInteger fastEnumCount = 0;
	while (fastEnumCount < len && nil != (currentLink = [self nextURI])) {
		stackbuf[fastEnumCount] = currentLink;
		++fastEnumCount;
	}
	
	state->state = (nil == currentLink)? (NSUInteger)currentLink : NSNotFound;
	state->itemsPtr = stackbuf;
	state->mutationsPtr = (unsigned long *)self;
	
	return fastEnumCount;
}

#pragma mark Below Here There Be Private Methods

- (NSRange)_longestBalancedEnclosureInRange:(NSRange)inRange
{
	NSMutableArray	*enclosureStack = nil, *enclosureArray = nil;
	NSString  *matchChar = nil;
	NSDictionary *encDict;
	unsigned long encScanLocation = inRange.location;
	
	while(encScanLocation < inRange.length + inRange.location) {
		[self _scanString:m_scanString upToCharactersFromSet:enclosureSet intoRange:nil fromIndex:&encScanLocation];
		
		if(encScanLocation >= (inRange.location + inRange.length)) break;
		
		matchChar = [m_scanString substringWithRange:NSMakeRange(encScanLocation, 1)];
		
		if([enclosureStartArray containsObject:matchChar]) {
			encDict = [NSDictionary	dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:encScanLocation], matchChar, nil]
												  forKeys:encKeys];
			if(!enclosureStack) enclosureStack = [NSMutableArray array];
			[enclosureStack addObject:encDict];
		}else if([enclosureStopArray containsObject:matchChar]) {
			NSEnumerator *encEnumerator = [enclosureStack objectEnumerator];
			while ((encDict = [encEnumerator nextObject])) {
				unsigned long encTagIndex = [(NSNumber *)[encDict objectForKey:ENC_INDEX_KEY] unsignedLongValue];
				unsigned long encStartIndex = [enclosureStartArray indexOfObjectIdenticalTo:[encDict objectForKey:ENC_CHAR_KEY]];
				if([enclosureStopArray indexOfObjectIdenticalTo:matchChar] == encStartIndex) {
					NSRange encRange = NSMakeRange(encTagIndex, encScanLocation - encTagIndex + 1);
					if(!enclosureStack) enclosureStack = [NSMutableArray array];
					if(!enclosureArray) enclosureArray = [NSMutableArray array];
					[enclosureStack removeObject:encDict];
					[enclosureArray addObject:NSStringFromRange(encRange)];
					break;
				}
			}
		}
		if(encScanLocation < inRange.length + inRange.location)
			encScanLocation++;
	}
	return (enclosureArray && [enclosureArray count])? NSRangeFromString([enclosureArray lastObject]) : NSMakeRange(0, 0);
}

// functional replacement for -[NSScanner scanUpToCharactersFromSet:intoString:]
- (BOOL)_scanString:(NSString *)inString upToCharactersFromSet:(NSCharacterSet *)inCharSet intoRange:(NSRange *)outRangeRef fromIndex:(unsigned long *)idx
{
	unichar			_curChar;
	NSRange			_outRange;
	unsigned long	_scanLength = [inString length];
	unsigned long	_idx;
	
	if(_scanLength <= *idx) return NO;
	
	// Asorb skipSet
	for(_idx = *idx; _scanLength > _idx; _idx++) {
		_curChar = [inString characterAtIndex:_idx];
		if(![skipSet characterIsMember:_curChar]) break;
	}
	
	// scanUpTo:
	for(*idx = _idx; _scanLength > _idx; _idx++) {
		_curChar = [inString characterAtIndex:_idx];
		if([inCharSet characterIsMember:_curChar] || [skipSet characterIsMember:_curChar]) break;
	}
	
	_outRange = NSMakeRange(*idx, _idx - *idx);
	*idx = _idx;
	
	if(_outRange.length) {
		if(outRangeRef) *outRangeRef = _outRange;
		return YES;
	} else {
		return NO;
	}
}

// functional replacement for -[NSScanner scanCharactersFromSet:intoString:]
- (BOOL)_scanString:(NSString *)inString charactersFromSet:(NSCharacterSet *)inCharSet intoRange:(NSRange *)outRangeRef fromIndex:(unsigned long *)idx
{
	unichar			_curChar;
	NSRange			_outRange;
	unsigned long	_scanLength = [inString length];
	unsigned long	_idx = *idx;
	
	if(_scanLength <= _idx) return NO;
	
	// Asorb skipSet
	for(_idx = *idx; _scanLength > _idx; _idx++) {
		_curChar = [inString characterAtIndex:_idx];
		if(![skipSet characterIsMember:_curChar]) break;
	}
	
	// scanCharacters:
	for(*idx = _idx; _scanLength > _idx; _idx++) {
		_curChar = [inString characterAtIndex:_idx];
		if(![inCharSet characterIsMember:_curChar]) break;
	}
	
	_outRange = NSMakeRange(*idx, _idx - *idx);
	*idx = _idx;
	
	if(_outRange.length) {
		if(outRangeRef) *outRangeRef = _outRange;
		return YES;
	} else {
		return NO;
	}
}
@end
