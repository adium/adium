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

#import "ESGaimYahooJapanAccount.h"

@implementation ESGaimYahooJapanAccount

- (void)configureGaimAccount
{
	[super configureGaimAccount];
	
	NSString	*hostName;
	
	//Host (server) - Yahoo! Japan uses a different server preference key than other accounts, so set that here
	hostName = [self host];
	if (hostName && [hostName length]) {
		gaim_account_set_string(account, "serverjp", [hostName UTF8String]);
	}

	gaim_account_set_bool(account, "yahoojp", TRUE);
}

@end
