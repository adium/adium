//
//  ApplescriptDebugging.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef APPLESCRIPT_DEBUGGING_ENABLED
#define APPLESCRIPT_DEBUGGING_ENABLED FALSE
#endif

#if APPLESCRIPT_DEBUGGING_ENABLED

@interface NSScriptClassDescription (NSScriptClassDescriptionAIPrivate)
- (short)_readClass:(void *)someSortOfInput;
@end

@interface AIScriptClassDescription : NSScriptClassDescription {

}

@end

@interface AIScriptCommand : NSScriptCommand {
	
}

@end

@interface AIScriptCommandDescription : NSScriptCommandDescription {

}

@end

#endif
