//
//  AIGuestAccountWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/9/06.
//

#import <Adium/AIWindowController.h>

@class AIAccount;

@interface AIGuestAccountWindowController : AIWindowController {
	IBOutlet	NSPopUpButton	*popUp_service;
	IBOutlet	NSTextField		*label_service;
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*label_name;
	
	IBOutlet	NSTextField		*textField_password;
	IBOutlet	NSTextField		*label_password;

	IBOutlet	NSButton		*button_okay;
	IBOutlet	NSButton		*button_cancel;
	IBOutlet	NSButton		*button_advanced;
	
	AIAccount	*account;
}

+ (void)showGuestAccountWindow;

- (IBAction)okay:(id)sender;
- (IBAction)displayAdvanced:(id)sender;

@end
