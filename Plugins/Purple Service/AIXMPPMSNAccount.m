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

#import "AIXMPPMSNAccount.h"

// Should probably be temporary, registered by me (Thijs)
#define ADIUM_MSN_OAUTH2_APP_ID @"0000000040068F8C"

@implementation AIXMPPMSNAccount

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSString *)oAuthURL
{
	return @"https://oauth.live.com/authorize?client_id=" ADIUM_MSN_OAUTH2_APP_ID
	@"&scope=wl.messenger"
	@"&response_type=token"
	@"&redirect_uri=http://oauth.live.com/desktop";
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
	return params;
}

- (NSString *)tokenFromURL:(NSURL *)url
{
	if ([[url host] isEqual:@"oauth.live.com"] && [[url path] isEqual:@"/desktop"]) {
		NSDictionary *urlParamDict = [self parseURLParams:[url fragment]];
		NSString *token = [urlParamDict objectForKey:@"access_token"];
		
		AILogWithSignature(@"Got token: %@", token);
		
		return token ?: @"";
	}
	
	return nil;
}

@end
