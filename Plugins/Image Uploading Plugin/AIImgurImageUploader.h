//
//  AIImgurImageUploader.h
//  Adium
//

#import "AIGenericMultipartImageUploader.h"

@interface AIImgurImageUploader : AIGenericMultipartImageUploader {
	NSData						*resultData;
	NSXMLParser					*responseParser;
	
	// Parsing
	NSMutableDictionary			*lastElement;
	NSString					*currentElementName;
	NSMutableDictionary			*currentElement;
	NSMutableDictionary			*response;
}

@end
