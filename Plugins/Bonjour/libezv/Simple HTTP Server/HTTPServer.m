#import "AsyncSocket.h"
#import "HTTPServer.h"
#import "HTTPAuthenticationRequest.h"
#import "EKEzvOutgoingFileTransfer.h"
#import <SystemConfiguration/SystemConfiguration.h>

#import <stdlib.h>

// Define the various timeouts (in seconds) for various parts of the HTTP process
#define READ_TIMEOUT        -1
#define WRITE_HEAD_TIMEOUT  30
#define WRITE_BODY_TIMEOUT  -1
#define WRITE_ERROR_TIMEOUT 30

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST           15
#define HTTP_PARTIAL_RESPONSE  29
#define HTTP_RESPONSE          30

#define HTTPConnectionDidDieNotification  @"HTTPConnectionDidDie"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPServer ()
- (void)connectionDidDie:(NSNotification *)notification;
@end

@implementation HTTPServer

/**
 * Standard Constructor.
 * Instantiates an HTTP server, but does not start it.
**/
- (id)init
{
	if ((self = [super init]))
	{
		// Initialize underlying asynchronous tcp/ip socket
		asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
		
		// Use default connection class of HTTPConnection
		connectionClass = [HTTPConnection self];
				
		// Use a default port of 0
		// This will allow the kernel to automatically pick an open port for us
		port = 0;
		
		// Initialize an array to hold all the HTTP connections
		connections = [[NSMutableArray alloc] init];
		
		// And register for notifications of closed connections
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(connectionDidDie:)
													 name:HTTPConnectionDidDieNotification
												   object:nil];
	}
	return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
**/
- (void)dealloc
{
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Stop the server if it's running
	[self stop];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Configuration:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the delegate connected with this instance.
**/
- (id)delegate
{
	return delegate;
}

/**
 * Sets the delegate connected with this instance.
**/
- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

/**
 * The document root is filesystem root for the webserver.
 * Thus requests for /index.html will be referencing the index.html file within the document root directory.
 * All file requests are relative to this document root.
**/
- (NSURL *)documentRoot {
    return documentRoot;
}
- (void)setDocumentRoot:(NSURL *)value
{
    if (![documentRoot isEqual:value])
	{
        documentRoot = [value copy];
    }
}

/**
 * The connection class is the class that will be used to handle connections.
 * That is, when a new connection is created, an instance of this class will be intialized.
 * The default connection class is HTTPConnection.
 * If you use a different connection class, it is assumed that the class extends HTTPConnection
**/
- (Class)connectionClass {
    return connectionClass;
}
- (void)setConnectionClass:(Class)value
{
    connectionClass = value;
}


/**
 * The port to listen for connections on.
 * By default this port is initially set to zero, which allows the kernel to pick an available port for us.
 * After the HTTP server has started, the port being used may be obtained by this method.
**/
- (UInt16)port {
    return port;
}
- (void)setPort:(UInt16)value {
    port = value;
}


- (NSString *)localHost{
	for (NSString *addr in [[NSHost currentHost] addresses])
	{
		if ([[addr componentsSeparatedByString:@"."] count] == 4 && ![addr isEqual:@"127.0.0.1"])
		{
			return addr;
		}
	}
	return [NSString stringWithFormat:@"127.0.0.1"]; // No non-loopback IPv4 addresses exist
}

- (void)setTransfer:(EKEzvOutgoingFileTransfer *)newTransfer{
	if (transfer !=newTransfer)
	{
		transfer = newTransfer;
	}
}
- (EKEzvOutgoingFileTransfer *)transfer{
	return transfer;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Control:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)start:(NSError **)error
{
	BOOL success = [asyncSocket acceptOnPort:port error:error];
	
	if (success)
	{
		// Update our port number
		[self setPort:[asyncSocket localPort]];
		
		// Output console message for debugging purposes
		// NSLog(@"Started HTTP server on port %hu", port);
	}
	
	return success;
}

- (BOOL)stop
{
	// Now stop the asynchronouse tcp server
	// This will prevent it from accepting any more connections
	[asyncSocket disconnect];
	
	// Now stop all HTTP connections the server owns
	[connections removeAllObjects];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Status:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the number of clients that are currently connected to the server.
**/
- (NSInteger)numberOfHTTPConnections
{
	return [connections count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark AsyncSocket Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	/*The contact has attempted to download so tell the main thread that we are now longer waiting on a remote user */
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	[transfer userBeganDownload];
	
	id newConnection = [[connectionClass alloc] initWithAsyncSocket:newSocket forServer:self];
	[connections addObject:newConnection];
}

/**
 * This method is automatically called when a notification of type HTTPConnectionDidDieNotification is posted.
 * It allows us to remove the connection from our array.
**/
- (void)connectionDidDie:(NSNotification *)notification
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	if (self != (HTTPServer *)[[notification object] server]) {
		return;
	} else {
		if (![transfer moreFilesToDownload]) {
			[transfer userFinishedDownload];
		}
		// [connections removeObject:[notification object]];
		
	}
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation HTTPConnection


/**
 * Sole Constructor.
 * Associates this new HTTP connection with the given AsyncSocket.
 * This HTTP connection object will become the socket's delegate and take over responsibility for the socket.
**/
- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer
{
	if ((self = [super init]))
	{
		// Take over ownership of the socket
		asyncSocket = newSocket;
		[asyncSocket setDelegate:self];
		
		// Store reference to server
		// Note that we do not retain the server. Parents retain their children, children do not retain their parents.
		server = myServer;
		
		
		// Create a new HTTP message
		// Note the second parameter is YES, because it will be used for HTTP requests from the client
		request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
		
		// And now that we own the socket, and we have our CFHTTPMessage object (for requests) ready,
		// we can start reading the HTTP requests...
		[asyncSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
	}
	return self;
}

/**
 * Standard Deconstructor.
**/
- (void)dealloc
{
	if (request) CFRelease(request);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connection Control:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * This method is called after a full HTTP request has been received.
 * The current request is in the CFHTTPMessage request variable.
**/
- (void)replyToHTTPRequest
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	
	// Print out the entire httprequest
//	NSDictionary *headers = [(NSDictionary *)CFHTTPMessageCopyAllHeaderFields(request) autorelease];
//	NSString *requestMethod = [(NSString *)CFHTTPMessageCopyRequestMethod(request) autorelease];
//	NSString *requestVersion = [(NSString *)CFHTTPMessageCopyVersion(request) autorelease];
//	NSURL *requestURI = [(NSURL *)CFHTTPMessageCopyRequestURL(request) autorelease];

	NSString *encoding = (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Accept-Encoding"));
	bool isAppleSingle = NO;
	if ([encoding isEqualToString:@"AppleSingle"]) {
		isAppleSingle = YES;
	}
	
	NSString *connection = (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Connection"));
	bool isKeepAlive = NO;
	if ([connection isEqualToString:@"keep-alive"]) {
		isKeepAlive = YES;
	}
	
	// NSLog(@"HTTP Server: Version - %@\nMethod - %@\nURI - %@\nRequest - %@", requestVersion, requestMethod, requestURI, headers);
	
	// Check the HTTP version
	// If it's anything but HTTP version 1.1, we don't support it
	NSString *version = (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(request);
    if (!version || ![version isEqualToString:(NSString *)kCFHTTPVersion1_1]) {
		//NSLog(@"HTTP Server: Error 505 - Version Not Supported");
		
		// Status Code 505 - Version Not Supported
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, (__bridge CFStringRef)version);
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
        NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
		[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
		CFRelease(response);
		[[server transfer] userFailedDownload];
		return;
	}
	
	// Check HTTP method
	// If no method was passed, issue a Bad Request response
    NSString *method = (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(request);
    if (!method) {
		//NSLog(@"HTTP Server: Error 400 - Bad Request");
		
		// Status Code 400 - Bad Request
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1);
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
        NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
		[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
        CFRelease(response);
		[[server transfer] userFailedDownload];
		return;
	}
	
	// Extract requested URI
	NSURL *uri = (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(request);
	
	// Respond properly to HTTP 'GET' and 'HEAD' commands
    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]) {
		// AWEzvLog(@"responding to get/head");
		NSData *data = [self dataForURI:[uri relativeString] appleSingle:isAppleSingle];
		
        if (!data)
		{
			/*We have a request for a non-existant file so we need to stop the transfer */
			[[server transfer] userFailedDownload];
			return;
        }
		
		// Status Code 200 - OK
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
		[self setHeaderFields:response forURI:[uri relativeString] appleSingle: isAppleSingle keepAlive:isKeepAlive];
		NSString *contentLength = [NSString stringWithFormat:@"%li", [data length]];
        CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)contentLength);

		//NSDictionary *responseHeaders = [(NSDictionary *)CFHTTPMessageCopyAllHeaderFields(response) autorelease];
		// NSLog(@"Sending Headers - %@", responseHeaders);


		// If they issue a 'HEAD' command, we don't have to include the file
		// If they issue a 'GET' command, we need to include the file
		if ([method isEqual:@"HEAD"])
		{
			NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
			[asyncSocket writeData:responseData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_RESPONSE];
        } else {
			// Previously, we would use the CFHTTPMessageSetBody method here.
			// This caused problems, however, if the data was large.
			// For example, if the data represented a 500 MB movie on the disk, this method would thrash the OS!
			
			NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
			[asyncSocket writeData:responseData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_PARTIAL_RESPONSE];
			[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_RESPONSE];
		}
		
		CFRelease(response);
		return;
    }
	
	//NSLog(@"HTTP Server: Error 405 - Method Not Allowed: %@", method);
	
	// Status code 405 - Method Not Allowed
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1);
    NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(response);
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
    CFRelease(response);

	[[server transfer] userFailedDownload];

	return;
}

/**
 * This method transforms the relative URL to the full URL.
 * It takes care of requests such as "/", transforming them to "/index.html".
 * This method can easily be overriden to perform more advanced lookups.
**/
- (NSData *)dataForURI:(NSString *)path appleSingle:(BOOL)isAppleSingle
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSMutableData *data = [NSMutableData data];


	if ([[server transfer] isDirectory] && [[server transfer] isBaseURIForDirectoryTransfer: path]) {
		/*If this is the base url for a directory transfer then we need to send the xml */
		[data appendData:[[server transfer] directoryXMLData]];
		// AWEzvLog(@"%@", data);
	} else {

	/*Check to see whether we should get applesingle data*/
		if (isAppleSingle) {
			[data appendData:[[server transfer] appleSingleDataForURI:path]];
		}

		/*Send the AppleSingle data along with the other stuff!*/
		/*We will get the path so let's load the data from the path */
		if (data) {
			NSError *error = nil;
			NSData *fileData = [[NSData alloc] initWithContentsOfFile:[[server transfer] fileDataForURI:path] options:(NSMappedRead | NSUncachedRead) error:&error];
			if (error || (fileData == nil)) {
				data = nil;
			} else {
				[data appendData: fileData];
			}
		}
	}
	return data;
}

- (void) setHeaderFields:(CFHTTPMessageRef)messageRef forURI:(NSString *)path appleSingle:(BOOL)isAppleSingle keepAlive:(BOOL)isKeepAlive
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	/*Set the iChat header field responses*/
	CFHTTPMessageRef response = messageRef;
    CFHTTPMessageSetHeaderFieldValue(response,CFSTR("Accept-Ranges"),CFSTR("bytes"));
	CFHTTPMessageSetHeaderFieldValue(response,CFSTR("Connection"),CFSTR("close"));
	if (isAppleSingle)
		CFHTTPMessageSetHeaderFieldValue(response,CFSTR("Content-Encoding"),CFSTR("AppleSingle"));
	CFHTTPMessageSetHeaderFieldValue(response,CFSTR("Date"),(__bridge CFStringRef)[[NSDate date] description]);
	CFHTTPMessageSetHeaderFieldValue(response,CFSTR("Server"),CFSTR("Fez (Mac OS X)"));
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark AsyncSocket Delegate Methods:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called immediately prior to opening up the stream.
 * This is the time to manually configure the stream if necessary.
**/
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	
	return YES;
}

/**
 * This method is called after the socket has successfully read data from the stream.
 * Remember that this method will only be called after the socket reaches a CRLF, or after it's read the proper length.
**/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	
	// Append the header line to the http message
	CFHTTPMessageAppendBytes(request, [data bytes], [data length]);
	if (!CFHTTPMessageIsHeaderComplete(request)) {
		// We don't have a complete header yet
		// That is, we haven't yet received a CRLF on a line by itself, indicating the end of the header
		[asyncSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
	}
	else
	{
		// We have an entire HTTP request from the client
		// Now we need to reply to it
		[self replyToHTTPRequest];
	}
}

/**
 * This method is called after the socket has successfully written data to the stream.
 * Remember that this method will be called after a complete response to a request has been written.
**/
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	
	// There are two possible tags: HTTP_RESPONSE and HTTP_PARTIAL_RESPONSE
	// A partial response represents a header response with a body following it,
	// so we still need to wait til the body is sent too.
	
	if (tag == HTTP_RESPONSE)
	{
		// Release the old request, and create a new one
		if (request) CFRelease(request);
		request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
		
		// And start listening for more requests
		[asyncSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:HTTP_REQUEST];
	}
}

/**
 * This message is sent:
 *  - if there is an connection, time out, or other i/o error.
 *  - if the remote socket cleanly disconnects.
 *  - before the local socket is disconnected.
**/
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{	
	if (err)
	{
	}
}

/**
 * Sent after the socket has been disconnected.
**/
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	// AWEzvLog(@"%s",  __PRETTY_FUNCTION__);
	
	// Post notification of dead connection
	// This will allow our server to release it from it's array of connections
	[[NSNotificationCenter defaultCenter] postNotificationName:HTTPConnectionDidDieNotification object:self];
}


- (void)didSendDataWithLength:(UInt32)length
{
	[[server transfer] didSendDataWithLength:length];
}

- (HTTPServer *)server
{
	return server;
}
@end
