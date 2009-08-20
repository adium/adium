//
//  AISystemNetworkDefaults.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Jun 25 2004.

#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "AISystemNetworkDefaults.h"
#import "AIKeychain.h"
#import "AIApplicationAdditions.h"
#import "AIStringUtilities.h"

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
			break;
		}
	}

	if ((proxyDict = (NSDictionary *)SCDynamicStoreCopyProxies(NULL))) {
		[proxyDict autorelease];

		//Enabled?
		enable = [[proxyDict objectForKey:(NSString *)enableKey] intValue];
		if (enable) {

			//Host
			hostString = [proxyDict objectForKey:(NSString *)proxyKey];
			if (hostString) {

				//Port
				portNum = [proxyDict objectForKey:(NSString *)portKey];
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
						NSLog(@"Could not get username and password for proxy: %@ returned %i (%@)",
							  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME],
							  [error code],
							  [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
					}
				}
			}

		} else {
			//Check for a PAC configuration
			enable = [[proxyDict objectForKey:(NSString *)kSCPropNetProxiesProxyAutoConfigEnable] boolValue];
			if (enable) {
				NSString *pacFile = [proxyDict objectForKey:(NSString *)kSCPropNetProxiesProxyAutoConfigURLString];
				
				if (pacFile) {
					CFURLRef url = (CFURLRef)[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", hostName ?: @"google.com"]];
					NSString *scriptStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:pacFile] encoding:NSUTF8StringEncoding error:NULL];
					
					if (url && scriptStr) {
						NSArray *proxies;
						// The following note is from Apple's CFProxySupportTool:
						// Work around <rdar://problem/5530166>.  This dummy call to 
						// CFNetworkCopyProxiesForURL initialise some state within CFNetwork 
						// that is required by CFNetworkCopyProxiesForAutoConfigurationScript.
						CFRelease(CFNetworkCopyProxiesForURL(url, NULL));
						
						CFErrorRef error = NULL;
						proxies = [(NSArray *)CFNetworkCopyProxiesForAutoConfigurationScript((CFStringRef)scriptStr, url, &error) autorelease];	

						if (error) {
							CFStringRef description = CFErrorCopyDescription(error);
							
							NSLog(@"Tried to get PAC, but got error: %@ %d %@",
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
