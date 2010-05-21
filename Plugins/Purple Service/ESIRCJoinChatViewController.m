//
//  ESIRCJoinChatViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

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
