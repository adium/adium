#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h> 
#import "GetMetadataForHTMLLog.h"
#import "NSCalendarDate+ISO8601Parsing.h"

/*
 Relevant keys from MDItem.h we use or may want to use:
 
 @constant kMDItemContentCreationDate
 This is the date that the contents of the file were created,
 has an application specific semantic.
 Type is a CFDate.

 @constant kMDItemTextContent
 Contains the text content of the document. Type is a CFString.
 
 @constant kMDItemDisplayName
 This is the localized version of the LaunchServices call
 LSCopyDisplayNameForURL()/LSCopyDisplayNameForRef().

 @const  kMDItemInstantMessageAddresses
 Instant message addresses for this item. Type is an Array of CFStrings.
 */
 
/* -----------------------------------------------------------------------------
Get metadata attributes from file

This function's job is to extract useful information your file format supports
and return it as a dictionary
----------------------------------------------------------------------------- */

Boolean GetMetadataForXMLLog(NSMutableDictionary *attributes, NSString *pathToFile);
NSString *GetTextContentForXMLLog(NSString *pathToFile);

Boolean GetMetadataForFile(void* thisInterface, 
						   CFMutableDictionaryRef attributes, 
						   CFStringRef contentTypeUTI,
						   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
	Boolean				success = FALSE;
	NSAutoreleasePool	*pool;
	pool = [[NSAutoreleasePool alloc] init];

	if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.htmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		success = GetMetadataForHTMLLog((NSMutableDictionary *)attributes, (NSString *)pathToFile);
	} else if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.xmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		success = GetMetadataForXMLLog((NSMutableDictionary *)attributes, (NSString *)pathToFile);
	} else {
		NSLog(@"We were passed %@, of type %@, which is an unknown type",pathToFile,contentTypeUTI);
	}

	[pool release];
	
    return success;
}

/*!
 * @brief Copy the text content for a file
 *
 * This is the text which would be the kMDItemTextContent for the file in Spotlight.
 *
 * @param contentTypeUTI The UTI type. If NULL, the extension of pathToFile will be used
 * @param pathToFile The full path to the file
 *
 * @result The kMDItemTextContent. Follows the Copy rule.
 */
CFStringRef CopyTextContentForFile(CFStringRef contentTypeUTI,
								   CFStringRef pathToFile)
{
	NSAutoreleasePool	*pool;
	CFStringRef			textContent;
	pool = [[NSAutoreleasePool alloc] init];
	
	//Deteremine the UTI type if we weren't passed one
	if (contentTypeUTI == NULL) {
		if (CFStringCompare((CFStringRef)[(NSString *)pathToFile pathExtension],
							CFSTR("chatLog"),
							(kCFCompareBackwards | kCFCompareCaseInsensitive)) == kCFCompareEqualTo) {
			contentTypeUTI = CFSTR("com.adiumx.xmllog");
		} else if (CFStringCompare((CFStringRef)[(NSString *)pathToFile pathExtension],
							CFSTR("AdiumXMLLog"),
							(kCFCompareBackwards | kCFCompareCaseInsensitive)) == kCFCompareEqualTo) {
			contentTypeUTI = CFSTR("com.adiumx.xmllog");
		} else {
			//Treat all other log extensions as HTML logs (plaintext will come out fine this way, too)
			contentTypeUTI = CFSTR("com.adiumx.htmllog");
		}
	}
		
	if (CFStringCompare(contentTypeUTI, CFSTR("com.adiumx.htmllog"), kCFCompareBackwards) == kCFCompareEqualTo) {
		textContent = (CFStringRef)GetTextContentForHTMLLog((NSString *)pathToFile);
	} else if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.xmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		BOOL isDir;
		if ([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)pathToFile isDirectory:&isDir]) {
			/* If we have a chatLog bundle, we want to get the text content for the xml file inside */
			if (isDir) pathToFile = (CFStringRef)[(NSString *)pathToFile stringByAppendingPathComponent:
									 [[[(NSString *)pathToFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
			
			textContent = (CFStringRef)GetTextContentForXMLLog((NSString *)pathToFile);
		} else {
			textContent = nil;
		}
		
	} else {
		textContent = nil;
		NSLog(@"We were passed %@, of type %@, which is an unknown type",pathToFile,contentTypeUTI);
	}

	if (textContent) CFRetain(textContent);
	[pool release];
	
	return textContent;
}

/*!
 * @brief get metadata for an XML file
 *
 * This function gets the metadata contained within a universal chat log format file
 * @param attributes The dictionary in which to store the metadata
 * @param pathToFile The path to the file to index
 *
 * @result true if successful, false if not
 */
Boolean GetMetadataForXMLLog(NSMutableDictionary *attributes, NSString *pathToFile)
{
	Boolean ret = YES;
	NSXMLDocument *xmlDoc = nil;
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:(NSString *)pathToFile];
	NSData *data = [NSData dataWithContentsOfURL:furl options:NSUncachedRead error:&err];
	if (data) {
		xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLNodePreserveCDATA error:&err];
	}

	if (xmlDoc)
	{   
		NSArray *senderNodes = [xmlDoc nodesForXPath:@"//message/@sender"
												error:&err];
		NSSet *duplicatesRemover = [NSSet setWithArray: senderNodes];
		// XPath returns an array of NSXMLNodes. Must convert them to strings containing just the attribute value.
		NSMutableArray *authorsArray = [NSMutableArray arrayWithCapacity:[duplicatesRemover count]];
		NSXMLNode *senderNode = nil;
		
		for( senderNode in duplicatesRemover ) {
			[authorsArray addObject:[senderNode objectValue]];
		}
		
		[(NSMutableDictionary *)attributes setObject:authorsArray
											  forKey:(NSString *)kMDItemAuthors];

		[(NSMutableDictionary *)attributes setObject:authorsArray
											  forKey:(NSString *)kMDItemInstantMessageAddresses];
		
		NSArray *contentArray = [xmlDoc nodesForXPath:@"//message//text()"
												error:&err];
		NSString *contentString = [contentArray componentsJoinedByString:@" "];
		
		[attributes setObject:contentString
					   forKey:(NSString *)kMDItemTextContent];

		NSString *serviceString = [[[xmlDoc rootElement] attributeForName:@"service"] objectValue];
		if(serviceString != nil)
			[attributes setObject:serviceString
						   forKey:@"com_adiumX_service"];
		
		NSArray			*children = [[xmlDoc rootElement] children];
		NSCalendarDate	*startDate = nil, *endDate = nil;

		if ([children count]) {
			NSString		*dateStr;

			dateStr = [[(NSXMLElement *)[children objectAtIndex:0] attributeForName:@"time"] objectValue];
			startDate = (dateStr ? [NSCalendarDate calendarDateWithString:dateStr] : nil);
			if (startDate)
				[(NSMutableDictionary *)attributes setObject:startDate
													  forKey:(NSString *)kMDItemContentCreationDate];

			dateStr = [[(NSXMLElement *)[children lastObject] attributeForName:@"time"] objectValue];
			endDate = (dateStr ? [NSCalendarDate calendarDateWithString:dateStr] : nil);
			if (endDate)
				[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:[endDate timeIntervalSinceDate:startDate]]
													  forKey:(NSString *)kMDItemDurationSeconds];
		}

		NSString *accountString = [[[xmlDoc rootElement] attributeForName:@"account"] objectValue];
		if (accountString) {
			[attributes setObject:accountString
						   forKey:@"com_adiumX_chatSource"];
			NSMutableArray *otherAuthors = [authorsArray mutableCopy];
			[otherAuthors removeObject:accountString];
			[attributes setObject:otherAuthors
						   forKey:@"com_adiumX_chatDestinations"];
			//pick the first author for this.  likely a bad idea
			if (startDate && [otherAuthors count]) {
				NSString *toUID = [otherAuthors objectAtIndex:0];
				[attributes setObject:[NSString stringWithFormat:@"%@ on %@",toUID,[startDate descriptionWithCalendarFormat:@"%Y-%m-%d"
																												   timeZone:nil
																													 locale:nil]]
							   forKey:(NSString *)kMDItemDisplayName];
			}
			[otherAuthors release];
			
		}
		[attributes setObject:@"Chat log"
					   forKey:(NSString *)kMDItemKind];
		[attributes setObject:@"Adium"
					   forKey:(NSString *)kMDItemCreator];
		
		[xmlDoc release];
	}
	else
		ret = NO;
	
	return ret;
}

NSString *killXMLTags(NSString *inString)
{
    NSScanner *scan = [NSScanner scannerWithString:inString];
    NSString *tempString = nil;
    NSMutableString *ret = [NSMutableString string];
    NSRange rng;
    
    while(![scan isAtEnd]){
        tempString = nil;
        [scan scanUpToString:@"<" intoString:&tempString];
        if(tempString != nil)
            [ret appendFormat:@"%@ ", tempString];
        [scan scanString:@"<" intoString:nil];
        [scan scanUpToString:@">" intoString:&tempString];
        if([tempString hasPrefix:@"br"])
            [ret appendString:@"\n"];
        [scan scanString:@">" intoString:nil];
    }
    rng.location = -1;
    do {
        NSRange searchRange = NSMakeRange(rng.location+1, [ret length]-rng.location-1);
        rng = [ret rangeOfString:@"&lt;" options:0 range:searchRange];
        if (rng.length > 0)
            [ret replaceCharactersInRange: rng withString: @"<"];
    } while (rng.length > 0);
    rng.location = -1;
    do {
        NSRange searchRange = NSMakeRange(rng.location+1, [ret length]-rng.location-1);
        rng = [ret rangeOfString:@"&gt;" options:0 range:searchRange];
        if (rng.length > 0)
            [ret replaceCharactersInRange: rng withString: @">"];
    } while (rng.length > 0);
    rng.location = -1;
    do {
        NSRange searchRange = NSMakeRange(rng.location+1, [ret length]-rng.location-1);
        rng = [ret rangeOfString:@"&amp;" options:0 range:searchRange];
        if (rng.length > 0)
            [ret replaceCharactersInRange: rng withString: @"&"];
    } while (rng.length > 0);
    return ret;
}

NSString *GetTextContentForXMLLog(NSString *pathToFile)
{
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:(NSString *)pathToFile];
	NSString *contentString = nil;
	NSXMLDocument *xmlDoc = nil;
	NSData *data = [NSData dataWithContentsOfURL:furl options:NSUncachedRead error:&err];
	if (data) {
		xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLNodePreserveCDATA error:&err];
	}
	
	if (xmlDoc) {
		NSArray *contentArray = [xmlDoc nodesForXPath:@"//message//text()"
												error:&err];
		contentString = [contentArray componentsJoinedByString:@" "];
		[xmlDoc release];
	}
	
	return contentString;
}
