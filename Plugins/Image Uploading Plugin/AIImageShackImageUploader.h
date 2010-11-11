//
//  AIImageShackImageUploader.h
//  Adium
//
//  Created by Zachary West on 2009-07-01.
//  Copyright 2009  . All rights reserved.
//

#import "AIGenericMultipartImageUploader.h"
#import <AIUtilities/AILeopardCompatibility.h>

@interface AIImageShackImageUploader : AIGenericMultipartImageUploader <NSXMLParserDelegate> {
	NSData						*resultData;
	NSXMLParser					*responseParser;
	
	// Parsing
	NSMutableDictionary			*lastElement;
	NSString					*currentElementName;
	NSMutableDictionary			*currentElement;

	NSMutableDictionary			*links;
}

@end
