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
#import "ESAccountEvents.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>

#define ACCOUNT_CONNECTION_STATUS_GROUPING  4.0

@interface ESAccountEvents ()
- (void)accountConnection:(NSTimer *)timer;
- (void)accountDisconnection:(NSTimer *)timer;
@end


/*!
 * @class ESAccountEvents
 * @brief Component to handle account-related Contact Alerts events
 */
@implementation ESAccountEvents

/*!
 * @brief Install
 */
- (void)installPlugin
{
	accountConnectionStatusGroupingOnlineTimer = nil;
	accountConnectionStatusGroupingOfflineTimer = nil;
	
	//Register the events we generate
	[adium.contactAlertsController registerEventID:ACCOUNT_CONNECTED withHandler:self inGroup:AIAccountsEventHandlerGroup globalOnly:YES];
	[adium.contactAlertsController registerEventID:ACCOUNT_DISCONNECTED withHandler:self inGroup:AIAccountsEventHandlerGroup globalOnly:YES];
	[adium.contactAlertsController registerEventID:ACCOUNT_RECEIVED_EMAIL withHandler:self inGroup:AIOtherEventHandlerGroup globalOnly:YES];

	//Observe status changes
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Short description for an event
 *
 * We're global-only, so no short descriptions are needed.
 */
- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

/*!
 * @brief Global short description for an event
 */
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
		description = AILocalizedString(@"You connect",nil);
	} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
		description = AILocalizedString(@"You disconnect",nil);
	} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
		description = AILocalizedString(@"New email notification",nil);
	} else {
		description = @"";	
	}
	
	return description;
}

/*!
 * @brief English, non-translated global short description for an event
 *
 * This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
 * a converter for old packs.  If anyone wants to fix this situation, please feel free :)
 *
 * @result English global short description which should only be used internally
 */
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
		description = @"Connected";
	} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
		description = @"Disconnected";
	} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
		description = @"New Mail Received";
	} else {
		description = @"";	
	}
	
	return description;
}

/*!
 * @brief Long description for an event
 */
- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description;
	
	if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
		description = AILocalizedString(@"When you connect",nil);
	} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
		description = AILocalizedString(@"When you disconnect",nil);
	} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
		description = AILocalizedString(@"When you receive a new email notification",nil);
	} else {
		description = @"";
	}
	
	return description;
}

/*!
 * @brief Natural language description for an event
 *
 * @param eventID The event identifier
 * @param listObject The listObject triggering the event
 * @param userInfo Event-specific userInfo
 * @param includeSubject If YES, return a full sentence.  If not, return a fragment.
 * @result The natural language description.
 */
- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString	*description = nil;
	
	if (includeSubject) {
		NSString	*format = nil;
		if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
			format = AILocalizedString(@"%@ connected",nil);
		} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
			format = AILocalizedString(@"%@ disconnected",nil);
		} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
			format = AILocalizedString(@"%@ received new email",nil);
		}
		
		if (format) {
			description = [NSString stringWithFormat:format,listObject.formattedUID];
		}
	} else {
		if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
			description = AILocalizedString(@"connected",nil);
		} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
			description = AILocalizedString(@"disconnected",nil);
		} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
			if (userInfo && [userInfo isKindOfClass:[NSString class]]) {
				description = [[(NSString *)userInfo copy] autorelease];

			} else {
				description = AILocalizedString(@"received new email",nil);
			}
		}
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [[NSImage imageNamed:@"pref-accounts" forClass:[self class]] retain];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	NSString *format = nil;
	
	if ([eventID isEqualToString:ACCOUNT_CONNECTED]) {
		format = AILocalizedString(@"%u accounts connected",nil);
	} else if ([eventID isEqualToString:ACCOUNT_DISCONNECTED]) {
		format = AILocalizedString(@"%u accounts disconnected",nil);
	} else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]) {
		format = AILocalizedString(@"%u accounts received new email",nil);
	}
	
	return format ? [NSString stringWithFormat:format, count] : @"";
}

#pragma mark Aggregation and event generation
/*!
 * @brief Update list object
 *
 * We aggregate account connection events to avoid a quick sign on/sign off from triggering the event
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) { //We only care about accounts
		if ([inModifiedKeys containsObject:@"isOnline"]) {
			
			if ([inObject boolValueForProperty:@"isOnline"]) {
				if (accountConnectionStatusGroupingOnlineTimer) {
					[accountConnectionStatusGroupingOnlineTimer invalidate]; [accountConnectionStatusGroupingOnlineTimer release];
				}
				
				accountConnectionStatusGroupingOnlineTimer = [[NSTimer scheduledTimerWithTimeInterval:ACCOUNT_CONNECTION_STATUS_GROUPING
																							   target:self
																							 selector:@selector(accountConnection:)
																							 userInfo:inObject
																							  repeats:NO] retain];
			} else {
				if (accountConnectionStatusGroupingOfflineTimer) {
					[accountConnectionStatusGroupingOfflineTimer invalidate]; [accountConnectionStatusGroupingOfflineTimer release];
				}
				
				accountConnectionStatusGroupingOfflineTimer = [[NSTimer scheduledTimerWithTimeInterval:ACCOUNT_CONNECTION_STATUS_GROUPING
																								target:self
																							  selector:@selector(accountDisconnection:)
																							  userInfo:inObject
																							   repeats:NO] retain];
			}
		}
	}
	
	return nil;	
}

/*!
 * @brief Called an account connects and remains online for ACCOUNT_CONNECTION_STATUS_GROUPING
 */
- (void)accountConnection:(NSTimer *)timer
{
	[adium.contactAlertsController generateEvent:ACCOUNT_CONNECTED
									 forListObject:[timer userInfo]
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	[accountConnectionStatusGroupingOnlineTimer release]; accountConnectionStatusGroupingOnlineTimer = nil;
}

/*!
 * @brief Called an account disconnects and remains offline for ACCOUNT_CONNECTION_STATUS_GROUPING
 */
- (void)accountDisconnection:(NSTimer *)timer
{
	[adium.contactAlertsController generateEvent:ACCOUNT_DISCONNECTED
									 forListObject:[timer userInfo]
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	[accountConnectionStatusGroupingOfflineTimer release]; accountConnectionStatusGroupingOfflineTimer = nil;
}

@end
