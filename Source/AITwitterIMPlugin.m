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

#import "AITwitterIMPlugin.h"
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>

@implementation AITwitterIMPlugin

- (void)installPlugin
{
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)dealloc
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet *returnSet = nil;
	
	if (!inModifiedKeys) {
		if (([inObject.UID isEqualToString:@"twitter@twitter.com"] &&
			 [inObject.service.serviceClass isEqualToString:@"Jabber"]) ||
			([inObject.service.serviceClass isEqualToString:@"Twitter"] || 
			 [inObject.service.serviceClass isEqualToString:@"Laconica"])) {
			
			if (![inObject valueForProperty:@"Character Counter Max"]) {
				[inObject setValue:[NSNumber numberWithInteger:140] forProperty:@"Character Counter Max" notify:YES];
				returnSet = [NSSet setWithObjects:@"Character Counter Max", nil];
			}
		}
	}
	
	return returnSet;
}

@end
