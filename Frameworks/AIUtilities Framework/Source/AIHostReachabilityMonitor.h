//
//  AIHostReachabilityMonitor.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-02-11.
//

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
