//
//  SmackXMPPServiceDiscoveryBrowsing.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "AMPurpleJabberServiceDiscoveryBrowsing.h"
#import "AMPurpleJabberNode.h"
#import "AMPurpleJabberServiceDiscoveryBrowserController.h"

#import <Adium/AIAccount.h>
#import <libpurple/jabber.h>

#import "AIAdium.h"

@implementation AMPurpleJabberServiceDiscoveryBrowsing

- (id)initWithAccount:(AIAccount *)_account purpleConnection:(PurpleConnection *)_gc;
{
    if ((self = [super init]))
    {
        gc = _gc;
		account = _account;
		browsers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[browsers makeObjectsPerformSelector:@selector(close)];
	[browsers release];
	[rootnode release];
	[super dealloc];
}

- (IBAction)browse:(id)sender
{
	if (!rootnode) {
		JabberStream *js = gc->proto_data;
		JabberID *user = js->user;
		
		rootnode = [[AMPurpleJabberNode alloc] initWithJID:(user->domain ? [NSString stringWithUTF8String:user->domain] : nil)
													  node:nil
													  name:(user->domain ? [NSString stringWithUTF8String:user->domain] : nil)
												connection:gc];
	}

	AMPurpleJabberServiceDiscoveryBrowserController *browser = [[AMPurpleJabberServiceDiscoveryBrowserController alloc] initWithAccount:account
																													   purpleConnection:gc
																																   node:rootnode];
	[browsers addObject:browser];
	[browser release];
}

@end
