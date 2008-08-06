//
//  AMPurpleJabberAdHocCommand.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import "PurpleCommon.h"
#import "xmlnode.h"

enum AMPurpleJabberAdHocCommandStatus {
	executing,
	canceled,
	completed
};

enum AMPurpleJabberAdHocCommandNoteType {
	error,
	info,
	warn
};

@class AMPurpleJabberAdHocServer, AMPurpleJabberFormGenerator;

@interface AMPurpleJabberAdHocCommand : NSObject {
	AMPurpleJabberAdHocServer *server;
	NSString *jid;
	NSString *node;
	NSString *iqid;
	NSString *sessionid;
	
	xmlnode *command;
}

- (id)initWithServer:(AMPurpleJabberAdHocServer *)_server command:(xmlnode *)_command jid:(NSString *)_jid iqid:(NSString *)_iqid;

- (AMPurpleJabberFormGenerator *)form;
- (NSString *)jid;
- (NSString *)sessionid;

- (void)setSessionid:(NSString *)_sessionid; /* this can be used by the AMPurpleJabberAdHocServerDelegate for tracking the specific session */

/* actions is an NSArray of NSStrings, which can be any combination of @"execute", @"cancel", @"prev", @"next", @"complete" */
- (AMPurpleJabberAdHocCommand *)generateReplyWithForm:(AMPurpleJabberFormGenerator *)form actions:(NSArray *)actions defaultAction:(unsigned)defaultAction status:(enum AMPurpleJabberAdHocCommandStatus)status;
- (AMPurpleJabberAdHocCommand *)generateReplyWithNote:(NSString *)text type:(enum AMPurpleJabberAdHocCommandNoteType)type status:(enum AMPurpleJabberAdHocCommandStatus)status;

- (void)send;

@end
