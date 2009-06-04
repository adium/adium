/*
 * @file AISystemNetworkDefaults.h
 */

//
//  AISystemNetworkDefaults.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Jun 25 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*
 * Proxy types for <tt>AISystemNetworkDefaults</tt>
 */
typedef enum
{
	Proxy_None		= 0, /**< No proxy */
	Proxy_HTTP		= 1, /**< HTTP proxy */
	Proxy_HTTPS		= 2, /**< HTTPS proxy */
	Proxy_SOCKS4	= 3, /**< SOCKS4 proxy */
	Proxy_SOCKS5	= 4, /**< SOCKS5 proxy */
	Proxy_FTP		= 5, /**< FTP proxy */
	Proxy_RTSP		= 6  /**< RTSP proxy */
} ProxyType;

/*!
 * @class AISystemNetworkDefaults
 * @brief Class to provide easy access to the systemwide network proxy settings of each type
*/
@interface AISystemNetworkDefaults : NSObject {

}

/*!
 * @brief Retrieve systemwide proxy settings for a type of proxy
 *
 * Retrieve systemwide proxy settings for <b>proxyType</b> using optional hostname <b>hostName</b> (for PAC files).
 * @param proxyType The type of proxy for which to retrieve settings.  ProxyType should be one of Proxy_None, Proxy_HTTP, Proxy_HTTPS, Proxy_SOCKS4, Proxy_SOCKS5, Proxy_FTP, Proxy_RTSP, or Proxy_Gopher.
 * @param hostName An NSString of the hostname to connect to, or nil
 * @result An <tt>NSDictionary</tt> containing the settings for that proxy type, or nil if no proxy is configured for that type.  The dictionary has the host as an NSString in the key @"Host", the port as an NSNumber in the key @"Port", and, if they are present, the username and password as NSStrings in @"Username" and @"Password" respectively.
*/
+ (NSDictionary *)systemProxySettingsDictionaryForType:(ProxyType)proxyType
											 forServer:(NSString *)hostName;

@end
