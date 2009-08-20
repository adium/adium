//
//  LinkDriverWindowController.h
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 5/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AutoHyperlinks/AutoHyperlinks.h>


@interface LinkDriverWindowController : NSWindowController {
	IBOutlet NSTextView	*linkifyView;
	IBOutlet NSButton	*linkifyButton;
	IBOutlet NSTextView	*otherView;
}

-(IBAction) linkifyTextView:(id)sender;
@end
