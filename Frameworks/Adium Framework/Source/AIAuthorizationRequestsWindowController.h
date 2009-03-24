//
//  AIAuthorizationRequestsWindowController.h
//  Adium
//
//  Created by Zachary West on 2009-03-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIWindowController.h>

#define AUTHORIZATION_REQUESTS		AILocalizedString(@"Authorization Requests", nil)
#define GET_INFO					AILocalizedString(@"Get Info", nil)
#define AUTHORIZE					AILocalizedString(@"Authorize", nil)
#define AUTHORIZE_ADD				AILocalizedString(@"Authorize and Add", nil)
#define DENY						AILocalizedString(@"Deny", nil)
#define DENY_BLOCK					AILocalizedString(@"Deny and Block", nil)
#define IGNORE						AILocalizedString(@"Ignore", nil)
#define IGNORE_BLOCK				AILocalizedString(@"Ignore and Block", nil)

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
