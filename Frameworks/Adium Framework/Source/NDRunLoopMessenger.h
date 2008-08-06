/*!
 * @file NDRunLoopMessenger.h
 *
 * @brief Defines the class @c NDRunLoopMessenger
 *
 * @c NDRunLoopMessenger provides a light weight version of distributed objects
 * that only works between threads within the same process. With the advent of
 * Mac OS 10.2 the need for this class has decreased with the introduction of
 * the methods <tt>-[NSObject performSelectorOnMainThread:withObject:waitUntilDone:]</tt>
 * and <tt>-[NSObject performSelectorOnMainThread:withObject:waitUntilDone:modes:]</tt>
 * but it is still useful.
 *
 * @author Nathan Day Copyright &copy; 2002-2003 Nathan Day. All rights reserved.
 * @date Fri Feb 08 2002
 */

/*!
 * @brief <tt>NDRunLoopMessenger</tt> exception
 *
 * An exception that can be thrown when sending a message by means of
 * @c NDRunLoopMessenger. This includes any messages forwarded by the proxy
 * returned from the methods <tt>target:</tt> and <tt>target:withResult:</tt>.
 */
extern NSString *kSendMessageException;

/*!
 * @brief <tt>NDRunLoopMessenger</tt> exception
 *
 * An exception that can be thrown when sending a message by means of
 * <tt>NDRunLoopMessenger</tt>. This includes any messages forwarded by the
 * proxy returned from the methods <tt>target:</tt> and <tt>target:withResult:</tt>.
 */
extern NSString *kConnectionDoesNotExistsException;

/*!
 * @brief Class to provide thread intercommunication
 *
 * A light weight version of distributed objects that only works between threads
 * within the same process. @c NDRunLoopMessenger works by only passing
 * the address of a @c NSInvocation object through a run loop port, this is all
 * that is needed since the object is already within the same process memory space.
 * This means that all the parameters do not need to be serialized. Results are
 * returned simply by waiting on a lock for a message result to be put into the
 * @c NSInvocation.
 */
@interface NDRunLoopMessenger : NSObject
{
@private
	NSPort			* port;
	NSMutableArray  * queuedPortMessageArray;
	NSTimer			* queuedPortMessageTimer;
	NSRunLoop		* targetRunLoop;
	BOOL			insideMessageInvocation;
	
	NSTimeInterval  messageRetryTimeout;
	NSTimeInterval  messageRetry;
}

/*!
 * @brief Get the @c NDRunLoopMessenger for a thread.
 *
 * If the thread does not have a @c NDRunLoopMessenger then @c nil is returned.
 * 
 * @param thread The thread.
 * @return The @c NDRunLoopMessenger for the specified thread.
 */
+ (NDRunLoopMessenger *)runLoopMessengerForThread:(NSThread *)thread;

/*!
 * @brief Returns the @c NDRunLoopMessenger for the current run loop.
 *
 * If a @c NDRunLoopMessenger has been created for the current run loop then
 * @c runLoopMessengerForCurrentRunLoop will return it otherwise it will
 * create one.
 *
 * @return A @c NDRunLoopMessenger object for the current run loop.
 */
+ (id)runLoopMessengerForCurrentRunLoop;

/*!
 * @brief Perform a selector.
 *
 * Send a message to the suplied target without waiting for the message to be processed.
 *
 * @param target The target object.
 * @param selector The selector that should be performed on the target object.
 */
- (void)target:(id)target performSelector:(SEL)selector;

/*!
 * @brief Perform a selector.
 *
 * Send a message with one object paramter to the suplied target without waiting for
 * the message to be processed.
 *
 * @param target The target object.
 * @param selector The message selector.
 * @param object An object to be passed with the message.
 */
- (void)target:(id)target performSelector:(SEL)selector withObject:(id)object;

/*!
 * @brief Perform a selector.
 *
 * Send a message with two object paramters to the suplied target without waiting
 * for the message to be processed.
 *
 * @param target The target object.
 * @param selector The message selector.
 * @param object The first object to be passed with the message.
 * @param anotherObject The second object to be passed with the message.
 */
- (void)target:(id)target performSelector:(SEL)selector withObject:(id)object withObject:(id)anotherObject;

- (void)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject;

- (void)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject;

- (void)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject withObject:(id)aFifthObject;

/*!
 * @brief Perform a selector.
 *
 * Send a message to the suplied target, the result can be waited for.
 *
 * @param target The target object.
 * @param selector The message selector.
 * @param resultFlag Should the result be waited for and returned.
 * @return The message result if @c resultFlag is @c YES, or @c nil if
 *   @c resultFlag is @c NO.
 */
- (id)target:(id)target performSelector:(SEL)selector withResult:(BOOL)resultFlag;

/*!
 * @brief Perform a selector.
 *
 * Send a message with one object paramter to the suplied target, the result can be
 * waited for.
 *
 * @param target The target object.
 * @param selector The message selector.
 * @param object An object to be passed with the message.
 * @param resultFlag Should the result be waited for and returned.
 * @return The message result if @c resultFlag is @c YES, or @c nil if
 *   @c resultFlag is @c NO.
 */
- (id)target:(id)target performSelector:(SEL)selector withObject:(id)object withResult:(BOOL)resultFlag;

/*!
 * @brief Perform a selector.
 *
 * Send a message with two object paramters to the suplied target, the result can be
 * waited for.
 *
 * @param target The target object.
 * @param selector The message selector.
 * @param object The first object to be passed with the message.
 * @param anotherObject The second object to be passed with the message.
 * @param resultFlag Should the result be waited for and returned.
 * @return The message result if @c resultFlag is @c YES, or @c nil if
 *   @c resultFlag is @c NO.
 */
- (id)target:(id)target performSelector:(SEL)selector withObject:(id)object withObject:(id)anotherObject withResult:(BOOL)resultFlag;

- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withResult:(BOOL)aFlag;

- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject withResult:(BOOL)aFlag;

- (id)target:(id)aTarget performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject withObject:(id)aThirdObject withObject:(id)aFourthObject withObject:(id)aFifthObject withResult:(BOOL)aFlag;
	
/*!
 * @brief Post a notification.
 *
 * Posts the supplied @c NSNotification object within the receivers run loop.
 *
 * @param notification A @c NSNotification object to be posted.
 */
- (void)postNotification:(NSNotification *)notification;

/*!
 * @brief Post a notification.
 *
 * Posts the notification of a supplied name and object within the receivers run loop.
 *
 * @param notificationName The notification name.
 * @param object The object to be posted with the notification.
 * @see @c NSNotification documentation to get more information about the parameters.
 */
- (void)postNotificationName:(NSString *)notificationName object:(id)object;

/*!
 * @brief Post a notification.
 *
 * Posts the notification of a supplied name, object and uder info within the receivers
 * run loop.
 *
 * @param notificationName The notification name.
 * @param object The object to be posted with the notification.
 * @param userInfo A @c NSDictionary of user info.
 * @see @c NSNotification documentation to get more information about the parameters.
 */
- (void)postNotificationName:(NSString *)notificationName object:(id)object userInfo:(NSDictionary *)userInfo;

/*!
 * @brief Invoke and invocation.
 *
 * Invokes the passed in @c NSInvocation within the receivers run loop.
 *
 * @param invocation The @c NSInvocation
 * @param resultFlag Should the result be waited for and returned.
 * @return The invocation result if @c resultFlag is @c YES, or @c nil if
 *   @c resultFlag is @c NO.
 */
- (void)messageInvocation:(NSInvocation *)invocation withResult:(BOOL)resultFlag;

/*!
 * @brief Get a target proxy.
 *
 * Returns a object that acts as a proxy, forwarding all messages it receives to the
 * supplied target. All messages sent to the target return immediately without waiting
 * for the result.
 *
 * @param target The target object.
 * @return The proxy object.
 */
- (id)target:(id)target;

/*!
 * @brief Get a target proxy.
 *
 * Returns a object that acts as a proxy, forwarding all messages it receives to the
 * supplied target.
 *
 * @param target The target object.
 * @param resultFlag Should all results be waited for and returned.
 * @return The proxy object.
 */
- (id)target:(id)target withResult:(BOOL)resultFlag;

- (id)targetFromNoRunLoop:(id)aTarget;

- (void)setMessageRetryTimeout:(NSTimeInterval)inMessageRetryTimeout;
- (void)setMessageRetry:(NSTimeInterval)inMessageRetry;

- (NSRunLoop *)targetRunLoop;

@end
