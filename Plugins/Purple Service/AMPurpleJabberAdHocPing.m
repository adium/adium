//
//  AMPurpleJabberAdHocPing.m
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import "AMPurpleJabberAdHocPing.h"

@implementation AMPurpleJabberAdHocPing

+ (void)adHocServer:(AMPurpleJabberAdHocServer*)server executeCommand:(AMPurpleJabberAdHocCommand*)command {
	[[command generateReplyWithNote:@"Pong" type:info status:completed] send];
}

@end
