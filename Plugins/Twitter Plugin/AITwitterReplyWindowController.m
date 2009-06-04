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

#import "AITwitterReplyWindowController.h"
#import "AITwitterAccount.h"
#import "AIURLHandlerPlugin.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation AITwitterReplyWindowController

@synthesize account;

static AITwitterReplyWindowController *sharedController = nil;

/*!
 * @brief Create or set up a reply window.
 *
 * @param inAccount Either the AIAccount this is specified on, or nil.
 */
+ (void)showReplyWindowForAccount:(AIAccount *)inAccount
{
	if (!sharedController) {
		sharedController = [[self alloc] initWithWindowNibName:@"AITwitterReplyWindow"];
	}
	
	// Make sure the window has loaded
	[sharedController window];
	
	sharedController.account = inAccount;
	
	[sharedController showWindow:nil];
	[sharedController.window makeKeyAndOrderFront:nil];
}

- (void)windowDidLoad
{
	[label_statusID setLocalizedString:AILocalizedString(@"Status ID:", "In the 'reply to tweet' window, this is the field for the ID of the status (numerical).")];
	[label_usernameOrTweetURL setLocalizedString:AILocalizedString(@"Username or Tweet URL:", "Either the username or the URL of a tweet we want to reply to.")];
	
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
	[button_reply setLocalizedString:AILocalizedString(@"Reply", nil)];
	
	[self.window setTitle:AILocalizedString(@"Reply to a Tweet", "Name of the 'reply to a tweet' window.")];
	
	[super windowDidLoad];
}

- (void)dealloc
{
	[account release];

	[super dealloc];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedController autorelease]; sharedController = nil;
}

/*!
 * @brief Broadcast a "reply to this" message.
 */
- (IBAction)reply:(id)sender
{
	if (([textField_usernameOrTweetURL.stringValue rangeOfCharacterFromSet:[account.service.allowedCharacters invertedSet]].location != NSNotFound) ||
		(![[NSString stringWithFormat:@"%qu", [textField_statusID.stringValue unsignedLongLongValue]] isEqualToString:textField_statusID.stringValue])) {
		NSBeep();
	} else if (textField_usernameOrTweetURL.stringValue && textField_statusID.stringValue) {

		NSString *replyAddress = [(AITwitterAccount *)account addressForLinkType:AITwitterLinkReply
																		  userID:textField_usernameOrTweetURL.stringValue
																		statusID:textField_statusID.stringValue
																		 context:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:AIURLHandleNotification object:replyAddress];
		
		[self closeWindow:nil];
	}
}

/*!
 * @brief Cancel.
 */
- (IBAction)cancel:(id)sender
{	
	[self closeWindow:nil];
}

/*!
 * @brief Detect a twitter.com URL being pasted in.
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *textField = [notification object];
	
	if (textField == textField_usernameOrTweetURL) {
		NSString *value = [textField stringValue];
		NSRange	 twitterLocation = [value rangeOfString:@"twitter.com"];
		
		if (twitterLocation.location != NSNotFound) {			
			NSArray *components = [[value substringFromIndex:twitterLocation.location] pathComponents];

			if (components.count == 4 && ([[components objectAtIndex:2] isEqualToString:@"status"] ||
										  [[components objectAtIndex:2] isEqualToString:@"statuses"])) {
				textField_usernameOrTweetURL.stringValue = [components objectAtIndex:1];
				textField_statusID.stringValue = [components objectAtIndex:3];
			}
		}
	}
}



@end
