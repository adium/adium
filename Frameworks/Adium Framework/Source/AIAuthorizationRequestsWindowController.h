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
#define AUTHORIZE					AILocalizedStringFromTable(@"Authorize", @"Buttons", nil)
#define AUTHORIZE_ADD				AILocalizedStringFromTable(@"Authorize and Add", @"Buttons", nil)
#define DENY						AILocalizedStringFromTable(@"Deny", @"Buttons", nil)

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
