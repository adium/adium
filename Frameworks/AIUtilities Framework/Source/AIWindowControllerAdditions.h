//
//  AIWindowControllerAdditions.h
//  AIUtilities.framework
//
//  Created by David Smith on 9/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindowController (AIWindowControllerAdditions) 

- (BOOL) canCustomizeToolbar;
- (BOOL) shouldResignKeyWindowWithoutUserInput;

@end
