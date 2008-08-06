/*
 *  NDRunLoopMessenger.m
 *  RunLoopMessenger
 *
 *  Created by Nathan Day on Fri Feb 08 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 *  Changes to add a silly number of withObject: options to target:performSelector: and to queue messages instead of threadlocking
 *		by Evan Schoenberg.
 */

#import <Adium/NDRunLoopMessenger.h>

#define DEFAULT_PORT_MESSAGE_RETRY_TIMEOUT  0.5
#define DEFAULT_PORT_MESSAGE_RETRY			0.01

static NSString		* kThreadDictionaryKey = @"NDRunLoopMessengerInstance";

NSString		* kSendMessageException = @"NDRunLoopMessengerSendException";
NSString		* kConnectionDoesNotExistsException = @"NDRunLoopMessengerConnectionNoLongerExistsException";

/*
 * struct message
 */
struct message
{
	NSConditionLock		* resultLock;
	NSInvocation		* invocation;
};

/*
 * interface NDRunLoopMessengerForwardingProxy
 */
@interface NDRunLoopMessengerForwardingProxy : NSProxy
{
	id								targetObject;
	NDRunLoopMessenger				* owner;
	BOOL							withResult;
}
- (id)_initWithTarget:(id)aTarget withOwner:(NDRunLoopMessenger *)anOwner withResult:(BOOL)aFlag;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
@end

@interface NDRunLoopMessengerForwardingProxyFromNoRunLoop : NDRunLoopMessengerForwardingProxy {}
@end

/*
 * interface NDRunLoopMessenger
 */
@interface NDRunLoopMessenger (Private)
- (void)createPortForRunLoop:(NSRunLoop *)aRunLoop;
- (void)registerNotificationObservers;
- (void)sendData:(NSData *)aData;
@end

/*
 * class NDRunLoopMessenger
 */
@implementation NDRunLoopMessenger


/*
 * +runLoopMessengerForThread
 */
+ (NDRunLoopMessenger *)runLoopMessengerForThread:(NSThread *)aThread
{
	return [[aThread threadDictionary] objectForKey:kThreadDictionaryKey];
}

/*
 * +runLoopMessengerForCurrentRunLoop
 */
+ (id)runLoopMessengerForCurrentRunLoop
{
	NDRunLoopMessenger		* theCurentRunLoopMessenger;
	
	theCurentRunLoopMessenger = [self runLoopMessengerForThread:[NSThread currentThread]];
	if ( theCurentRunLoopMessenger == nil )
		theCurentRunLoopMessenger = [[NDRunLoopMessenger alloc] init];

	return theCurentRunLoopMessenger;
}

/*
 * init
  */
- (id)init
{
	if ((self = [super init]))
	{
		NSMutableDictionary		* theThreadDictionary;
		id						theOneForThisThread;

		messageRetryTimeout = DEFAULT_PORT_MESSAGE_RETRY_TIMEOUT;
		messageRetry = DEFAULT_PORT_MESSAGE_RETRY;
		
		theThreadDictionary = [[NSThread currentThread] threadDictionary];
		if ((theOneForThisThread = [theThreadDictionary objectForKey:kThreadDictionaryKey]))
		{
			[self release];
			self = theOneForThisThread;
		}
		else
		{
			queuedPortMessageArray = nil;
			queuedPortMessageTimer = nil;
			targetRunLoop = [[NSRunLoop currentRunLoop] retain];
			
			[self createPortForRunLoop:targetRunLoop];
			[theThreadDictionary setObject:self forKey:kThreadDictionaryKey];
			[self registerNotificationObservers];
		}
	}

	return self;
}

/*
 * registerNotificationObservers
  */
- (void)registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portDidBecomeInvalid:) name:NSPortDidBecomeInvalidNotification object:port];
}

/*
 * dealloc
  */
- (void)dealloc
{
	[targetRunLoop release]; targetRunLoop = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
	[port removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[port release];
	[super dealloc];
}

- (void)setMessageRetryTimeout:(NSTimeInterval)inMessageRetryTimeout
{
	messageRetryTimeout = inMessageRetryTimeout;
}

- (void)setMessageRetry:(NSTimeInterval)inMessageRetry
{
	messageRetry = inMessageRetry;
}
/*
 * threadWillExit:
  */
- (void)threadWillExit:(NSNotification *)notification
{
	NSThread		* thread = [notification object];

	if ( [[thread threadDictionary] objectForKey:kThreadDictionaryKey] == self )
	{
		[[thread threadDictionary] removeObjectForKey:kThreadDictionaryKey];
		[port removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		port = nil;
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
}

/*
 * portDidBecomeInvalid:
  */
- (void)portDidBecomeInvalid:(NSNotification *)notification
{
	if ( [notification object] == port )
	{
		[[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
		[port removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		port = nil;
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		NSAssert(FALSE,@"portDidBecomeInvalid!");
	}
}

/*
 * target:performSelector:
  */
- (void)target:(id)aTarget performSelector:(SEL)aSelector
{
	[self target:aTarget performSelector:aSelector withResult:NO];
}

/*
 * target:selector:withObject:
  */
- (void)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject
{
	[self target:aTarget performSelector:aSelector withObject:anObject withResult:NO];
}

/*
 * target:performSelector:withObject:withObject:
  */
- (void)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
	[self target:aTarget performSelector:aSelector withObject:anObject withObject:anotherObject withResult:NO];

}

- (void)target:(id)aTarget
 performSelector:(SEL)aSelector
	withObject:(id)anObject
	withObject:(id)anotherObject
	withObject:(id)aThirdObject;
{
	[self target:aTarget
 performSelector:aSelector
	  withObject:anObject
	  withObject:anotherObject
	  withObject:aThirdObject
	  withResult:NO];
	
}

- (void)target:(id)aTarget
 performSelector:(SEL)aSelector
	withObject:(id)anObject
	withObject:(id)anotherObject
	withObject:(id)aThirdObject
	withObject:(id)aFourthObject;
{
	[self target:aTarget
 performSelector:aSelector 
	  withObject:anObject 
	  withObject:anotherObject
	  withObject:aThirdObject
	  withObject:aFourthObject
	  withResult:NO];
	
}

- (void)target:(id)aTarget
 performSelector:(SEL)aSelector
	withObject:(id)anObject
	withObject:(id)anotherObject
	withObject:(id)aThirdObject
	withObject:(id)aFourthObject
	withObject:(id)aFifthObject;
{
	[self target:aTarget
 performSelector:aSelector 
	  withObject:anObject 
	  withObject:anotherObject
	  withObject:aThirdObject
	  withObject:aFourthObject
	  withObject:aFifthObject
	  withResult:NO];
	
}

/*
 * target:performSelector:withResult:
  */
- (id)target:(id)aTarget performSelector:(SEL)aSelector withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;

	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];

	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[self messageInvocation: theInvocation withResult:aFlag];

	if ( aFlag )
		[theInvocation getReturnValue:&theResult];

	return theResult;
}

/*
 * target:performSelector:withObject:withResult:
  */
- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;

	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];

	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[theInvocation setArgument:&anObject atIndex:2];
	[self messageInvocation: theInvocation withResult:aFlag];

	if ( aFlag )
		[theInvocation getReturnValue:&theResult];

	return theResult;
}

/*
 * target:performSelector:withObject:withObject:withResult:
  */
- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;

	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];

	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[theInvocation setArgument:&anObject atIndex:2];
	[theInvocation setArgument:&anotherObject atIndex:3];
	[self messageInvocation:theInvocation withResult:aFlag];

	if ( aFlag )
		[theInvocation getReturnValue:&theResult];
	
	return theResult;
}

/*
 * target:performSelector:withObject:withObject:withObject:withResult:
  */
- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;
	
	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];
	
	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[theInvocation setArgument:&anObject atIndex:2];
	[theInvocation setArgument:&anotherObject atIndex:3];
	[theInvocation setArgument:&aThirdObject atIndex:4];
	[self messageInvocation:theInvocation withResult:aFlag];
	
	if ( aFlag )
		[theInvocation getReturnValue:&theResult];
	
	return theResult;
}

- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject withObject:(id)aFifthObject withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;
	
	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];
	
	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[theInvocation setArgument:&anObject atIndex:2];
	[theInvocation setArgument:&anotherObject atIndex:3];
	[theInvocation setArgument:&aThirdObject atIndex:4];
	[theInvocation setArgument:&aFourthObject atIndex:5];
	[theInvocation setArgument:&aFifthObject atIndex:6];
	[self messageInvocation:theInvocation withResult:aFlag];
	
	if ( aFlag )
		[theInvocation getReturnValue:&theResult];
	
	return theResult;
}

- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject withResult:(BOOL)aFlag
{
	NSInvocation		* theInvocation;
	id						theResult = nil;
	
	theInvocation = [NSInvocation invocationWithMethodSignature:[aTarget methodSignatureForSelector:aSelector]];
	
	[theInvocation setSelector:aSelector];
	[theInvocation setTarget:aTarget];
	[theInvocation setArgument:&anObject atIndex:2];
	[theInvocation setArgument:&anotherObject atIndex:3];
	[theInvocation setArgument:&aThirdObject atIndex:4];
	[theInvocation setArgument:&aFourthObject atIndex:5];
	[self messageInvocation:theInvocation withResult:aFlag];
	
	if ( aFlag )
		[theInvocation getReturnValue:&theResult];
	
	return theResult;
}

/*
 * messageInvocation:
  */
- (void)postNotification:(NSNotification *)aNotification
{
	NSInvocation		* theInvocation;

	theInvocation = [NSInvocation invocationWithMethodSignature:[NSNotificationCenter instanceMethodSignatureForSelector:@selector(postNotification:)]];

	[theInvocation setSelector:@selector(postNotification:)];
	[theInvocation setTarget:[NSNotificationCenter defaultCenter]];
	[theInvocation setArgument:&aNotification atIndex:2];
	[self messageInvocation:theInvocation withResult:NO];
}

/*
 * messageInvocation:object:
  */
- (void)postNotificationName:(NSString *)aNotificationName object:(id)anObject
{
	[self postNotification:[NSNotification notificationWithName:aNotificationName object:anObject]];
}

/*
 * postNotificationName:object:userInfo:
  */
- (void)postNotificationName:(NSString *)aNotificationName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
	[self postNotification:[NSNotification notificationWithName:aNotificationName object:anObject userInfo:aUserInfo]];
}

/*
 * messageInvocation:
  */
- (void)messageInvocation:(NSInvocation *)anInvocation withResult:(BOOL)aResultFlag
{
	struct message		* theMessage;
	NSMutableData		* theData;

	[anInvocation retainArguments];

	theData = [NSMutableData dataWithLength:sizeof(struct message)];
	theMessage = (struct message *)[theData mutableBytes];

	theMessage->invocation = [anInvocation retain];		// will be released by handlePortMessage
	theMessage->resultLock = aResultFlag ? [[NSConditionLock alloc] initWithCondition:NO] : nil;
	[self sendData:theData];

	if ( aResultFlag )
	{
		[theMessage->resultLock lockWhenCondition:YES];
		[theMessage->resultLock unlock];
		[theMessage->resultLock release];
	}
}

/*
 * target:
  */
- (id)target:(id)aTarget;
{
	return [[[NDRunLoopMessengerForwardingProxy alloc] _initWithTarget:aTarget withOwner:self withResult:NO] autorelease];
}

/*
 * target:withResult:
  */
- (id)target:(id)aTarget withResult:(BOOL)aResultFlag;
{
	return [[[NDRunLoopMessengerForwardingProxy alloc] _initWithTarget:aTarget withOwner:self withResult:aResultFlag] autorelease];
}

- (id)targetFromNoRunLoop:(id)aTarget;
{
	return [[[NDRunLoopMessengerForwardingProxyFromNoRunLoop alloc] _initWithTarget:aTarget withOwner:self withResult:NO] autorelease];
}

/*
 * handlePortMessage:
  */
- (void)handlePortMessage:(NSPortMessage *)aPortMessage
{
	struct message 	* theMessage;
	NSData			* theData;
	void			handlePerformSelectorMessage( struct message * aMessage );
	void			handleInvocationMessage( struct message * aMessage );

	theData = [[aPortMessage components] lastObject];
	
	theMessage = (struct message *)[theData bytes];
	insideMessageInvocation = YES;
	[theMessage->invocation invoke];
	
	if ( theMessage->resultLock )
	{
		[theMessage->resultLock lock];
		[theMessage->resultLock unlockWithCondition:YES];
	}
	insideMessageInvocation = NO;	
	[theMessage->invocation release];	// to balance messageInvocation:withResult:
}

/*
 * createPortForRunLoop:
  */
- (void)createPortForRunLoop:(NSRunLoop *)aRunLoop
{
	port = [NSPort port];
	[port setDelegate:self];
	[port scheduleInRunLoop:aRunLoop forMode:NSDefaultRunLoopMode];
}

/*
 * sendData
  */
- (void)sendData:(NSData *)aData
{
	NSPortMessage		* thePortMessage;

	if ( port )
	{
		thePortMessage = [[NSPortMessage alloc] initWithSendPort:port receivePort:nil components:[NSArray arrayWithObject:aData]];
		
		//Ensure that messages are delivered in the order sent, so if we have queued messages, queue this new mesage, too
		if (queuedPortMessageTimer) {
			@synchronized(self) {
				if (!queuedPortMessageArray) {
					queuedPortMessageArray = [[NSMutableArray alloc] init];
				}
				[queuedPortMessageArray addObject:thePortMessage];
			}

		} else {
			NSDate	* sendBeforeDate = (messageRetryTimeout ? 
										[NSDate dateWithTimeIntervalSinceNow:messageRetryTimeout] :
										[NSDate distantFuture]);
			if ( ![thePortMessage sendBeforeDate:sendBeforeDate] ) {
				//If the message can't be sent before the timeout, add it to a queue array and ensure a timer is firing to send it later
				@synchronized(self) {
					if (!queuedPortMessageArray) {
						queuedPortMessageArray = [[NSMutableArray alloc] init];
					}
					[queuedPortMessageArray addObject:thePortMessage];
				
					if (!queuedPortMessageTimer) {
						queuedPortMessageTimer = [[NSTimer scheduledTimerWithTimeInterval:messageRetry
																				   target:self 
																				 selector:@selector(sendQueuedDataTimer:) 
																				 userInfo:nil 
																				  repeats:YES] retain];
					}
				}
			}
		}
		
		[thePortMessage release];
	}
	else
	{
		[NSException raise:kConnectionDoesNotExistsException format:@"The connection to the runLoop does not exist"];
	}
}

//Send the first item in the queue, or destroy the queue and timer if the queue is empty
- (void)sendQueuedDataTimer:(NSTimer *)inTimer
{
	//If we are inside a message invocation, do nothing; we'll be given another shot when the timer fires again
	if (!insideMessageInvocation) {
		BOOL haveQueuedMessages;
		@synchronized(self) {
			 haveQueuedMessages = ([queuedPortMessageArray count] > 0);
		}
			
		if (haveQueuedMessages) {
			NSPortMessage	*thePortMessage;
			
			@synchronized(self) {
				//Keep it around for us
				thePortMessage = [[queuedPortMessageArray objectAtIndex:0] retain];
				//And remove it from our queue array so the next dequeue will get a new NSPortMessage
				[queuedPortMessageArray removeObjectAtIndex:0];
			}
			NSDate			*sendBeforeDate = (messageRetryTimeout ? 
											   [NSDate dateWithTimeIntervalSinceNow:messageRetryTimeout] :
											   [NSDate distantFuture]);
			
			if (![thePortMessage sendBeforeDate:sendBeforeDate]) {
				@synchronized(self) {
					[queuedPortMessageArray insertObject:thePortMessage
												 atIndex:0];
				}
			}

			[thePortMessage release];
			
		} else {
			@synchronized(self) {
				[queuedPortMessageArray release]; queuedPortMessageArray = nil;
				[queuedPortMessageTimer invalidate]; [queuedPortMessageTimer release]; queuedPortMessageTimer = nil;
			}
		}
	}
}

- (NSRunLoop *)targetRunLoop
{
	return targetRunLoop;
}

@end

/*
 * class NDRunLoopMessengerForwardingProxy
 */
@implementation NDRunLoopMessengerForwardingProxy

/*
 * _initWithTarget:withOwner:withResult:
  */
- (id)_initWithTarget:(id)aTarget withOwner:(NDRunLoopMessenger *)anOwner withResult:(BOOL)aFlag
{
	if ( aTarget && anOwner )
	{
		targetObject = [aTarget retain];
		owner = [anOwner retain];
		withResult = aFlag;
	}
	else
	{
		[self release];
		self = nil;
	}

	return self;
}

/*
 * dealloc
  */
- (void)dealloc
{
	[targetObject release];
	[owner release];
	
	[super dealloc];
}

/*
 * forwardInvocation:
  */
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation setTarget:targetObject];
	[owner messageInvocation:anInvocation withResult:withResult];
}

/*
 * methodSignatureForSelector:
  */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [[targetObject class] instanceMethodSignatureForSelector:aSelector];
}

@end

/*
 * class NDRunLoopMessengerForwardingProxy
 */
@implementation NDRunLoopMessengerForwardingProxyFromNoRunLoop
/*
 * forwardInvocation:
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if ([owner targetRunLoop] != [NSRunLoop currentRunLoop]) {
		[super forwardInvocation:anInvocation];
		if (![[NSRunLoop currentRunLoop] currentMode]) [[NSRunLoop currentRunLoop] run];

	} else {
		[anInvocation setTarget:targetObject];
		[anInvocation invoke];
	}
}

@end
