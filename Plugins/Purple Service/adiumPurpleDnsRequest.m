//
//  adiumPurpleDnsRequest.m
//  Adium
//
//  Created by Graham Booker on 2/24/07.
//

#import "adiumPurpleDnsRequest.h"

#include <libpurple/internal.h>

#include <sys/socket.h>
#include <netdb.h>

@interface AdiumPurpleDnsRequest : NSObject {
	PurpleDnsQueryData *query_data;
	PurpleDnsQueryResolvedCallback resolved_cb;
	PurpleDnsQueryFailedCallback failed_cb;
	CFHostRef host;
	BOOL finished_lookup;
}

+ (AdiumPurpleDnsRequest *)lookupRequestForData:(PurpleDnsQueryData *)query_data;
- (id)initWithData:(PurpleDnsQueryData *)data resolvedCB:(PurpleDnsQueryResolvedCallback)resolved failedCB:(PurpleDnsQueryFailedCallback)failed;
- (BOOL)startLookup;
- (void)lookupFailedWithError:(const CFStreamError *)streamError;
- (void)lookupSucceededWithAddresses:(NSArray *)addresses;
- (void)cancel;
@end

@implementation AdiumPurpleDnsRequest

static NSMutableDictionary *lookupRequestsByQueryData = nil;

+ (void)initialize
{
	if (self == [AdiumPurpleDnsRequest class]) {
		lookupRequestsByQueryData = [[NSMutableDictionary alloc] init];
	}
}

+ (AdiumPurpleDnsRequest *)lookupRequestForData:(PurpleDnsQueryData *)query_data
{
	return [lookupRequestsByQueryData objectForKey:[NSValue valueWithPointer:query_data]];
}

/*!
 * @brief Perform a DNS lookup request
 * 
 * @result YES if the DNS lookup began successfully. It was asynchronously return success or failure at a later time.
 */
+ (BOOL)performDnsRequestWithData:(PurpleDnsQueryData *)inData resolvedCB:(PurpleDnsQueryResolvedCallback)inResolved failedCB:(PurpleDnsQueryFailedCallback)inFailed
{
	return [[[[self alloc] initWithData:inData resolvedCB:inResolved failedCB:inFailed] autorelease] startLookup];
}

- (id)initWithData:(PurpleDnsQueryData *)data resolvedCB:(PurpleDnsQueryResolvedCallback)resolved failedCB:(PurpleDnsQueryFailedCallback)failed
{
	self = [super init];
	if(self == nil)
		return nil;
	
	query_data = data;
	resolved_cb = resolved;
	failed_cb = failed;
	finished_lookup = NO;

	[lookupRequestsByQueryData setObject:self forKey:[NSValue valueWithPointer:query_data]];

	//Released in finishDnsRequest
	[self retain];

	return self;
}

- (void)dealloc
{
	if (host)
		CFRelease(host);
	
	[super dealloc];
}

- (PurpleDnsQueryData *)queryData
{
	return query_data;
}

/*!
 * @brief Called by CFHost when the resolve is complete or fails
 */
static void host_client_cb(CFHostRef theHost, CFHostInfoType typeInfo,
						   const CFStreamError *streamError,
						   void *info)
{
	AdiumPurpleDnsRequest *self = (AdiumPurpleDnsRequest *)info;
	if (streamError && (streamError->error != 0)) {
		[self lookupFailedWithError:streamError];

	} else {
		Boolean hasBeenResolved;

		/* CFHostGetAddressing retrieves the known addresses from the given host. Returns a
		 CFArrayRef of addresses.  Each address is a CFDataRef wrapping a struct sockaddr. */
		CFArrayRef addresses = CFHostGetAddressing(theHost, &hasBeenResolved);
		if (hasBeenResolved) {
			[self lookupSucceededWithAddresses:(NSArray *)addresses];

		} else {
			[self lookupFailedWithError:NULL];
		}
	}
}

/*!
 * @brief Lookup succeeded
 *
 * This will call the resolved callback provided by libpurple
 *
 * @param addresses An NSArray of NSData objects, each wrapping a struct sockaddr
 */
- (void)lookupSucceededWithAddresses:(NSArray *)addresses
{
	//Success! Build a list of our results and pass it to the resolved callback
	AILog(@"DNS resolve complete for %s:%d",
		  purple_dnsquery_get_host(query_data),
		  purple_dnsquery_get_port(query_data));	

	NSEnumerator *enumerator = [addresses objectEnumerator];
	NSData		 *address;
	GSList		 *returnAddresses = NULL;
	unsigned short port = purple_dnsquery_get_port(query_data);

	while ((address = [enumerator nextObject])) {
		struct sockaddr *addr = (struct sockaddr *)[address bytes];

		struct sockaddr_in *addr_to_return = g_malloc(addr->sa_len);
		memcpy(addr_to_return, addr, addr->sa_len);
		addr_to_return->sin_port = htons(port);

		returnAddresses = g_slist_append(returnAddresses, GINT_TO_POINTER((int)(addr_to_return->sin_len)));
		returnAddresses = g_slist_append(returnAddresses, addr_to_return);
	}

	finished_lookup = YES;

	resolved_cb(query_data, returnAddresses);
}

/*!
 * @brief Report that the lookup failed
 *
 * This will call the failed callback provided by libpurple
 */
- (void)lookupFailedWithError:(const CFStreamError *)streamError
{
	AILogWithSignature(@"Failed lookup for %s. Error domain %i, error %i",
					   purple_dnsquery_get_host([self queryData]),
					   (streamError ? streamError->domain : 0),
					   (streamError ? streamError->error : 0));

	finished_lookup = YES;

	//Failure :( Send an error message to the failed callback
	char message[1024];
	
	g_snprintf(message, sizeof(message), _("Error resolving %s:\n%s"),
			   purple_dnsquery_get_host(query_data), (streamError ? gai_strerror(streamError->error) : _("Unknown")));
	failed_cb(query_data, message);	
}

/*!
 * @brief Begin an asynchronous lookup
 *
 * @result YES if the lookup started successfully
 */
- (BOOL)startLookup
{
	CFStreamError		streamError;
	Boolean				success;
	CFHostClientContext context =  { /* Version */ 0, /* info */ self, CFRetain, CFRelease, NULL};

	AILogWithSignature(@"Performing DNS resolve: %s:%d",
					   purple_dnsquery_get_host(query_data),
					   purple_dnsquery_get_port(query_data));
	
	host = CFHostCreateWithName(kCFAllocatorDefault,
								(CFStringRef)[NSString stringWithUTF8String:purple_dnsquery_get_host(query_data)]);
	success = CFHostSetClient(host, host_client_cb, &context);

	if (!success) {
		[self lookupFailedWithError:NULL];
		return FALSE;
	}

	CFHostScheduleWithRunLoop(host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	success = CFHostStartInfoResolution(host, kCFHostAddresses, &streamError);
	if (!success)
		[self lookupFailedWithError:&streamError];
	
	return success;
}


/*!
 * @brief Clean up after a DNS request (whether it succeeded or failed)
 *
 * Must be called only once. Should only be called by -[self cancel].
 */
- (void)_finishDnsRequest
{
	if (host) {
		CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		CFHostSetClient(host, /* callback */ NULL, /* context */ NULL);
	}

	/* Immediately remove ourselves from the global lookup dictionary so we won't be double-released */
	if (query_data) {
		[lookupRequestsByQueryData removeObjectForKey:[NSValue valueWithPointer:query_data]];
		query_data = NULL;
	}

	//Release our retain in init...
	[self autorelease];
}

/*!
 * @brief Cancel
 */
- (void)cancel
{
	if (!finished_lookup && host)
		CFHostCancelInfoResolution(host, kCFHostAddresses);

	[self _finishDnsRequest];
}

@end

gboolean adiumPurpleDnsRequestResolve(PurpleDnsQueryData *query_data, PurpleDnsQueryResolvedCallback resolved_cb, PurpleDnsQueryFailedCallback failed_cb)
{
	return [AdiumPurpleDnsRequest performDnsRequestWithData:query_data resolvedCB:resolved_cb failedCB:failed_cb];
}

/*!
 * @brief Libpurple is done with a query_data
 *
 * This will be called after we call the resolved_cb or the failed_cb or when libpurple wants us to cancel
 */
void adiumPurpleDnsRequestDestroy(PurpleDnsQueryData *query_data)
{
	[[AdiumPurpleDnsRequest lookupRequestForData:query_data] cancel];
}

static PurpleDnsQueryUiOps adiumPurpleDnsRequestOps = {
	adiumPurpleDnsRequestResolve,
	adiumPurpleDnsRequestDestroy
};

PurpleDnsQueryUiOps *adium_purple_dns_request_get_ui_ops(void)
{
	return &adiumPurpleDnsRequestOps;
}
