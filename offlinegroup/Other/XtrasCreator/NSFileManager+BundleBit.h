//
//  NSFileManager+BundleBit.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

@interface NSFileManager (BundleBit)

//both of these can work on a directory as well.
- (BOOL) bundleBitOfFile:(NSString *)path;
- (void) setBundleBitOfFile:(NSString *)path toBool:(BOOL)newValue;

@end
