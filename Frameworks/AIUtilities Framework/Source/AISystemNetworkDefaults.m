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

#import <SystemConfiguration/SystemConfiguration.h>
#import "AISystemNetworkDefaults.h"
#import "AIKeychain.h"

@implementation AISystemNetworkDefaults

+ (NSDictionary *)systemProxySettingsDictionaryForType:(ProxyType)proxyType
											 forServer:(NSString *)hostName
{
	NSMutableDictionary *systemProxySettingsDictionary = nil;
	NSDictionary		*proxyDict = nil;

	CFStringRef			enableKey;
	int                 enable;

	CFStringRef			portKey;
	NSNumber			*portNum = nil;

	CFStringRef			proxyKey;
	NSString			*hostString;

	SecProtocolType		protocolType;

	switch (proxyType) {
		case Proxy_HTTP: {
			enableKey = kSCPropNetProxiesHTTPEnable;
			portKey   = kSCPropNetProxiesHTTPPort;
			proxyKey  = kSCPropNetProxiesHTTPProxy;
			protocolType = kSecProtocolTypeHTTPProxy;
			break;
		}
		case Proxy_SOCKS4:
		case Proxy_SOCKS5: {
			enableKey = kSCPropNetProxiesSOCKSEnable;
			portKey   = kSCPropNetProxiesSOCKSPort;
			proxyKey  = kSCPropNetProxiesSOCKSProxy;
			protocolType = kSecProtocolTypeSOCKS;
			break;
		}
		case Proxy_HTTPS: {
			enableKey = kSCPropNetProxiesHTTPSEnable;
			portKey   = kSCPropNetProxiesHTTPSPort;
			proxyKey  = kSCPropNetProxiesHTTPSProxy;
			protocolType = kSecProtocolTypeHTTPSProxy;
			break;
		}
		case Proxy_FTP: {
			enableKey = kSCPropNetProxiesFTPEnable;
			portKey   = kSCPropNetProxiesFTPPort;
			proxyKey  = kSCPropNetProxiesFTPProxy;
			protocolType = kSecProtocolTypeFTPProxy;
			break;
		}
		case Proxy_RTSP: {
			enableKey = kSCPropNetProxiesRTSPEnable;
			portKey   = kSCPropNetProxiesRTSPPort;
			proxyKey  = kSCPropNetProxiesRTSPProxy;
			protocolType = kSecProtocolTypeRTSPProxy;
			break;
		}
		default: {
			return nil;
		}
	}

	if ((proxyDict = (__bridge_transfer NSDictionary *)SCDynamicStoreCopyProxies(NULL))) {

		//Enabled?
		enable = [[proxyDict objectForKey:(__bridge NSString *)enableKey] intValue];
		if (enable) {

			//Host
			hostString = [proxyDict objectForKey:(__bridge NSString *)proxyKey];
			if (hostString) {

				//Port
				portNum = [proxyDict objectForKey:(__bridge NSString *)portKey];
				if (portNum) {
					NSDictionary	*authDict;

					systemProxySettingsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						hostString, @"Host",
						portNum,    @"Port",
						nil];

					//User name & password if applicable
					NSError *error = nil;
					authDict = [[AIKeychain defaultKeychain_error:&error] dictionaryFromKeychainForServer:hostString 
																								 protocol:protocolType
																									error:&error];
					if (authDict) {
						[systemProxySettingsDictionary addEntriesFromDictionary:authDict];
					}

					if (error) {
						NSDictionary *userInfo = [error userInfo];
						NSLog(@"Could not get username and password for proxy: %@ returned %ld (%@)",
							  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
							  (long)[error code],
							  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
					}
				}
			}

		} else {
			//Check for a PAC configuration
			enable = [[proxyDict objectForKey:kSCPropNetProxiesProxyAutoConfigEnable] boolValue];
			if (enable) {
				NSString *pacFile = [proxyDict objectForKey:kSCPropNetProxiesProxyAutoConfigURLString];
				
				if (pacFile) {
					CFURLRef url = (__bridge CFURLRef)[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", hostName ?: @"google.com"]];
					NSString *scriptStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:pacFile] encoding:NSUTF8StringEncoding error:NULL];
					
					if (url && scriptStr) {
						NSArray *proxies;
						// The following note is from Apple's CFProxySupportTool:
						// Work around <rdar://problem/5530166>.  This dummy call to 
						// CFNetworkCopyProxiesForURL initialise some state within CFNetwork 
						// that is required by CFNetworkCopyProxiesForAutoConfigurationScript.
						CFRelease(CFNetworkCopyProxiesForURL(url, NULL));
						
						CFErrorRef error = NULL;
						proxies = (__bridge_transfer NSArray *)CFNetworkCopyProxiesForAutoConfigurationScript((__bridge CFStringRef)scriptStr, url, &error);	

						if (error) {
							CFStringRef description = CFErrorCopyDescription(error);
							
							NSLog(@"Tried to get PAC, but got error: %@ %ld %@",
								  CFErrorGetDomain(error),
								  CFErrorGetCode(error),
								  description);
							
							CFRelease(description);
							CFRelease(error);
						} else if (proxies && proxies.count) {
							proxyDict = [proxies objectAtIndex:0];
							
							systemProxySettingsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
															 [proxyDict objectForKey:(NSString *)kCFProxyHostNameKey], @"Host",
															 [proxyDict objectForKey:(NSString *)kCFProxyPortNumberKey], @"Port",
															 [proxyDict objectForKey:(NSString *)kCFProxyUsernameKey], @"Username",
															 [proxyDict objectForKey:(NSString *)kCFProxyPasswordKey], @"Password",
															 nil];
						}
					}
				}
			}
		}
		// Could check and process kSCPropNetProxiesExceptionsList here, which returns: CFArray[CFString]
	}


	return systemProxySettingsDictionary;
}

@end
