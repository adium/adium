//
//  AIAuthorizationRequestsWindowController.h
//  Adium
//
//  Created by Zachary West on 2009-03-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>

@class AIAccount;

@interface AIAuthorizationRequestsWindowController : AIWindowController {
	IBOutlet		NSTableView		*tableView;
	
	NSMutableArray					*requests;
	
	NSMutableDictionary				*toolbarItems;
	NSMutableDictionary				*requiredHeightDict;
}

+ (AIAuthorizationRequestsWindowController *)sharedController;

- (void)addRequestWithDict:(NSDictionary *)dict;
- (void)removeRequest:(id)request;

@end
