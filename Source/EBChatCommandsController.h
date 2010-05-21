//
//  EBChatCommandsController.h
//  Adium
//
//  Created by Chloe Haney on 11/07/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIAccount.h>
#import "AIChat.h"
#import "AIWindowController.h"
#import "AIUtilities/AICompletingTextfield.h"
#import "AIMetaContact.h"
@interface EBChatCommandsController : AIWindowController 
{
	IBOutlet				id								sheet;
	IBOutlet				id								label_target;
	IBOutlet				id								label_comment;
	IBOutlet				AICompletingTextField			*textField_target;
	IBOutlet				NSTextField						*textField_comment;
							id								delegate;
							NSMutableDictionary				*parameters;
}
+(id)init;
-(void)verifyCommand:(NSString*)command forChat:(AIChat*)chat;
-(id)delegate;
-(void)setDelegate:(id)newDelegate;
- (AIListContact *)contactFromTextField;
- (void)configureTextFieldForAccount:(AIAccount *)account;


@end
