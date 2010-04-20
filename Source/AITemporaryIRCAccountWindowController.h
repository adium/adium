//
//  AITemporaryIRCAccountWindowController.h
//  Adium
//
//  Created by Thijs Alkemade on 15-04-10.
//

#import <Adium/AIWindowController.h>
#import <Adium/AIStatus.h>

@class AIAccount;

@interface AITemporaryIRCAccountWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_explanation;
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*label_name;
	
	IBOutlet	NSTextField		*textField_server;
	IBOutlet	NSTextField		*label_server;
	
	IBOutlet	NSButton		*button_okay;
	IBOutlet	NSButton		*button_cancel;
	IBOutlet	NSButton		*button_advanced;
	
	IBOutlet	NSButton		*button_remember;
	
	AIAccount	*account;
	
	NSString	*channel;
	NSString	*server;
	NSInteger	port;
	NSString	*password;
	
}

- (id)initWithChannel:(NSString *)newChannel server:(NSString *)newServer port:(NSInteger)newPort andPassword:(NSString *)newPassword;

- (IBAction)okay:(id)sender;
- (IBAction)displayAdvanced:(id)sender;

- (void)accountConnected:(NSNotification *)not;

@end
