//
//  AIStringDebug.h
//  Adium
//
//  Created by David Smith on 5/24/2009
//  Copyright 2009 The Adium Team. All rights reserved.
//
#ifdef DEBUG_BUILD

@interface NSObject (AIObjectDebug) 
- (void) doesNotRecognizeSelector:(SEL)aSelector;
@end
#endif
