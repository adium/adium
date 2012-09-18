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

#import "ESIRCJoinChatViewController.h"

@interface ESIRCJoinChatViewController ()
- (void)validateEnteredText;
@end

@interface NSObject (JointChatViewDelegate)
- (void)setJoinChatEnabled:(BOOL)enabled;
@end

@implementation ESIRCJoinChatViewController
- (NSString *)nibName
{
	return @"ESIRCJoinChatView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[[view window] makeFirstResponder:textField_channel];
	[self validateEnteredText];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString			*channel;
	NSMutableDictionary	*chatCreationInfo;
	
	//Obtain room and exchange from the view
	channel = [textField_channel stringValue];
	
	if (channel && [channel length]) {
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSMutableDictionary dictionaryWithObject:channel
															  forKey:@"channel"];
		
		NSString *password = [textField_password stringValue];
		if (password && [password length]) {
			[chatCreationInfo setObject:password
								 forKey:@"password"];
		}

		[self doJoinChatWithName:channel
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:nil
		   withInvitationMessage:nil];
		
	} else {
		NSLog(@"Error: No channel specified.");
	}
	
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == textField_channel) {
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	if (delegate && [delegate respondsToSelector:@selector(setJoinChatEnabled:)]) {
		NSString	*channel = [textField_channel stringValue];

		[delegate setJoinChatEnabled:(channel && [channel length])];
	}
}

@end
