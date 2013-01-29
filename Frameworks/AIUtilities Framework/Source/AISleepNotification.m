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

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import "AISleepNotification.h"

@interface AISleepNotification (PRIVATE)
+ (void)holdSleep:(NSNotification *)notification;
+ (void)continueSleep:(NSNotification *)notification;
@end

/*!
 * @class AISleepNotification
 * @brief Class to notify when the system goes to sleep and wakes from sleep and optionally place a hold on the sleep process.
 *
 * AISleepNotification posts (on the default NSNotificationCenter) <tt>AISystemWillSleep_Notification</tt> when the system is about to go to sleep,
 * and posts <tt>AISystemDidWake_Notification</tt> when it wakes from sleep.
 *
 * Classes may request that the sleep process be postponed by posting <tt>AISystemHoldSleep_Notification</tt>.
 * This is most useful in response to the <tt>AISystemWillSleep_Notification</tt> notification.
 * When sleep should be allowed to continue, <tt>AISystemContinueSleep_Notification</tt> should be posted.
 * At that time, if no other holders are pending, the system will go to sleep.
 * Through the use of these, a program can preemptively delay sleeping which may occur during, for example, the execution of a lengthy block of
 * code which shouldn't be interrupted, and then remove the delay when execution of the code is complete.
 */
@implementation AISleepNotification

static io_connect_t			root_port;
static int					holdSleep = 0;
static long unsigned int	waitingSleepArgument;

static void powerServiceInterestCallback(void *refcon, io_service_t y, natural_t messageType, void *messageArgument);

/*!
 * @brief Load, called when the framework is loaded
 *
 * We should not depend upon any other classes being ready when load is called.  However, we can depend on our own
 * class being ready... so we reference to force initialize being called on our superclass as well as ourself.
 */
+ (void)load
{
	[self class];
}

/*!
 * @brief Initialize sleep notifications
 *
 * Observe system power events (sleep / wake from sleep) and begin observing for hold and continue notifications.
 */
+ (void)initialize
{
	if (self != [AISleepNotification class])
		return;
	
    IONotificationPortRef	notificationPort;
    io_object_t				notifier;
	NSNotificationCenter	*defaultCenter = [NSNotificationCenter defaultCenter];

    //Observe system power events
    root_port = IORegisterForSystemPower(0, &notificationPort, powerServiceInterestCallback, &notifier);
    if (root_port) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           IONotificationPortGetRunLoopSource(notificationPort),
                           kCFRunLoopDefaultMode);
    } else {
		NSLog(@"AISleepNotification: Could not retrieve root_port from IORegisterForSystemPower(). Sleep notification disabled.");
	}

    //Observe Hold/continue sleep notification
    [defaultCenter addObserver:self 
					  selector:@selector(holdSleep:) 
						  name:AISystemHoldSleep_Notification
						object:nil];

    [defaultCenter addObserver:self 
					  selector:@selector(continueSleep:)
						  name:AISystemContinueSleep_Notification
						object:nil];
}

/*
 * @brief Hold sleep notification
 *
 * This must be balanced by the AISystemContinueSleep_Notification notification
 */
+ (void)holdSleep:(NSNotification *)notification
{
    holdSleep++;
}

/*
 * @brief Continue sleep notification
 *
 * If this balances the last AISystemHoldSleep_Notification notification, we will sleep immediately.
 * If this is sent without a preceeding AISystemHoldSleep_Notification, it is ignored.
 */
+ (void)continueSleep:(NSNotification *)notification
{
	if (holdSleep > 0) {
		holdSleep--;
		
		if (holdSleep == 0) {
			//Permit sleep now
			IOAllowPowerChange(root_port, (long)waitingSleepArgument);
		}
	}
}

/*
 * @brief Callback for sleep power events
 *
 * @param refcon The refcon passed when the notification was installed.
 * @param service The IOService whose state has changed. We only handle one IOService.
 * @param messageType A messageType enum, defined by IOKit/IOMessage.h.
 * @param messageArgument An argument for the message which we store for use when sleeping later.
 */
static void powerServiceInterestCallback(void *refcon, io_service_t service, natural_t messageType, void *messageArgument)
{
    switch ( messageType ) {
        case kIOMessageSystemWillSleep:
            //Let everyone know we will sleep
            [[NSNotificationCenter defaultCenter] postNotificationName:AISystemWillSleep_Notification object:nil];

            //If noone requested a delay, sleep now
            if (holdSleep == 0) {
                IOAllowPowerChange(root_port, (long)messageArgument);
            } else {
                waitingSleepArgument = (long unsigned int)messageArgument;
            }
                
        break;
            
        case kIOMessageCanSystemSleep:
            IOAllowPowerChange(root_port, (long)messageArgument);
        break;
            
        case kIOMessageSystemHasPoweredOn:
            //Let everyone know we awoke
            [[NSNotificationCenter defaultCenter] postNotificationName:AISystemDidWake_Notification object:nil];
        break;
    }
}

@end
