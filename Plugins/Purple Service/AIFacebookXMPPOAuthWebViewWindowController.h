//
//  AIFacebookXMPPOAuthWebViewWindowController.h
//  Adium
//
//  Created by Colin Barrett on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>
#import <WebKit/WebKit.h>

@interface AIFacebookXMPPOAuthWebViewWindowController : AIWindowController {
    IBOutlet WebView *webView;
	IBOutlet NSProgressIndicator *spinner;
    NSMutableSet *cookies;
}

@end
