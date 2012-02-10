/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
