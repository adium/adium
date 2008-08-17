//
//  ESIRCJoinChatViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Adium/DCJoinChatViewController.h>

@interface ESIRCJoinChatViewController : DCJoinChatViewController {
	IBOutlet	NSTextField	*textField_channel;
	IBOutlet	NSTextField	*textField_password;
}

@end
