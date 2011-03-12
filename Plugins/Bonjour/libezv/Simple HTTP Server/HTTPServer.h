
@class EKEzvOutgoingFileTransfer, AsyncSocket;

@interface HTTPServer : NSObject
{
	// Underlying asynchronous TCP/IP socket
	AsyncSocket *asyncSocket;
	
	// Standard delegate
	id delegate;
	
	// HTTP server configuration
	NSURL *documentRoot;
	Class connectionClass;
	
	UInt16 port;
	
	NSMutableArray *connections;
	
	EKEzvOutgoingFileTransfer *transfer;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (EKEzvOutgoingFileTransfer *)transfer;

- (NSURL *)documentRoot;
- (void)setDocumentRoot:(NSURL *)value;

- (Class)connectionClass;
- (void)setConnectionClass:(Class)value;

- (UInt16)port;
- (void)setPort:(UInt16)value;

- (NSString *)localHost;

- (void)setTransfer:(EKEzvOutgoingFileTransfer *)newTransfer;
- (EKEzvOutgoingFileTransfer *)transfer;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (NSInteger)numberOfHTTPConnections;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPConnection : NSObject
{
	AsyncSocket *asyncSocket;
	HTTPServer *server;
	
	CFHTTPMessageRef request;
	
	NSString *nonce;
	int lastNC;
}

- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer;

- (NSData *)dataForURI:(NSString *)path appleSingle:(BOOL)isAppleSingle;

- (void)didSendDataWithLength:(UInt32)length;

- (HTTPServer *)server;

- (void) setHeaderFields:(CFHTTPMessageRef)messageRef forURI:(NSString *)path appleSingle:(BOOL)isAppleSingle keepAlive:(BOOL)isKeepAlive;

@end
