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

#import "AMPurpleJabberServiceDiscoveryBrowsing.h"
#import "AMPurpleJabberNode.h"
#import "AMPurpleJabberServiceDiscoveryBrowserController.h"

#import <Adium/AIAccount.h>
#import <libpurple/jabber.h>

#import "AIAdium.h"

@implementation AMPurpleJabberServiceDiscoveryBrowsing

- (id)initWithAccount:(AIAccount *)_account purpleConnection:(PurpleConnection *)_gc;
{
    if ((self = [super init]))
    {
        gc = _gc;
		account = _account;
		browsers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[browsers makeObjectsPerformSelector:@selector(close)];
}

- (IBAction)browse:(id)sender
{
	if (!rootnode) {
		JabberStream *js = gc->proto_data;
		JabberID *user = js->user;
		
		rootnode = [[AMPurpleJabberNode alloc] initWithJID:(user->domain ? [NSString stringWithUTF8String:user->domain] : nil)
													  node:nil
													  name:(user->domain ? [NSString stringWithUTF8String:user->domain] : nil)
												connection:gc];
	}

	AMPurpleJabberServiceDiscoveryBrowserController *browser = [[AMPurpleJabberServiceDiscoveryBrowserController alloc] initWithAccount:account
																													   purpleConnection:gc
																																   node:rootnode];
	[browsers addObject:browser];
}

@end
