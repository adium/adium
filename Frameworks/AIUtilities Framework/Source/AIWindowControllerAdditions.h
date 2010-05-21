//
//  AIWindowControllerAdditions.h
//  AIUtilities.framework
//
//  Created by David Smith on 9/16/06.
//  Copyright 2006-2009 The Adium Team. All rights reserved.
//

@interface NSWindowController (AIWindowControllerAdditions) 

- (BOOL) canCustomizeToolbar;
- (BOOL) shouldResignKeyWindowWithoutUserInput;

@end
