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

#import "AIHostReachabilityMonitor.h"
#import "AISleepNotification.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <netinet/in.h>

#define CONNECTIVITY_DEBUG FALSE

@interface AIHostReachabilityMonitor ()
- (void)scheduleReachabilityMonitoringForHost:(NSString *)nodename observer:(id)observer;
- (void)gotReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef forHost:(NSString *)host observer:(id)observer;

- (void)addUnconfiguredHost:(NSString *)host observer:(id)observer;
- (void)removeUnconfiguredHost:(NSString *)host observer:(id)observer;
- (void)queryUnconfiguredHosts;

- (void)beginMonitorngIPChanges;
- (void)stopMonitoringIPChanges;

- (void)systemDidWake:(NSNotification *)notification;
@end

@implementation AIHostReachabilityMonitor

#pragma mark Shared instance management

/*!
 *	@brief	Returns a shared instance, usable for most purposes.
 *	@return A shared AIHostReachabilityMonitor instance.
 */
+ (id)defaultMonitor
{
    static AIHostReachabilityMonitor *sharedMonitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMonitor = [[AIHostReachabilityMonitor alloc] init];
    });

	return sharedMonitor;
}

#pragma mark -
#pragma mark Birth and death

/*
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		hostAndObserverListLock = [[NSLock alloc] init];
		[hostAndObserverListLock setName:@"HostAndObserverListLock"];

		hosts          = [[NSMutableArray alloc] init];
		observers      = [[NSMutableArray alloc] init];
		reachabilities = [[NSMutableArray alloc] init];
		
		unconfiguredHostsAndObservers = [[NSMutableSet alloc] init];
		ipChangesRunLoopSourceRef = nil;
		
		//Monitor system sleep so we can accurately report connectivity changes when the system wakes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(systemDidWake:)
													 name:AISystemDidWake_Notification
												   object:nil];
	}
	return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[hostAndObserverListLock lock];
	[hosts          release]; hosts          = nil;
	[observers      release]; observers      = nil;
	[reachabilities release]; reachabilities = nil;
	
	[unconfiguredHostsAndObservers release]; unconfiguredHostsAndObservers = nil;
	[hostAndObserverListLock unlock];

	[hostAndObserverListLock release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

#pragma mark -
#pragma mark Observer management

/*!
 *	@brief Begins observing a host's reachability for an object.
 */
- (void)addObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host
{
	NSParameterAssert(host != nil);
	NSParameterAssert(newObserver != nil);

	NSString	*hostCopy = [host copy];
	[self scheduleReachabilityMonitoringForHost:hostCopy
									   observer:newObserver];
	[hostCopy release];
}

/*!
 *	@brief Stops an object's observation of a host's reachability.
 *
 *	When host is non-nil, stops observing that host's reachability for the given observer.
 *	When host is nil, stops observing all hosts' reachability for the given observer.
 */

- (void)removeObserver:(id <AIHostReachabilityObserver>)newObserver forHost:(NSString *)host
{
	//nil cannot observe, so it must not be in the list.
	if (!newObserver) return;

	[hostAndObserverListLock lock];

	NSUInteger numObservers = [observers count];
	for (unsigned i = 0; i < numObservers; ) {
		BOOL removed = NO;
		if (newObserver == [observers objectAtIndex:i]) {
			if ((!host) || ([host isEqualToString:[hosts objectAtIndex:i]])) {
				[hosts          removeObjectAtIndex:i];
				[observers      removeObjectAtIndex:i];
				SCNetworkReachabilityScheduleWithRunLoop((SCNetworkReachabilityRef)[reachabilities objectAtIndex:i],
														 CFRunLoopGetCurrent(),
														 kCFRunLoopDefaultMode);
				[reachabilities removeObjectAtIndex:i];

				[self removeUnconfiguredHost:host
									observer:newObserver];
				
				removed = YES;
				--numObservers;
			}
		}
		i += !removed;
	}

	[hostAndObserverListLock unlock];
}

/*
 * @brief Is an observer currently observing a host?
 *
 * @result YES if so, NO if not
 */
- (BOOL)observer:(id)observer isObservingHost:(NSString *)host
{
	BOOL isObserving = NO;
	
	[hostAndObserverListLock lock];

	if (host && observer) {
		NSUInteger numObservers = [observers count];
		for (unsigned i = 0; i < numObservers; i++) {
			if ((observer == [observers objectAtIndex:i]) &&
				([host isEqualToString:[hosts objectAtIndex:i]])) {
				isObserving = YES;
				break;
			}
		}
		
		if (!isObserving && [unconfiguredHostsAndObservers count]) {
			NSDictionary *unconfiguredHostObserverDict = [NSDictionary dictionaryWithObjectsAndKeys:
				observer, @"observer",
				host, @"host",
				nil];
			if ([unconfiguredHostsAndObservers containsObject:unconfiguredHostObserverDict]) {
				isObserving = YES;
			}
		}
	}
	
	[hostAndObserverListLock unlock];

	return isObserving;
}

#pragma mark -
#pragma mark Reachability monitoring

/*
 * @brief A host's reachability changed
 *
 * @param reachability The SCNetworkReachabilityRef for the host which changed
 */
- (void)reachabilityChanged:(SCNetworkReachabilityRef)reachability
{
	[hostAndObserverListLock lock];

	NSUInteger i = [reachabilities indexOfObjectIdenticalTo:(id)reachability];
	if (i != NSNotFound) {
		NSString *host = [hosts objectAtIndex:i];
		id <AIHostReachabilityObserver> observer = [observers objectAtIndex:i];
		
		BOOL anyHostsReachable = NO;
		
		// If we have multiple host <-> IP links (AAAA record and an A record), we need to check agreement.
		for (NSUInteger idx = 0; idx < hosts.count; idx++) {
			if (![host isEqualToString:[hosts objectAtIndex:idx]])
				continue;
			
			SCNetworkReachabilityRef otherReachability = (SCNetworkReachabilityRef)[reachabilities objectAtIndex:idx];
			SCNetworkConnectionFlags flags;

			if (SCNetworkReachabilityGetFlags(otherReachability, &flags)
				&& (flags & kSCNetworkFlagsReachable)
				&& !(flags & kSCNetworkFlagsConnectionRequired)) {
				anyHostsReachable = YES;
				break;
			}
		}
		
		// Return reachability based on any reachability response.
		if (anyHostsReachable) {
			[observer hostReachabilityMonitor:self hostIsReachable:host];
		} else {
			[observer hostReachabilityMonitor:self hostIsNotReachable:host];
		}
	}

	[hostAndObserverListLock unlock];
}

/*
 * @brief Callback for changes in a host's reachability (SCNetworkReachability)
 *
 * @param info The AIHostReachabilityMonitor which requested host reachability monitoring
 */
static void hostReachabilityChangedCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
#if CONNECTIVITY_DEBUG
	NSLog(@"*** hostReachabilityChangedCallback got flags: %c%c%c%c%c%c%c \n",  
 	      (flags & kSCNetworkFlagsTransientConnection)  ? 't' : '-',  
 	      (flags & kSCNetworkFlagsReachable)            ? 'r' : '-',  
 	      (flags & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',  
 	      (flags & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',  
 	      (flags & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',  
 	      (flags & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',  
 	      (flags & kSCNetworkFlagsIsDirect)             ? 'd' : '-');
#endif
	
	AIHostReachabilityMonitor *self = info;
	[self reachabilityChanged:target];
}

/*
 * @brief Callbacak for resolution of a host's name to an IP (CFHost)
 *
 * @param info An NSDictionary with the keys @"self", @"observer", and @"host"
 */
static void hostResolvedCallback(CFHostRef theHost, CFHostInfoType typeInfo,  const CFStreamError *error, void *info)
{
	NSDictionary				*infoDict = info;
	AIHostReachabilityMonitor	*self = [infoDict objectForKey:@"self"];
	id							observer = [infoDict objectForKey:@"observer"];
	NSString					*host = [infoDict objectForKey:@"host"];

	if (typeInfo == kCFHostAddresses) {
		//CFHostGetAddressing returns a CFArrayRef of CFDataRefs which wrap struct sockaddr
		CFArrayRef addresses = CFHostGetAddressing(theHost, NULL);
		
		if (!addresses || !CFArrayGetCount(addresses)) {
			/* We were not able to resolve the host name to an IP address.  This is most likely because we have no
			 * Internet connection or because the user is attempting to connect to MSN.
			 *
			 * Add to unconfiguredHostsAndObservers so we can try configuring again later.
			 */
			[self addUnconfiguredHost:host
							 observer:observer];
		} else if (addresses) {
			// Only add 1 observer for IPv6 and one for IPv4.
			BOOL addedIPv4 = NO, addedIPv6 = NO;
			
			for (NSData *saData in (NSArray *)addresses) {
				struct sockaddr							*remoteAddr = (struct sockaddr *)saData.bytes;
				
				if ((remoteAddr->sa_family == AF_INET && addedIPv4) || (remoteAddr->sa_family == AF_INET6 && addedIPv6)) {
					continue;
				}
				
				if (remoteAddr->sa_family == AF_INET)
					addedIPv4 = YES;
				if (remoteAddr->sa_family == AF_INET6)
					addedIPv6 = YES;
							
				SCNetworkReachabilityRef		reachabilityRef;
				SCNetworkReachabilityContext	reachabilityContext = {
					.version         = 0,
					.info            = self,
					.retain          = CFRetain,
					.release         = CFRelease,
					.copyDescription = CFCopyDescription,
				};
				SCNetworkConnectionFlags				flags;
				struct sockaddr_in						localAddr;
				
				/* Create a reachability reference pair with localhost and the remote host */
				
				//Our local address is 127.0.0.1
				bzero(&localAddr, sizeof(localAddr));
				localAddr.sin_len = sizeof(localAddr);
				localAddr.sin_family = AF_INET;
				inet_aton("127.0.0.1", &localAddr.sin_addr);
				
				//Create the pair
				reachabilityRef = SCNetworkReachabilityCreateWithAddressPair(NULL, 
																			 (struct sockaddr *)&localAddr, 
																			 remoteAddr);
				
				//Configure our callback
				SCNetworkReachabilitySetCallback(reachabilityRef, 
												 hostReachabilityChangedCallback, 
												 &reachabilityContext);
				
				//Add it to the run loop so we will receive the notifications
				SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef,
														 CFRunLoopGetCurrent(),
														 kCFRunLoopDefaultMode);
				
				//Note that we succesfully configured for reachability notifications
				[self gotReachabilityRef:(SCNetworkReachabilityRef)[(NSObject *)reachabilityRef autorelease]
								 forHost:host
								observer:observer];

				if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
					//We already have valid flags for the reachabilityRef
			#if CONNECTIVITY_DEBUG
					NSLog(@"Immediate reachability info for %@", reachabilityRef);
			#endif
					hostReachabilityChangedCallback(reachabilityRef,
													flags,
													self);

				} else {
					/* Perform an immediate reachability check, since we've just scheduled checks for future changes
					* and won't be notified immediately.  We update the hostContext to include our reachabilityRef before
					* scheduling the info resolution (it's still in our run loop from when we requested the IP address).
					*/
					CFHostClientContext	hostContext = {
						.version		 = 0,
						.info			 = [NSDictionary dictionaryWithObjectsAndKeys:
							self, @"self",
							host, @"host",
							observer, @"observer",
							[NSValue valueWithPointer:reachabilityRef], @"reachabilityRef",
							nil],
						.retain			 = CFRetain,
						.release		 = CFRelease,
						.copyDescription = CFCopyDescription,
					};
					CFHostSetClient(theHost,
									hostResolvedCallback,
									&hostContext);
					CFHostStartInfoResolution(theHost,
											  kCFHostReachability,
											  NULL);
				}

			}
		}
		
	} else if (typeInfo == kCFHostReachability) {
		/* Asynchronous host reachability notification from CFHost(), triggered by CFHostStartInfoResolution() above. */
		SCNetworkConnectionFlags	flags;
		CFDataRef					flagsData = CFHostGetReachability(theHost,
																	  NULL);
		CFDataGetBytes(flagsData,
					   CFRangeMake(0, CFDataGetLength(flagsData)),
					   (UInt8 *)&flags);

		//Call the reachability changed callback directly
		hostReachabilityChangedCallback((SCNetworkReachabilityRef)[infoDict objectForKey:@"reachabilityRef"],
										flags,
										self);

		//No further need for this CFHost to be in our run loop
		CFHostUnscheduleFromRunLoop(theHost,
									CFRunLoopGetCurrent(),
									kCFRunLoopDefaultMode);
	}
}

/*
 * @brief We obtained an SCNetworkReachabilityRef for a host/observer pair
 *
 * We can now effectively monitor connectivity between us and the host.
 *
 * Add these three objects to our hosts, observers, and reachabilities arrays respectively so we can determine the
 * host and observer given the reachabilityRef in hostReachabilityChangedCallback() above.
 *
 * Remove the host/observer pair from the unconfigured dictionary.
 */
- (void)gotReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef forHost:(NSString *)host observer:(id)observer
{
	//Add to our arrays for tracking
	[hostAndObserverListLock lock];
	
	[hosts          addObject:host];
	[observers      addObject:observer];
	[reachabilities addObject:(id)reachabilityRef];
	
	//Remove from our unconfigured array
	[self removeUnconfiguredHost:host
						observer:observer];
	
	[hostAndObserverListLock unlock];

#if CONNECTIVITY_DEBUG
	NSLog(@"Obtained reachability ref %@ for %@ (%@).",reachabilityRef, host, observer);
#endif
}

/*
 * @brief Schedule a reachability check for a host, with an observer
 *
 * This method begins the process of scheduling the reachability check.  It actually creates a CFHost to schedules
 * an asynchronous IP lookup for nodename.  hostResolvedCallback() will be called when it succeeds or fails.
 *
 * @param nodename The name such as "xtras.adium.im"
 * @param observer The observer which will be notified when the reachability changes
 */
- (void)scheduleReachabilityMonitoringForHost:(NSString *)nodename observer:(id)observer
{
	//Resolve the remote host domain name to an IP asynchronously
	CFHostClientContext	hostContext = {
		.version		 = 0,
		.info			 = [NSDictionary dictionaryWithObjectsAndKeys:
							self, @"self",
							nodename, @"host",
							observer, @"observer",
							nil],
		.retain			 = CFRetain,
		.release		 = CFRelease,
		.copyDescription = CFCopyDescription,
	};
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault,
										  (CFStringRef)nodename);
	CFHostSetClient(host,
					hostResolvedCallback,
					&hostContext);
	CFHostScheduleWithRunLoop(host,
							  CFRunLoopGetCurrent(),
							  kCFRunLoopDefaultMode);
	CFHostStartInfoResolution(host,
							  kCFHostAddresses,
							  NULL);
#if CONNECTIVITY_DEBUG
	NSLog(@"Scheduled reachability check for %@",nodename);
#endif
	
	CFRelease(host);
}

#pragma mark -
#pragma mark Unconfigured hosts
/*
 * @brief Add an unconfigured host and observer to unconfiguredHostsAndObservers
 *
 * We have to resolve a host to an IP address before we can properly observe reachability.  unconfiguredHostsAndObservers
 * holds information on host/observer pairs which we haven't been able to resolve yet.  When the IP configuration changes,
 * we will try again, hoping to get an IP address this time.
 */
- (void)addUnconfiguredHost:(NSString *)host observer:(id)observer
{
	NSDictionary *unconfiguredHostDict = [NSDictionary dictionaryWithObjectsAndKeys:
		observer, @"observer",
		host, @"host",
		nil];
	BOOL addedNewUnconfiguredHost = NO;
	[hostAndObserverListLock lock];
	if (![unconfiguredHostsAndObservers containsObject:unconfiguredHostDict]) {
		addedNewUnconfiguredHost = YES;
		[unconfiguredHostsAndObservers addObject:unconfiguredHostDict];
	}
	[hostAndObserverListLock unlock];
	
	if (addedNewUnconfiguredHost) {
		/* If this is the first unconfigured host, begin monitoring IP changes so we can try to set it (and any others)
		* up at the earliest possible time.
		*/
		if ([unconfiguredHostsAndObservers count] == 1) {
			[self beginMonitorngIPChanges];
		}

#if CONNECTIVITY_DEBUG
		NSLog(@"Unable to resolve %@. Now monitoring IP changes for %@",host,unconfiguredHostsAndObservers);
#endif

		/*
		 * There are various ways we can get here when we already have an IP, such as when other network conditions
		 * need to be negotiated at the router-level before we're actually connected.  In such a case, IPs aren't going to
		 * change... so we'll check one more time, 10 seconds from the last time we get an unconfigured host call,
		 * for connectivity.
		 */
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(queryUnconfiguredHosts)
												   object:nil];
		[self performSelector:@selector(queryUnconfiguredHosts)
				   withObject:nil
				   afterDelay:10.0];
	}
}

/*
 * @brief Remove an unconfigured host and observer from unconfiguredHostsAndObservers
 *
 * Must be called with the hostAndObserverListLock already obtained.
 */
- (void)removeUnconfiguredHost:(NSString *)host observer:(id)observer
{
	[unconfiguredHostsAndObservers removeObject:[NSDictionary dictionaryWithObjectsAndKeys:
		observer, @"observer",
		host, @"host",
		nil]];

	if ([unconfiguredHostsAndObservers count] == 0) {
		[self stopMonitoringIPChanges];
	}
}

/*
 * @brief Attempt to set up reachability monitoring for all currently unconfigured hosts
 *
 * Called by localIPsChangedCallback() in response to a change in the local IP list.
 *
 * Also called 5 seconds after one or more unconfigured hosts are added to verify they are actually unreachable.
 *
 * If we are able to schedule reachability monitoring for a given host, its dictionary in unconfiguredHostsAndObservers
 * will be removed.
 */
- (void)queryUnconfiguredHosts
{
	if ([unconfiguredHostsAndObservers count]) {
		[hostAndObserverListLock lock];
		for (NSDictionary *unconfiguredDict in unconfiguredHostsAndObservers) {
			[self scheduleReachabilityMonitoringForHost:[unconfiguredDict objectForKey:@"host"]
											   observer:[unconfiguredDict objectForKey:@"observer"]];
		}
		[hostAndObserverListLock unlock];
	}
}

/*
 * @brief The local IP list changed (SCDynamicStore)
 *
 * @param info The AIHostReachabilityMonitor which set up the callback
 */
static void localIPsChangedCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
	AIHostReachabilityMonitor	*self = info;
	
	/* Wait one second after receiving the callback, as it seems to be sent in some cases the middle of the change
	 * rather than after it is complete.
	 */
	[self performSelector:@selector(queryUnconfiguredHosts)
			   withObject:nil
			   afterDelay:1.0];	
}

static OSStatus CreateIPAddressListChangeCallbackSCF(SCDynamicStoreCallBack callback, void *contextPtr, 
													 SCDynamicStoreRef *storeRef, CFRunLoopSourceRef *sourceRef);

/*
 * @brief Monitor when our local IP list changes, which generally indicates a possible change in network connectivity
 */
- (void)beginMonitorngIPChanges
{
	if (!ipChangesRunLoopSourceRef) {		
		SCDynamicStoreRef	storeRef = nil;
		OSStatus			status;
		
		//Create the CFRunLoopSourceRef we will want to add to our run loop to have
		//localIPsChangedCallback() called when the IP list changes
		status = CreateIPAddressListChangeCallbackSCF(localIPsChangedCallback, 
													  self,
													  &storeRef,
													  &ipChangesRunLoopSourceRef);
		
		//Add it to the run loop so we will receive the notifications
		if((status == noErr) && ipChangesRunLoopSourceRef){
			CFRunLoopAddSource(CFRunLoopGetCurrent(),
							   ipChangesRunLoopSourceRef,
							   kCFRunLoopDefaultMode);
		}
		
		if (storeRef) CFRelease(storeRef);
	}
}

/*
 * @brief Stop monitoring changes to our local IP list
 */
- (void)stopMonitoringIPChanges
{
	if (ipChangesRunLoopSourceRef) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
							  ipChangesRunLoopSourceRef,
							  kCFRunLoopDefaultMode);
		CFRelease(ipChangesRunLoopSourceRef);
		ipChangesRunLoopSourceRef = nil;
	}
}

#pragma mark -
#pragma mark Sleep and Wake

/*!
 * @brief System is waking from sleep
 *
 * When the system wakes, manually reconfigure reachability checking as not all network configurations will report a change.
 */
- (void)systemDidWake:(NSNotification *)notification
{
	[hostAndObserverListLock lock];

	NSArray	*oldHosts = [hosts copy];
	NSArray	*oldObservers = [observers copy];
	
	[reachabilities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SCNetworkReachabilityUnscheduleFromRunLoop((SCNetworkReachabilityRef)obj,
												   CFRunLoopGetCurrent(),
												   kCFRunLoopDefaultMode);
	}];
	
	[hosts removeAllObjects];
	[observers removeAllObjects];
	[reachabilities removeAllObjects];
	
	[hostAndObserverListLock unlock];

	NSUInteger numObservers = [oldObservers count];
	for (unsigned i = 0; i < numObservers; i++) {
		NSString						*host = [oldHosts objectAtIndex:i];
		id<AIHostReachabilityObserver>	observer = [oldObservers objectAtIndex:i];

		[self addObserver:observer
				  forHost:host];
	}
	
	[oldHosts release];
	[oldObservers release];
}

#pragma mark -
#pragma mark CreateIPAddressListChangeCallbackSCF

/*CreateIPAddressListChangeCallbackSCF() and its supporting functions are from
*	Apple's "Living in a Dynamic TCP/IP Environment, available at
*	http://developer.apple.com/technotes/tn/tn1145.html
*/

//Error Handling  ------------------------------------------------------------------------------------------------------
// Error Handling
// --------------
// SCF returns errors in two ways:
//
// o The function result is usually set to something
//   generic (like NULL or false) to indicate an error.
//
// o There is a call, SCError, that returns the error
//   code for the most recent function.  These error codes
//   are not in the OSStatus domain.
//
// We deal with this using two functions, MoreSCError
// and MoreSCErrorBoolean.  Both of these take a generic
// failure indicator (a pointer or a Boolean) and, if
// that indicates an error, they call SCError to get the
// real error code.  They also act as a bottleneck for
// mapping SC errors into the OSStatus domain, although
// I don't do that in this simple implementation.
//
// Note that I could have eliminated the failure indicator
// parameter and just called SCError but I'm worried
// about SCF returning an error indicator without setting
// the SCError.  There's no justification for this worry
// other than general paranoia (I know of no examples where
// this happens),

static OSStatus MoreSCErrorBoolean(Boolean success)
{
    OSStatus err;
    int scErr;
	
    err = noErr;
    if ( ! success ) {
        scErr = SCError();
        if (scErr == kSCStatusOK) {
            scErr = kSCStatusFailed;
        }
        // Return an SCF error directly as an OSStatus.
        // That's a little cheesy.  In a real program
        // you might want to do some mapping from SCF
        // errors to a range within the OSStatus range.
        err = scErr;
    }
    return err;
}

static OSStatus MoreSCError(const void *value)
{
    return MoreSCErrorBoolean(value != NULL);
}

static OSStatus CFQError(CFTypeRef cf)
// Maps Core Foundation error indications (such as they
// are) to the OSStatus domain.
{
    OSStatus err;
	
    err = noErr;
    if (cf == NULL) {
        err = coreFoundationUnknownErr;
    }
    return err;
}

//CreateIPAddressListChangeCallbackSCF ----------------------------------------------------------------------------------

static OSStatus CreateIPAddressListChangeCallbackSCF(SCDynamicStoreCallBack callback,
													 void *contextPtr,
													 SCDynamicStoreRef *storeRef,
													 CFRunLoopSourceRef *sourceRef)
// Create a SCF dynamic store reference and a
// corresponding CFRunLoop source.  If you add the
// run loop source to your run loop then the supplied
// callback function will be called when local IP
// address list changes.
{
    OSStatus                err;
    SCDynamicStoreContext   context = {0, NULL, NULL, NULL, NULL};
    SCDynamicStoreRef       ref;
    CFStringRef             pattern;
    CFArrayRef              patternList;
    CFRunLoopSourceRef      rls;
	
    assert(callback   != NULL);
    assert( storeRef  != NULL);
    assert(*storeRef  == NULL);
    assert( sourceRef != NULL);
    assert(*sourceRef == NULL);
	
    ref = NULL;
    pattern = NULL;
    patternList = NULL;
    rls = NULL;
	
    // Create a connection to the dynamic store, then create
    // a search pattern that finds all IPv4 entities.
    // The pattern is "State:/Network/Service/[^/]+/IPv4".
	
    context.info = contextPtr;
    ref = SCDynamicStoreCreate( NULL,
                                CFSTR("AddIPAddressListChangeCallbackSCF"),
                                callback,
                                &context);
    err = MoreSCError(ref);
    if (err == noErr) {
        pattern = SCDynamicStoreKeyCreateNetworkServiceEntity(
															  NULL,
															  kSCDynamicStoreDomainState,
															  kSCCompAnyRegex,
															  kSCEntNetIPv4);
        err = MoreSCError(pattern);
    }
	
    // Create a pattern list containing just one pattern,
    // then tell SCF that we want to watch changes in keys
    // that match that pattern list, then create our run loop
    // source.
	
    if (err == noErr) {
        patternList = CFArrayCreate(NULL,
                                    (const void **) &pattern, 1,
                                    &kCFTypeArrayCallBacks);
        err = CFQError(patternList);
    }
    if (err == noErr) {
        err = MoreSCErrorBoolean(
								 SCDynamicStoreSetNotificationKeys(
																   ref,
																   NULL,
																   patternList)
								 );
    }
    if (err == noErr) {
        rls = SCDynamicStoreCreateRunLoopSource(NULL, ref, 0);
        err = MoreSCError(rls);
    }
	
    // Clean up.
	
    if (pattern) CFRelease(pattern);
    if (patternList) CFRelease(patternList);
    if (err != noErr) {
        if (ref) {
			CFRelease(ref);
			ref = NULL;
		}
    }
    *storeRef = ref;
    *sourceRef = rls;
	
    assert( (err == noErr) == (*storeRef  != NULL) );
    assert( (err == noErr) == (*sourceRef != NULL) );
	
    return err;
}

@end
