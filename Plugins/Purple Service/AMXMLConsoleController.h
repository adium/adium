//
//  AMXMLConsoleController.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-06.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <AdiumLibpurple/PurpleCommon.h>

@interface AMXMLConsoleController : NSObject {
    IBOutlet NSWindow *xmlConsoleWindow;
    IBOutlet NSTextView *xmlLogView;
    IBOutlet NSTextView *xmlInjectView;
    
    PurpleConnection *gc;
}

- (IBAction)sendXML:(id)sender;
- (IBAction)clearLog:(id)sender;
- (IBAction)showWindow:(id)sender;
- (void)close;

- (void)setPurpleConnection:(PurpleConnection *)gc;
@end
