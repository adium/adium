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

#import "AIOAuth2XMPPAccount.h"

@implementation AIOAuth2XMPPAccount

@synthesize oAuthWC, oAuthToken;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)requestAuthorization
{
	self.oAuthWC = [[[AIFacebookXMPPOAuthWebViewWindowController alloc] init] autorelease];
	self.oAuthWC.account = self;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressPromptingUser]
								 forKey:KEY_OAUTH2_STEP]];
	
//	if (![[self class] uidIsValidForFacebook:self.UID]) {
		/* We have a UID which isn't a Facebook numeric username. That can come from:
		 *	 1. The setup wizard
		 *   2. Facebook-HTTP account from Adium <= 1.4.2
		 */
//		self.oAuthWC.autoFillUsername = self.UID;
//		self.oAuthWC.autoFillPassword = [adium.accountController passwordForAccount:self];
//		self.oAuthWC.isMigrating = ![self.service.serviceID isEqualToString:FACEBOOK_XMPP_SERVICE_ID];
		
//		self.migrationData = [NSDictionary dictionaryWithObjectsAndKeys:
//							  self.UID, @"originalUID",
//							  self.service.serviceID, @"originalServiceID",
//							  nil];
//	}
	
	[self.oAuthWC showWindow:self];
}

- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token
{
    [self setOAuthToken:token];
    
    NSString *urlstring = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", [self oAuthToken]];
    NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
//    self.networkState = AIMeGraphAPINetworkState;
//    self.connectionData = [NSMutableData data];
//    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressContactingServer]
								 forKey:KEY_OAUTH2_STEP]];
}

- (void)oAuthWebViewControllerDidFail:(AIFacebookXMPPOAuthWebViewWindowController *)wc
{
	[self setOAuthToken:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AIOAuth2ProgressNotification
														object:self
													  userInfo:
	 [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:AIOAuth2ProgressFailure]
								 forKey:KEY_OAUTH2_STEP]];
	
}

@end
