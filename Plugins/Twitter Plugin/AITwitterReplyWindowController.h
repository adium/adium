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
#import <Adium/AIAccount.h>

@interface AITwitterReplyWindowController : AIWindowController {
	IBOutlet NSTextField			*label_usernameOrTweetURL;
	IBOutlet NSTextField			*textField_usernameOrTweetURL;
	
	IBOutlet NSTextField			*label_statusID;
	IBOutlet NSTextField			*textField_statusID;
	
	IBOutlet NSButton				*button_reply;
	IBOutlet NSButton				*button_cancel;
	
	AIAccount	*__weak account;
}

+ (void)showReplyWindowForAccount:(AIAccount *)inAccount;

- (IBAction)reply:(id)sender;
- (IBAction)cancel:(id)sender;

@property (weak, nonatomic) AIAccount *account;

@end
