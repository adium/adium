//
//  AIMediaController.h
//  Adium
//
//  Created by Zachary West on 2009-12-10.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIMediaControllerProtocol.h>

@interface AIMediaController : NSObject <AIMediaController> {
	NSMutableArray *openMedias;
	NSMutableArray *openMediaControllers;
}

@end
