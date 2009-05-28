//
//  AIProgressDataUploader.m
//  Adium
//
//  Created by Zachary West on 2009-05-27.
//  
//  Interpreted from the source of OFPOSTRequest at http://objectiveflickr.googlecode.com/svn/trunk/Source/OFPOSTRequest.m
//

#import "AIProgressDataUploader.h"

#define BUFFER_SIZE 1024
#define UPDATE_INTERVAL 0.5
#define TIMEOUT_INTERVAL 30.0

@interface AIProgressDataUploader()
- (id)initWithData:(NSData *)inUploadData
			   URL:(NSURL *)inUrl
		   headers:(NSDictionary *)inHeaders
		  delegate:(id <AIProgressDataUploaderDelegate>)inDelegate
		   context:(id)inContext;

// Timers
- (void)timeoutDidOccur;
- (void)updateProgress;

// Callbacks
- (void)streamDidOpen;
- (void)errorDidOccur;
- (void)uploadSucceeded;
- (void)bytesAvailable;
@end

static void AIProgressDataUploaderCallback(CFReadStreamRef callbackStream,
										   CFStreamEventType type,
										   void *info);

@implementation AIProgressDataUploader
/*!
 * @brief Create a data uploader.
 *
 * @param delegate The delegate
 * @param context The context for this upload
 *
 * Uploading does not begin until -upload is called.
 */
+ (id)dataUploaderWithData:(NSData *)uploadData
					   URL:(NSURL *)url
				   headers:(NSDictionary *)headers
				  delegate:(id <AIProgressDataUploaderDelegate>)delegate
				   context:(id)context
{
	return [[[self alloc] initWithData:uploadData URL:url headers:headers delegate:delegate context:context] autorelease];
}

- (id)initWithData:(NSData *)inUploadData
			   URL:(NSURL *)inURL
		   headers:(NSDictionary *)inHeaders
		  delegate:(id <AIProgressDataUploaderDelegate>)inDelegate
		   context:(id)inContext
{
	if ((self = [super init])) {
		uploadData = [inUploadData retain];
		delegate = inDelegate;
		context = inContext;
		url = [inURL retain];
		headers = [inHeaders retain];
	}
	
	return self;
}

- (void)dealloc
{
	[url release];
	[headers release];
	[uploadData release];
	[returnedData release];
	
	[super dealloc];
}

/*!
 * @brief Begin the upload.
 *
 * Immediately begins the upload.
 */
- (void)upload
{
	CFHTTPMessageRef httpRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
															  CFSTR("POST"),
															  (CFURLRef)url,
															  kCFHTTPVersion1_1);
	
	for (NSString *headerKey in headers) {
		CFHTTPMessageSetHeaderFieldValue(httpRequest,
										 (CFStringRef)headerKey, 
										 (CFStringRef)[headers objectForKey:headerKey]);
	}
	
	CFHTTPMessageSetBody(httpRequest, (CFDataRef)uploadData);
	
	stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpRequest);
	
	CFStreamClientContext streamClientContext = {
		0,
		self,
		NULL,
		NULL,
		NULL
	};
	
	BOOL success = YES;
	
	if (CFReadStreamSetClient(stream,
							  /* flags */ (kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered), 
							  /* callback */ AIProgressDataUploaderCallback, 
							  /* context */ &streamClientContext)) {
		CFReadStreamScheduleWithRunLoop(stream,
										CFRunLoopGetCurrent(),
										kCFRunLoopCommonModes);
		
		returnedData = [[NSMutableData alloc] init];
		
		if (CFReadStreamOpen(stream)) {
			[self streamDidOpen];
		} else {
			success = NO;
		}
	} else {
		success = NO;
	}
	
	if (!success) {
		[delegate uploadFailed:context];	
	}
	
	CFRelease(httpRequest);
}

/*!
 * @brief Cancel the upload.
 *
 * Cancels the upload and returns no further status messages to the delegate.
 */
- (void)cancel
{
	if (!stream) {
		return;
	}
	
	CFReadStreamUnscheduleFromRunLoop(stream, 
									  CFRunLoopGetCurrent(),
									  kCFRunLoopCommonModes);
	CFReadStreamClose(stream);

	[timeoutTimer invalidate]; timeoutTimer = nil;
	[periodicTimer invalidate]; periodicTimer = nil;
}

/*!
 * @brief Stream opened
 *
 * Called when the stream is opened.
 * Sets up our periodic timer to gather the current status of the upload
 */
- (void)streamDidOpen
{
	totalSize = [uploadData length];
	
	periodicTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL
													  target:self
													selector:@selector(updateProgress)
													userInfo:nil
													 repeats:YES] retain];
	
	timeoutTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:TIMEOUT_INTERVAL]
											interval:TIMEOUT_INTERVAL
											  target:self
											selector:@selector(timeoutDidOccur)
											userInfo:nil
											 repeats:NO];
}

/*!
 * @brief Update our progress
 *
 * Updates our delegate with our current upload percent.
 */
- (void)updateProgress
{
	if (!stream) {
		return;
	}
	
	NSInteger bytesWritten;
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
	CFNumberGetValue(bytesWrittenProperty, 
					 kCFNumberNSIntegerType,
					 &bytesWritten);

	if (bytesWritten > bytesSent) {		
		bytesSent = bytesWritten;

		[delegate updateUploadPercent:(CGFloat)bytesSent/(CGFloat)totalSize
							  context:context];
		
		[timeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:TIMEOUT_INTERVAL]];
	}
}
	
/*!
 * @brief A timeout occured
 *
 * We weren't able to upload any more data after a specified duration of time.
 * Fail cleanly and let our delegate know.
 */
- (void)timeoutDidOccur
{
	[self cancel];
	[delegate uploadFailed:context];
}

/*!
 * @brief Our callback function
 *
 * Handles events which occur during the stream, as specified in the "flags".
 */
static void AIProgressDataUploaderCallback(CFReadStreamRef callbackStream,
										   CFStreamEventType type,
										   void *info)
{
	AIProgressDataUploader *uploader = (AIProgressDataUploader *)info;
	
	switch (type) {
		case kCFStreamEventHasBytesAvailable:
			[uploader bytesAvailable];
			break;
			
		case kCFStreamEventErrorOccurred:
			[uploader errorDidOccur];
			break;
			
		case kCFStreamEventEndEncountered:
			[uploader uploadSucceeded];
			break;
			
		case kCFStreamEventOpenCompleted:
		case kCFStreamEventNone:
		case kCFStreamEventCanAcceptBytes:
			break;
	}
}

/*!
 * @brief Bytes are available
 *
 * Gobble up as much from the stream as we can.
 */
- (void)bytesAvailable
{
	UInt8 buffer[BUFFER_SIZE];
	
	CFIndex read = CFReadStreamRead(stream, 
									buffer, 
									BUFFER_SIZE);
	
	if (read) {
		[returnedData appendBytes:(const void *)buffer
						   length:(NSUInteger)read];		
	}
}

/*!
 * @brief An error occured
 *
 * Let our delegate know the upload was unsuccessful.
 */
- (void)errorDidOccur
{
	[periodicTimer invalidate]; periodicTimer = nil;
	[timeoutTimer invalidate]; timeoutTimer = nil;
	
	[delegate uploadFailed:context];
}

/*!
 * @brief Upload succeeded
 *
 * Let our delegate know the unload was successful.
 */
- (void)uploadSucceeded
{
	stream = NULL;
	
	[periodicTimer invalidate]; periodicTimer = nil;
	[timeoutTimer invalidate]; timeoutTimer = nil;
	
	[delegate uploadCompleted:context result:returnedData];
}

@end
