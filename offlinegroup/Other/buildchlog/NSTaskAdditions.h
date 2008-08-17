//
//  NSTaskAdditions.h
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTask (DPExtensions)
+ (NSString *)fullPathToExecutable:(NSString *)execName;
+ (NSString *)fullPathToExecutable:(NSString *)execName additionalSearchPaths:(NSArray *)paths;
@end
