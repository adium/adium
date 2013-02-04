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

#import <Adium/AIContactControllerProtocol.h>
#import "AIContactIdlePlugin.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>

#define IDLE_UPDATE_INTERVAL	60.0

@interface AIContactIdlePlugin ()
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent;
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer;
@end

/*!
 * @class AIContactIdlePlugin
 * @brief Contact idle time updating, and idle time tooltip component
 */
@implementation AIContactIdlePlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    idleObjectArray = nil;

    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];

    //
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
    //Stop tracking all idle handles
    [idleObjectTimer invalidate];  idleObjectTimer = nil;
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Update list object
 *
 * When the idleSince property changes, we start or stop tracking the object as appropriate.
 * We track in order to have a simple number associated with the contact, updated once per minute, rather
 * than calculating the time from IdleSince until Now whenever we want to display the idle time.
 *
 * Don't calculate an idle time for a metacontact; its "idle time" should be determined dynamically based on its contained contacts.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if ((inModifiedKeys == nil || [inModifiedKeys containsObject:@"idleSince"]) &&
		![inObject isKindOfClass:[AIMetaContact class]]) {

        if ([inObject valueForProperty:@"idleSince"] != nil) {
            //Track the handle
            if (!idleObjectArray) {
                idleObjectArray = [[NSMutableArray alloc] init];
                idleObjectTimer = [NSTimer scheduledTimerWithTimeInterval:IDLE_UPDATE_INTERVAL
																	target:self 
																  selector:@selector(updateIdleObjectsTimer:)
																  userInfo:nil 
																   repeats:YES];
            }
            [idleObjectArray addObject:inObject];
			
			//Set the correct idle value
			[self setIdleForObject:inObject silent:silent];

        } else {
			if ([idleObjectArray containsObjectIdenticalTo:inObject]) {
				//Stop tracking the handle
				[idleObjectArray removeObject:inObject];
				if ([idleObjectArray count] == 0) {
					[idleObjectTimer invalidate]; idleObjectTimer = nil;
					idleObjectArray = nil;
				}
				
				//Set the correct idle value
				[self setIdleForObject:inObject silent:silent];
			}
        }
    }

    return nil;
}
        
/*!
 * @brief Updates the idle duration of all idle contacts
 */
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer
{
	//There's actually no reason to re-sort in response to these status changes, but there is no way for us to
	//let the Adium core know that.  The best we can do is delay updates so only a single sort occurs
	//of course, smart sorting controllers should be watching IdleSince, not Idle, since that's the important bit
	[[AIContactObserverManager sharedManager] delayListObjectNotifications];

	//Update everyone's idle time
	for (AIListObject *object in idleObjectArray) {
		[self setIdleForObject:object silent:YES];
	}
	
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];
}

/*!
 * @brief Give a contact its correct idle value
 */
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent
{
	NSDate		*idleSince = [inObject valueForProperty:@"idleSince"];
	NSNumber	*idleNumber = nil;
	
	if (idleSince) { //Set the handle's 'idle' value
		NSInteger	idle = (CGFloat)(-[idleSince timeIntervalSinceNow]) / 60.0f;
		
		/* They are idle; a non-zero idle time is needed.  We'll treat them as generically idle until this updates */
		if (idle == 0) {
			idle = -1;
		}

		idleNumber = [NSNumber numberWithInteger:idle];
	}

	[inObject setValue:idleNumber
					   forProperty:@"idle"
					   notify:NotifyLater];

	[inObject notifyOfChangedPropertiesSilently:silent];
}


//Tooltip entry ---------------------------------------------------------------------------------
#pragma mark Tooltip entry

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
	NSInteger 		idle = inObject.idleTime;
	NSString	*entry = nil;

	if ((idle > 599400) || (idle == -1)) { //Cap idle at 999 Hours (999*60*60 seconds)
		entry = AILocalizedString(@"Idle",nil);
	} else if (idle != 0) {
		entry = AILocalizedString(@"Idle Time",nil);
	}

	return entry;
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSInteger 				idleMinutes = [inObject integerValueForProperty:@"idle"];
    NSAttributedString	*entry = nil;

    if ((idleMinutes > 599400) || (idleMinutes == -1)) { //Cap idle at 999 Hours (999*60 minutes)
		entry = [[NSAttributedString alloc] initWithString:AILocalizedString(@"Yes",nil)];
		
    } else if (idleMinutes != 0) {
		entry = [[NSAttributedString alloc] initWithString:[NSDateFormatter stringForTimeInterval:(idleMinutes * 60.0)]];    
	}

    return entry;
}

- (BOOL)shouldDisplayInContactInspector
{
	/* Accounts should be including this information in the profile already */
	return NO;
}

@end
