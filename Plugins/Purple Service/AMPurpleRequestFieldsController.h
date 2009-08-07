//
//  AMPurpleRequestFieldsController.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-10.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "ESPurpleRequestAbstractWindowController.h"
#import <AdiumLibpurple/PurpleCommon.h>
#import <WebKit/WebKit.h>

@class CBPurpleAccount;

@interface AMPurpleRequestFieldsController : ESPurpleRequestAbstractWindowController {
    GCallback			okcb;
    GCallback			cancelcb;
    void				*userData;
    PurpleRequestFields *fields;
    NSMutableDictionary *fieldobjects;
    BOOL				wasSubmitted;
    
    IBOutlet WebView	*webview;
}

- (id)initWithTitle:(NSString *)title
        primaryText:(NSString *)primary
      secondaryText:(NSString *)secondary
      requestFields:(PurpleRequestFields *)_fields
             okText:(NSString *)okText
           callback:(GCallback)_okcb
         cancelText:(NSString *)cancelText
           callback:(GCallback)_cancelcb
            account:(CBPurpleAccount *)account
                who:(NSString *)who
       conversation:(PurpleConversation *)conv
           userData:(void *)_userData;

@end
