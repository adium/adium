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
