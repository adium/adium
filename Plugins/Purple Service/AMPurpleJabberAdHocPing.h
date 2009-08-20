//
//  AMPurpleJabberAdHocPing.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import "AMPurpleJabberAdHocCommand.h"

@class AMPurpleJabberAdHocServer;

@interface AMPurpleJabberAdHocPing : NSObject {
}

+ (void)adHocServer:(AMPurpleJabberAdHocServer *)server executeCommand:(AMPurpleJabberAdHocCommand *)command;

@end
