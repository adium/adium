//
//  AIPicImImageUploader.h
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIGenericMultipartImageUploader.h"

@interface AIPicImImageUploader : AIGenericMultipartImageUploader {
	NSData						*resultData;
	NSXMLParser					*responseParser;
	
	// Parsing
	NSMutableDictionary			*lastElement;
	NSString					*currentElementName;
	NSMutableDictionary			*currentElement;
	NSMutableDictionary			*response;
}

@end
