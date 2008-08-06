//
//  ESFileWrapperExtension.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 10 2004.
//  Copyright (c) 2004-2006 The Adium Team. All rights reserved.
//

@interface ESFileWrapperExtension : NSFileWrapper {
	NSString	*originalPath;
}

- (NSString *)originalPath;

@end
