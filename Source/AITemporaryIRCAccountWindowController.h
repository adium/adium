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

#import <Adium/AIWindowController.h>
#import <Adium/AIStatus.h>

@class AIAccount;

@interface AITemporaryIRCAccountWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_explanation;
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*label_name;
	
	IBOutlet	NSTextField		*textField_server;
	IBOutlet	NSTextField		*label_server;
	
	IBOutlet	NSButton		*button_okay;
	IBOutlet	NSButton		*button_cancel;
	IBOutlet	NSButton		*button_advanced;
	
	IBOutlet	NSButton		*button_remember;
	
	AIAccount	*account;
	
	NSString	*channel;
	NSString	*server;
	NSInteger	port;
	NSString	*password;
	
}

- (id)initWithChannel:(NSString *)newChannel server:(NSString *)newServer port:(NSInteger)newPort andPassword:(NSString *)newPassword;
- (void)show __attribute__((ns_consumes_self));
- (IBAction)okay:(id)sender;
- (IBAction)displayAdvanced:(id)sender;

- (void)accountConnected:(NSNotification *)not;

@end
