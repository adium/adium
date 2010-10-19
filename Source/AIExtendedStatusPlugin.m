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

#import "AIExtendedStatusPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

#define STATUS_MAX_LENGTH	100

/*!
 * @class AIExtendedStatusPlugin
 * @brief Manage the 'extended status' shown in the contact list
 *
 * If the contact list layout calls for displaying a status message or idle time (or both), this component manages
 * generating the appropriate string, storing it in the @"extendedStatus" property, and updating it as necessary.
 */
@implementation AIExtendedStatusPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];
	
	whitespaceAndNewlineCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
}

/*!
 * @brief Preferences changes
 *
 * PREF_GROUP_LIST_LAYOUT changed; update our list objects if needed.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	BOOL oldShowStatus = showStatus;
	BOOL oldShowIdle = showIdle;
	BOOL oldIncludeIdleInExtendedStatus = includeIdleInExtendedStatus;

	EXTENDED_STATUS_STYLE statusStyle = [(NSNumber *)[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_STYLE] intValue];
	showStatus = ((statusStyle == STATUS_ONLY) || (statusStyle == IDLE_AND_STATUS));
	showIdle = ((statusStyle == IDLE_ONLY) || (statusStyle == IDLE_AND_STATUS));
	
	EXTENDED_STATUS_POSITION statusPosition = [(NSNumber *)[prefDict objectForKey:KEY_LIST_LAYOUT_EXTENDED_STATUS_POSITION] intValue];
	includeIdleInExtendedStatus = (statusPosition != EXTENDED_STATUS_POSITION_BOTH);
	
	if (firstTime) {
		[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	} else {
		if ((oldShowStatus != showStatus) ||
			(oldShowIdle != showIdle) ||
			(oldIncludeIdleInExtendedStatus != includeIdleInExtendedStatus)) {
			[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];
		}
	}
}

/*!
 * @brief Update list object's extended status messages
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	NSSet		*modifiedAttributes = nil;

	/* Work at the parent contact (metacontact, etc.) level for extended status, since that's what's displayed in the contact list.
	 * We completely ignore status updates sent for an object which isn't the highest-level up (e.g. is within a metacontact).
	 */
    if ((inModifiedKeys == nil || 
		 (showIdle && [inModifiedKeys containsObject:@"idle"]) ||
		 (showStatus && ([inModifiedKeys containsObject:@"listObjectStatusMessage"] ||
						 [inModifiedKeys containsObject:@"listObjectStatusName"]))) &&
		[inObject isKindOfClass:[AIListContact class]]){
		NSMutableString	*statusMessage = nil;
		NSString		*finalMessage = nil, *finalIdleReadable = nil;
		NSInteger		idle;

		if (showStatus) {
			NSAttributedString *filteredMessage;

			filteredMessage = [adium.contentController filterAttributedString:[(AIListContact *)inObject contactListStatusMessage]
																usingFilterType:AIFilterContactList
																	  direction:AIFilterIncoming
																		context:inObject];
			statusMessage = [[[[filteredMessage string] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] mutableCopy] autorelease];

			//Incredibly long status messages are slow to size, so we crop them to a reasonable length
			NSInteger statusMessageLength = [statusMessage length];
			if (statusMessageLength == 0) {
				statusMessage = nil;

			} else if (statusMessageLength > STATUS_MAX_LENGTH) {
				[statusMessage deleteCharactersInRange:NSMakeRange(STATUS_MAX_LENGTH,
																   [statusMessage length] - STATUS_MAX_LENGTH)];
			}

			/* Linebreaks in the status message cause vertical alignment issues. */
			[statusMessage convertNewlinesToSlashes];	
		}

		idle = (showIdle ? inObject.idleTime : 0);

		//
		NSString *idleString = ((idle > 0) ? [self idleStringForMinutes:idle] : nil);

		if (idle > 0 && statusMessage) {
			finalMessage = (includeIdleInExtendedStatus ?
							[NSString stringWithFormat:@"(%@) %@",idleString, statusMessage] :
							statusMessage);
			finalIdleReadable = [NSString stringWithFormat:@"(%@)", idleString];
		} else if (idle > 0) {			
			finalIdleReadable = [NSString stringWithFormat:@"(%@)",idleString];
			finalMessage = (includeIdleInExtendedStatus ?
							finalIdleReadable :
							statusMessage);			
		} else {
			finalMessage = statusMessage;
		}

		[inObject setValue:finalIdleReadable
			   forProperty:@"idleReadable"
					notify:NotifyNever];

		[inObject setValue:finalMessage
			   forProperty:@"extendedStatus"
					notify:NotifyNever];
		modifiedAttributes = [NSSet setWithObject:@"extendedStatus"];
	}
	
	return modifiedAttributes;
}


/*!
 * @brief Determine the idle string
 *
 * @param minutes Number of minutes idle
 * @result A localized string to display for the idle time
 */
- (NSString *)idleStringForMinutes:(NSInteger)minutes //input is actualy minutes
{
	// Cap Idletime at 599400 minutes (999 hours)
	return ((minutes > 599400) ? AILocalizedString(@"Idle",nil) : [NSDateFormatter stringForApproximateTimeInterval:(minutes * 60) abbreviated:YES]);
}

@end
