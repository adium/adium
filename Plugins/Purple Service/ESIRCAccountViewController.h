//
//  ESIRCAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Adium/AIAccountViewController.h>

@interface ESIRCAccountViewController : AIAccountViewController {
	IBOutlet	NSButton	*checkbox_useSSL;
	IBOutlet	NSTextField *textfield_Nick;
	
	IBOutlet	NSTextView	*textView_commands;
}

@end
