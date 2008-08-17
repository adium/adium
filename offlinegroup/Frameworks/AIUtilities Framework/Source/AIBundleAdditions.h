//
//  AIBundleAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface NSBundle (AIBundleAdditions)

- (NSString *)name;
- (NSSet *)supportedDocumentExtensions;

@end
