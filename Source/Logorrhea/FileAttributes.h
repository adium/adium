//
//  FileAttributes.h
//  Logtastic
//
//  Created by Ladd Van Tol on Sat Mar 29 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileAttributes : NSObject
{
}

+ (NSDate *) getCreationDateForPath:(NSString *) path;

@end
