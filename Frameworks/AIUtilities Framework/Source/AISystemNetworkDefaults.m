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
			if ([NSApp isOnTigerOrBetter]) {
				//Check for a PAC configuration
				enable = [[proxyDict objectForKey:(NSString *)kSCPropNetProxiesProxyAutoConfigEnable] boolValue];
				if (enable) {
					NSString *pacFile = [proxyDict objectForKey:(NSString *)kSCPropNetProxiesProxyAutoConfigURLString];
					
					if (pacFile) {
						//XXX can't use pac file
						NSString *msg = [NSString stringWithFormat:
							AILocalizedString(@"The systemwide proxy configuration specified via the Network System Preferences depends upon reading a PAC (Proxy Automatic Confiruation) file from %@.  This information can not be used at this time; to connect, please obtain proxy information from your network administrator and use it manually.", nil),
							pacFile];
						NSRunCriticalAlertPanel(AILocalizedString(@"Unable to read proxy information", "Title of the alert shown when the system proxy configuration can not be determined"),
												msg,
												nil,
												nil,
												nil);
					}
				}
			}		
		}
		// Could check and process kSCPropNetProxiesExceptionsList here, which returns: CFArray[CFString]

		//Clean up; proxyDict was created by a call with Copy in its name
		[proxyDict release];
	}


	return systemProxySettingsDictionary;
}

@end
