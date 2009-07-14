//
//  AIGenericMultipartImageUploader.h
//  Adium
//
//  Created by Zachary West on 2009-07-01.
//  Copyright 2009  . All rights reserved.
//

#import "AIImageUploaderPlugin.h"
#import <AIUtilities/AIProgressDataUploader.h>

@interface AIGenericMultipartImageUploader : NSObject <AIImageUploader, AIProgressDataUploaderDelegate> {
	AIChat						*chat;
	NSImage						*image;
	AIImageUploaderPlugin		*uploader;
	
	AIProgressDataUploader		*dataUploader;
}

@property (readonly, nonatomic) NSUInteger maximumSize;
@property (readonly, nonatomic) NSString *uploadURL;
@property (readonly, nonatomic) NSString *fieldName;

- (void)parseResponse:(NSData *)data;

@end
