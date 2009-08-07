//
//  ESEditStatusGroupWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 11/25/05.

#import <Adium/AIWindowController.h>

@class AIStatusGroup;

@interface ESEditStatusGroupWindowController : AIWindowController {
	IBOutlet	NSTextField			*label_title;
	IBOutlet	NSTextField			*textField_title;

	IBOutlet	NSTextField			*label_groupWith;
	IBOutlet	NSPopUpButton		*popUp_groupWith;
	
	IBOutlet	NSButton			*button_OK;
	IBOutlet	NSButton			*button_cancel;
	
	AIStatusGroup					*statusGroup;
	id								target;
}

+ (void)editStatusGroup:(AIStatusGroup *)inStatusGroup onWindow:(id)parentWindow notifyingTarget:(id)inTarget;

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;

@end
