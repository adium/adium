//
//  AIChatCommandsController.h
//  Adium
//
//  Created by Chloe Haney on 11/07/07.
//

#import "AIWindowController.h"

@class AIChat, AIAccount, AIMetaContact, AICompletingTextField;

@interface AIChatCommandsController : AIWindowController 
{
	IBOutlet				id								sheet;
	IBOutlet				id								label_target;
	IBOutlet				id								label_comment;
	IBOutlet				AICompletingTextField			*textField_target;
	IBOutlet				NSTextField						*textField_comment;
	id								delegate;
	NSMutableDictionary				*parameters;
	NSMutableString					*nibToLoad;
	AIChatCommandsController *newChatCommandsController;
}

+ (void)showCommand:(NSString *)command forChat:(AIChat *)chat;

-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end

@interface NSObject (AIChatCommandsControllerDelegate)
- (void)executeCommandWithParameters:(NSDictionary *)paramters;
@end

