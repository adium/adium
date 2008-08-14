//
//  AdiumIdleManager.m
//  Adium
//
//  Created by Evan Schoenberg on 7/5/05.
//

#import "AdiumIdleManager.h"
#import "AIStatusController.h"

#define MACHINE_IDLE_THRESHOLD			30 	//30 seconds of inactivity is considered idle
#define MACHINE_ACTIVE_POLL_INTERVAL	30	//Poll every 30 seconds when the user is active
#define MACHINE_IDLE_POLL_INTERVAL		1	//Poll every second when the user is idle

//Private idle function
extern CFTimeInterval CGSSecondsSinceLastInputEvent(unsigned long evType);

@interface AdiumIdleManager ()
- (void)_setMachineIsIdle:(BOOL)inIdle;
- (void)screenSaverDidStart;
- (void)screenSaverDidStop;
@end

/*!
 * @class AdiumIdleManager
 * @brief Core class to manage sending notifications when the system is idle or no longe ridle
 *
 * Posts AIMachineIsIdleNotification to adium's notification center when the machine becomes idle.
 * Posts AIMachineIsActiveNotification when the machine is no longer idle
 * Posts AIMachineIdleUpdateNotification periodically while idle with an NSDictionary userInfo
 *		containing an NSNumber double value @"Duration" (a CFTimeInterval) and an NSDate @"IdleSince".
 */
@implementation AdiumIdleManager

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		[self _setMachineIsIdle:NO];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(screenSaverDidStart)
																name:@"com.apple.screensaver.didstart"
															  object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(screenSaverDidStop)
																name:@"com.apple.screensaver.didstop"
															  object:nil];
	}
	
	return self;
}

/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle.  The machine is idle when there are no input
 * events from the user (such as mouse movement or keyboard input) or when the screen saver is active.
 * In addition to this method, the status controller sends out notifications when the machine becomes idle,
 * stays idle, and returns to an active state.
 */
- (CFTimeInterval)currentMachineIdle
{
	CFTimeInterval idleTime;

	/* CGSSecondsSinceLastInputEvent is a private function available in 10.2 and later. Note that CGEventSourceSecondsSinceLastEventType()
	 * should work as of 10.4 but doesn't return a sensical value.
	 */
	idleTime = CGSSecondsSinceLastInputEvent(-1);
	
	/* On MDD Powermacs, the above function will return a large value when the machine is active (perhaps a -1?).
	 * Here we check for that value and correctly return a 0 idle time.
	 */
	if (idleTime >= 18446744000.0) idleTime = 0.0; //18446744073.0 is the lowest I've seen on my MDD -ai		
	
    return idleTime;
}

/*!
 * @brief Timer that checkes for machine idle
 *
 * This timer periodically checks the machine for inactivity.  When the machine has been inactive for atleast
 * MACHINE_IDLE_THRESHOLD seconds, a notification is broadcast.
 *
 * When the machine is active, this timer is called infrequently.  It's not important to notice that the user went
 * idle immediately, so we relax our CPU usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently.  It's important to notice immediately when the user
 * returns.
 */
- (void)_idleCheckTimer:(NSTimer *)inTimer
{
	CFTimeInterval	currentIdle = [self currentMachineIdle];
	
	if (machineIsIdle) {
		if (currentIdle < lastSeenIdle) {
			/* If the machine is less idle than the last time we recorded, it means that activity has occured and the
			* user is no longer idle.
			*/
			[self _setMachineIsIdle:NO];
		} else {
			//Periodically broadcast a 'MachineIdleUpdate' notification
			[[adium notificationCenter] postNotificationName:AIMachineIdleUpdateNotification
													  object:nil
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithDouble:currentIdle], @"Duration",
														[NSDate dateWithTimeIntervalSinceNow:-currentIdle], @"IdleSince",
														nil]];
		}
	} else {
		//If machine inactivity is over the threshold, the user has gone idle.
		if (currentIdle > MACHINE_IDLE_THRESHOLD) [self _setMachineIsIdle:YES];
	}
	
	lastSeenIdle = currentIdle;
}

/*!
 * @brief Sets the machine as idle or not
 *
 * This internal method updates the frequency of our idle timer depending on whether the machine is considered
 * idle or not.  It also posts the AIMachineIsIdleNotification and AIMachineIsActiveNotification notifications
 * based on the passed idle state
 */
- (void)_setMachineIsIdle:(BOOL)inIdle
{
	machineIsIdle = inIdle;
	
	//Post the appropriate idle or active notification
	if (machineIsIdle) {
		[[adium notificationCenter] postNotificationName:AIMachineIsIdleNotification object:nil];
	} else {
		[[adium notificationCenter] postNotificationName:AIMachineIsActiveNotification object:nil];
	}
	
	//Update our timer interval for either idle or active polling
	[idleTimer invalidate];
	[idleTimer release];
	idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(machineIsIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL)
												  target:self
												selector:@selector(_idleCheckTimer:)
												userInfo:nil
												 repeats:YES] retain];
}

/*!
 * @brief Called by the screen saver when it starts
 *
 * When the screen saver starts, we set ourself to idle.
 */
- (void)screenSaverDidStart
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self _setMachineIsIdle:YES];
	[pool release];
}

/*!
 * @brief Called by the screen saver when it starts
 *
 * When the screen saver stops, we set ourself to active.
 */
- (void)screenSaverDidStop
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self _setMachineIsIdle:NO];
	[pool release];
}


@end
