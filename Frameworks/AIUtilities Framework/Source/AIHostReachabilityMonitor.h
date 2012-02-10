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

@class AIHostReachabilityMonitor;

@protocol AIHostReachabilityObserver <NSObject>

- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host;
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host;

@end

@interface AIHostReachabilityMonitor: NSObject
{
	NSMutableArray		*hosts;
	NSMutableArray		*observers;
	NSMutableArray		*reachabilities;
	
	NSMutableSet		*unconfiguredHostsAndObservers;
	
	NSLock				*hostAndObserverListLock;
	
	CFRunLoopSourceRef	ipChangesRunLoopSourceRef;
}


+ (id)defaultMonitor;

#pragma mark -

- (void)addObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host;
- (void)removeObserver:(id <AIHostReachabilityObserver>)observer forHost:(NSString *)host;
- (BOOL)observer:(id)observer isObservingHost:(NSString *)host;

@end
