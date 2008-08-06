//
//  ESPresetNameSheetController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/15/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

typedef enum {
	ESPresetNameSheetOkayReturn			= 1,
    ESPresetNameSheetCancelReturn		= 0
} ESPresetNameSheetReturnCode;

@interface ESPresetNameSheetController : AIWindowController {
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*label_name;
	IBOutlet	NSButton		*button_ok;
	IBOutlet	NSButton		*button_cancel;	

	IBOutlet	NSTextView		*textView_explanatoryText;
	IBOutlet	NSScrollView	*scrollView_explanatoryText;

	NSString	*defaultName;
	NSString	*explanatoryText;
	id			target;
	id			userInfo;
}

+ (void)showPresetNameSheetWithDefaultName:(NSString *)inDefaultName
						   explanatoryText:(NSString *)inExplanatoryText
								  onWindow:(NSWindow *)parentWindow
						   notifyingTarget:(id)inTarget
								  userInfo:(id)inUserInfo;
- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface NSObject (ESPresetNameSheetControllerTarget)
//Required
- (void)presetNameSheetControllerDidEnd:(ESPresetNameSheetController *)controller 
							 returnCode:(ESPresetNameSheetReturnCode)returnCode
								newName:(NSString *)newName
							   userInfo:(id)userInfo;

//Optional
- (BOOL)presetNameSheetController:(ESPresetNameSheetController *)controller
			  shouldAcceptNewName:(NSString *)newName
						 userInfo:(id)userInfo;

@end
