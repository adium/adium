//
//  AMPurpleJabberServiceDiscoveryBrowserController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import <Adium/AIWindowController.h>
#include <libpurple/libpurple.h>

@class AIAccount, AMPurpleJabberNode;

@interface AMPurpleJabberServiceDiscoveryBrowserController : AIWindowController
{
	AIAccount *account;
    PurpleConnection *gc;
	
    IBOutlet NSTextField *servicename;
    IBOutlet NSTextField *nodename;
    IBOutlet NSOutlineView *outlineview;
    
	IBOutlet NSTextField *label_service;
	IBOutlet NSTextField *label_node;
	
	AMPurpleJabberNode *node;
}

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection *)_gc node:(AMPurpleJabberNode *)_node;

- (IBAction)changeServiceName:(id)sender;
- (IBAction)openService:(id)sender;

@end
