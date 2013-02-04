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
#import "AIContactStatusEventsPlugin.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>

@interface AIContactStatusEventsPlugin ()
- (BOOL)updateCache:(NSMutableDictionary *)cache
			forKey:(NSString *)key
		  newValue:(id)newStatus
		listObject:(AIListObject *)inObject
	performCompare:(BOOL)performCompare;
@end

/*!
 * @class AIContactStatusEventsPlugin
 * @brief Component to provide events for contact status changes (online, offline, away, idle, etc.)
 */
@implementation AIContactStatusEventsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//
    onlineCache = [[NSMutableDictionary alloc] init];
    awayCache = [[NSMutableDictionary alloc] init];
    idleCache = [[NSMutableDictionary alloc] init];
	statusMessageCache = [[NSMutableDictionary alloc] init];
	mobileCache = [[NSMutableDictionary alloc] init];
	
	//Register the events we generate
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_ONLINE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_ONLINE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_AWAY_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_AWAY_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_IDLE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_IDLE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_SEEN_ONLINE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_SEEN_ONLINE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_MOBILE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[adium.contactAlertsController registerEventID:CONTACT_STATUS_MOBILE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	
	//Observe status changes
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the passed event
 */
- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
		description = AILocalizedString(@"Signs on",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
		description = AILocalizedString(@"Signs off",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
		description = AILocalizedString(@"Goes away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
		description = AILocalizedString(@"Returns from away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
		description = AILocalizedString(@"Becomes idle",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
		description = AILocalizedString(@"Returns from idle",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
		description = AILocalizedString(@"Is seen",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
		description = AILocalizedString(@"Is no longer seen",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
		description = AILocalizedString(@"Goes mobile",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
		description = AILocalizedString(@"Returns from mobile",nil);
	} else {
		description = @"";
	}
	
	return description;
}

/*!
 * @brief Global short description for an event
 */
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
		description = AILocalizedString(@"Contact signs on",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
		description = AILocalizedString(@"Contact signs off",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
		description = AILocalizedString(@"Contact goes away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
		description = AILocalizedString(@"Contact returns from away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
		description = AILocalizedString(@"Contact becomes idle",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
		description = AILocalizedString(@"Contact returns from idle",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
		description = AILocalizedString(@"Contact is seen",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
		description = AILocalizedString(@"Contact is no longer seen",nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
		description = AILocalizedString(@"Contact goes mobile",nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
		description = AILocalizedString(@"Contact returns from mobile",nil);
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
	
	if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
		description = @"Contact Signed On";
	} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
		description = @"Contact Signed Off";
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
		description = @"Contact Went Away";
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
		description = @"Contact Returned from Away";
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
		description = @"Contact Went Idle";
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
		description = @"Contact Returned from Idle";
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
		description = @"Contact is seen";
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
		description = @"Contact is no longer seen";
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
		description = @"Contact Went Mobile";
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
		description = @"Contact Returns from Mobile";
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
	NSString	*format;
	NSString	*name;
	
	if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
		format = AILocalizedString(@"When %@ connects",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
		format = AILocalizedString(@"When %@ disconnects",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
		format = AILocalizedString(@"When %@ goes away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
		format = AILocalizedString(@"When %@ returns from away",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
		format = AILocalizedString(@"When %@ goes idle",nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
		format = AILocalizedString(@"When %@ returns from idle",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
		format = AILocalizedString(@"When you see %@",nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
		format = AILocalizedString(@"When you no longer see %@",nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
		format = AILocalizedString(@"When %@ goes mobile",nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
		format = AILocalizedString(@"When %@ returns from mobile",nil);
	} else {
		format = @"";
	}
	
	if (listObject) {
		name = ([listObject isKindOfClass:[AIListGroup class]] ?
				[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),listObject.displayName] :
				listObject.displayName);
	} else {
		name = AILocalizedString(@"a contact",nil);
	}

	return [NSString stringWithFormat:format,name];
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
		
		if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
			format = AILocalizedString(@"%@ connected", "Event: <A contact's name> connected");
		} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
			format = AILocalizedString(@"%@ disconnected","Event: <A contact's name> disconnected");
		} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
			format = AILocalizedString(@"%@ went away","Event: <A contact's name> went away (is no longer available but is still online)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
			format = AILocalizedString(@"%@ came back","Event: <A contact's name> came back (is now available)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
			format = AILocalizedString(@"%@ went idle",nil"Event: <A contact's name> went idle");
		} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
			format = AILocalizedString(@"%@ became active","Event: <A contact's name> became active (is no longer idle)");
		} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
			format = AILocalizedString(@"%@ is seen","Event: <A contact's name> is seen (which can be 'came online' or 'was online when you connected')");
		} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
			format = AILocalizedString(@"%@ is no longer seen","Event: <A contact's name> is no longer seen (went offline, or you went offline)");
		} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
			format = AILocalizedString(@"%@ went mobile", "Event: <A contact's name> went mobile (went offline but is available on a mobile device)");
		} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
			format = AILocalizedString(@"%@ returned from mobile", "Event: <A contact's name> is no longer mobile (came online and is no longer available on a mobile device)");
		}
		
		if (format) {
			description = [NSString stringWithFormat:format,listObject.displayName];
		}
	} else {
		if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
			description = AILocalizedString(@"connected","Event: connected (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
			description = AILocalizedString(@"disconnected","Event: disconnected (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
			description = AILocalizedString(@"went away","Event: went away (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
			description = AILocalizedString(@"came back","Event: came back (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
			description = AILocalizedString(@"went idle","Event: went idle (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
			description = AILocalizedString(@"became active","Event: became active (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
			description = AILocalizedString(@"is seen","Event: is seen (follows a contact's name displayed as a header)");
		} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
			description = AILocalizedString(@"is no longer seen","Event: is no longer seen (follows a contact's name displayed as a header)");
		} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
			description = AILocalizedString(@"went mobile", "Event: went mobile (follows a contact's name displayed as a header)");
		} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
			description = AILocalizedString(@"returned from mobile", "Event: is no longer mobile (follows a contact's name displayed as a header)");
		}
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [NSImage imageNamed:@"events-contact" forClass:[self class]];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	NSString *format = nil;
	
	if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]) {
		format = AILocalizedString(@"%u contacts connected", nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]) {
		format = AILocalizedString(@"%u contacts disconnected", nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]) {
		format = AILocalizedString(@"%u contacts went away", nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]) {
		format = AILocalizedString(@"%u contacts came back", nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]) {
		format = AILocalizedString(@"%u contacts went idle", nil);
	} else if ([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]) {
		format = AILocalizedString(@"%u contacts became active", nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_YES]) {
		format = AILocalizedString(@"%u contacts are seen", nil);
	} else if ([eventID isEqualToString:CONTACT_SEEN_ONLINE_NO]) {
		format = AILocalizedString(@"%u contacts are no longer seen", nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_YES]) {
		format = AILocalizedString(@"%u contacts went mobile", nil);
	} else if([eventID isEqualToString:CONTACT_STATUS_MOBILE_NO]) {
		format = AILocalizedString(@"%u contacts returned from mobile", nil);
	}
	
	return format ? [NSString stringWithFormat:format, count] : @"";
}

#pragma mark Caching and event generation
/*!
 * @brief Cache list object updates
 *
 * We cache list object updates so we can avoid generating the same event for the same contact on two accounts
 * or for multiple identical changes within a metaContact.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	/* Ignore accounts.
	 * Ignore meta contact children since the actual meta contact provides a better event. The best way to check this is to verify that the contact's parentContact is itself.*/
	if (([inObject isKindOfClass:[AIListContact class]]) &&
		([(AIListContact *)inObject parentContact] == (AIListContact *)inObject)) {
		
		if ([inModifiedKeys containsObject:@"isOnline"]) {
			NSNumber *newValue = [inObject valueForProperty:@"isOnline"];

			if ([self updateCache:onlineCache
						   forKey:@"isOnline"
						 newValue:newValue
					   listObject:inObject
				   performCompare:YES]) {
				if (!silent) {
					NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO);
					[adium.contactAlertsController generateEvent:event
													 forListObject:inObject
														  userInfo:nil
									  previouslyPerformedActionIDs:nil];
				}
									
				NSString	*event = ([newValue boolValue] ? CONTACT_SEEN_ONLINE_YES : CONTACT_SEEN_ONLINE_NO);
				[adium.contactAlertsController generateEvent:event
												 forListObject:inObject
													  userInfo:nil
								  previouslyPerformedActionIDs:nil];
			}
		}
		
		// IsMobile can be broadcasted before Online
		if([inModifiedKeys containsObject:@"isMobile"]) {
			NSNumber *newValue = [inObject valueForProperty:@"isMobile"];
			if([self updateCache:mobileCache 
						  forKey:@"isMobile"
						newValue:newValue 
					  listObject:inObject 
				  performCompare:YES] && !silent) {
				NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_MOBILE_YES : CONTACT_STATUS_MOBILE_NO);
				[adium.contactAlertsController generateEvent:event 
				 forListObject:inObject 
				 userInfo:nil 
				 previouslyPerformedActionIDs:nil];
			}
		}
		
		/* Events which are irrelevent if the contact is not online - these changes occur when we are
		 * just doing bookkeeping e.g. an away contact signs off, we clear the away flag, but they didn't actually
		 * come back from away. */
		if ([inObject boolValueForProperty:@"isOnline"]) {
			if ([inModifiedKeys containsObject:@"listObjectStatusMessage"] || [inModifiedKeys containsObject:@"listObjectStatusType"]) {
				NSNumber	*newAwayNumber;
				NSString	*newStatusMessage;
				BOOL		awayChanged, statusMessageChanged;
				NSSet		*previouslyPerformedActionIDs = nil;

				//Update away/not-away
				newAwayNumber = (inObject.statusType == AIAwayStatusType) ? [NSNumber numberWithBool:YES] : nil;
				awayChanged = [self updateCache:awayCache
										 forKey:@"Away"
									   newValue:newAwayNumber
									 listObject:inObject
								 performCompare:YES];
				
				//Update status message
				newStatusMessage = [inObject.statusMessage string];
				statusMessageChanged = [self updateCache:statusMessageCache 
												 forKey:@"listObjectStatusMessage"
											   newValue:newStatusMessage
											 listObject:inObject
										 performCompare:YES];

				if (statusMessageChanged && !silent) {
					if (newStatusMessage != nil) {
						//Evan: Not yet a contact alert, but we use the notification - how could/should we use this?
						previouslyPerformedActionIDs = [adium.contactAlertsController generateEvent:CONTACT_STATUS_MESSAGE
																						forListObject:inObject
																							 userInfo:nil
																		 previouslyPerformedActionIDs:nil];
					}
				}
				
				//Don't repeat notifications for the away change which the status message already covered
				if (awayChanged && !silent) {
					NSString		*event = ([newAwayNumber boolValue] ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO);
					NSDictionary	*userInfo = nil;
					
					if ([event isEqualToString:CONTACT_STATUS_AWAY_YES] &&
						(statusMessageChanged && (newStatusMessage != nil))) {
						userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
															   forKey:@"Already Posted StatusMessage"];
					}

					[adium.contactAlertsController generateEvent:event
													 forListObject:inObject
														  userInfo:userInfo
									  previouslyPerformedActionIDs:previouslyPerformedActionIDs];
				}
			}

			if ([inModifiedKeys containsObject:@"isIdle"]) {
				id newValue = [inObject numberValueForProperty:@"isIdle"];
				if ([self updateCache:idleCache
							   forKey:@"isIdle"
							 newValue:newValue
						   listObject:inObject
					   performCompare:YES] && !silent) {
					NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO);
					[adium.contactAlertsController generateEvent:event
													 forListObject:inObject
														  userInfo:nil
									  previouslyPerformedActionIDs:nil];
				}
			}
		}
	}

	return nil;	
}

/*!
 * @brief Update the cache
 *
 * @param cache The cache
 * @param key The key
 * @param newStatus The new value
 * @param inObject The list object
 * @param performCompare If NO, we are only concerned about whether any object exists. If YES, a change from one value to another means we've updated.
 *
 * @result YES if the cache changed; NO if it remained the same (event has already occurred on another associated contact)
 */
- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key newValue:(id)newStatus listObject:(AIListObject *)inObject performCompare:(BOOL)performCompare
{
	id		oldStatus = [cache objectForKey:inObject.internalObjectID];

	if ((newStatus && !oldStatus) ||
	   (oldStatus && !newStatus) ||
	   ((performCompare && newStatus && oldStatus && (int)[newStatus performSelector:@selector(compare:) withObject:oldStatus] != NSOrderedSame))) {
		
		if (newStatus) {
			[cache setObject:newStatus forKey:inObject.internalObjectID];
		} else {
			[cache removeObjectForKey:inObject.internalObjectID];
		}

		return YES;
	} else {
		return NO;
	}
}

@end
