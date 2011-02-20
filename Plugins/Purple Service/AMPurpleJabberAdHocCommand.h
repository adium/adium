/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
- (AMPurpleJabberAdHocCommand *)generateReplyWithForm:(AMPurpleJabberFormGenerator *)form actions:(NSArray *)actions defaultAction:(NSUInteger)defaultAction status:(enum AMPurpleJabberAdHocCommandStatus)status;
- (AMPurpleJabberAdHocCommand *)generateReplyWithNote:(NSString *)text type:(enum AMPurpleJabberAdHocCommandNoteType)type status:(enum AMPurpleJabberAdHocCommandStatus)status;

- (void)send;

@end
