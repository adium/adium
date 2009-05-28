//
//  AIPicImImageUploader.h
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIImageUploaderPlugin.h"

#import <AIUtilities/AIProgressDataUploader.h>

@interface AIPicImImageUploader : NSObject <AIImageUploader, AIProgressDataUploaderDelegate> {
	AIChat						*chat;
	NSImage						*image;
	AIImageUploaderPlugin		*uploader;
	
	AIProgressDataUploader		*dataUploader;
	
	NSXMLParser					*responseParser;
	
	// Parsing
	NSMutableDictionary			*lastElement;
	NSString					*currentElementName;
	NSMutableDictionary			*currentElement;
	NSMutableDictionary			*response;
}

@end
