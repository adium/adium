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

#import <AdiumLibpurple/CBPurpleAccount.h>
#import <AdiumLibpurple/AIIRCConsoleController.h>

#define KEY_IRC_USE_SSL		@"IRC:Use SSL"
#define KEY_IRC_COMMANDS	@"IRC:Commands"
#define KEY_IRC_USERNAME	@"IRC:Username"
#define KEY_IRC_REALNAME	@"IRC:Realname"
#define KEY_IRC_ENCODING	@"IRC:Encoding"

typedef enum {
	AIUnspecifiedOperation = 0,
	AIRequiresNoLevel,
	AIRequiresOp,
	AIRequiresHalfop
} AIOperationRequirement;

@interface ESIRCAccount : CBPurpleAccount <AIAccount_Files> {
	AIIRCConsoleController *consoleController;
}

@property (weak, readonly, nonatomic) NSString *defaultUsername;
@property (weak, readonly, nonatomic) NSString *defaultRealname;

- (void)identifyForName:(NSString *)name password:(NSString *)inPassword;
- (AIGroupChatFlags)flagsInChat:(AIChat *)chat;

@end
