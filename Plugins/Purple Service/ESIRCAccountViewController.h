//
//  ESIRCAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Adium/AIAccountViewController.h>
#import "PurpleAccountViewController.h"

@interface ESIRCAccountViewController : PurpleAccountViewController {
	IBOutlet	NSButton		*checkbox_useSSL;
	IBOutlet	NSPopUpButton	*popUp_encoding;
	
	IBOutlet	NSTextField	*textField_username;
	IBOutlet	NSTextField *textField_realname;
	
	IBOutlet	NSTextView	*textView_commands;
}

@end
