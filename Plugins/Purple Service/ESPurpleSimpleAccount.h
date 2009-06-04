//
//  ESPurpleSimpleAccount.h
//  Adium
//
//  Created by Evan Schoenberg on 12/17/05.

#import "CBPurpleAccount.h"

#define KEY_SIMPLE_PUBLISH_STATUS	@"Simple:Publish Status"
#define KEY_SIMPLE_USE_UDP			@"Simple:Use UDP"

#define KEY_SIMPLE_USE_SIP_PROXY	@"Simple:Use SIP Proxy"
#define KEY_SIMPLE_SIP_PROXY		@"Simple:SIP Proxy"
#define KEY_SIMPLE_AUTH_USER		@"Simple:Auth User"
#define KEY_SIMPLE_AUTH_DOMAIN		@"Simple:Auth Domain"

@interface ESPurpleSimpleAccount : CBPurpleAccount {

}

@end
