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

#import <Adium/AIInterfaceControllerProtocol.h>
#import "CBContactLastSeenPlugin.h"
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>

#define PREF_GROUP_LAST_SEEN	@"Last Seen"
#define KEY_LAST_SEEN_STATUS	@"Last Seen Status"
#define KEY_LAST_SEEN_DATE		@"Last Seen Date"

/*!
 * @class CBContactLastSeenPlugin
 * @brief Component to track and display as a tooltip the last time contacts were seen online
 */
@implementation CBContactLastSeenPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:NO];

	//Observe status changes
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	/* Update only for contacts whose online status has changed */
	if ([inObject isKindOfClass:[AIListContact class]]) {
		if ([inModifiedKeys containsObject:@"isOnline"]) {
			if (inObject.online) {
				//Either they are online, or we've come online. Either way, update both their status and the time
				[inObject setPreference:AILocalizedString(@"Online",nil)
								 forKey:KEY_LAST_SEEN_STATUS
								  group:PREF_GROUP_LAST_SEEN];
				
				[inObject setPreference:[NSDate date]
								 forKey:KEY_LAST_SEEN_DATE
								  group:PREF_GROUP_LAST_SEEN];
				
				
			} else {
				if (!silent) {
					//They've signed off, update their status and the time		
					[inObject setPreference:AILocalizedString(@"Signing off",nil)
									 forKey:KEY_LAST_SEEN_STATUS
									  group:PREF_GROUP_LAST_SEEN];
					
					[inObject setPreference:[NSDate date]
									 forKey:KEY_LAST_SEEN_DATE
									  group:PREF_GROUP_LAST_SEEN];	
				} else {
					/* Don't update the status, as we didn't see them signing off but
					 * rather we signed off (silent updates are grouped ones.)
					 * Just update the date.
					 */
					[inObject setPreference:[NSDate date]
									 forKey:KEY_LAST_SEEN_DATE
									  group:PREF_GROUP_LAST_SEEN];
				}
			}
		}
	}
	
	return nil;	
}

#pragma mark Tooltip entry
//Tooltip entry ---------------------------------------------------------------------------------------

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return AILocalizedString(@"Last Seen","A time interval such as '4 days ago' will be shown after this tooltip identifier");
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	NSString			*lastSeenStatus;
	NSDate				*lastSeenDate;
	NSDateFormatter		*sinceDateFormatter;
	NSAttributedString	*entry = nil;
	
	//Only display for offline contacts
	if (!inObject.online && !inObject.isStranger) {
	
		lastSeenStatus = [adium.preferenceController preferenceForKey:KEY_LAST_SEEN_STATUS 
																  group:PREF_GROUP_LAST_SEEN
																 object:inObject];
		
		lastSeenDate = [adium.preferenceController preferenceForKey:KEY_LAST_SEEN_DATE 
																group:PREF_GROUP_LAST_SEEN
															   object:inObject];
		if (lastSeenStatus && lastSeenDate) {
			NSString	*timeElapsed;
			NSString	*timeElapsedWithDesignation;
			
			sinceDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[NSDateFormatter withLocalizedShortDateFormatterPerform:^(NSDateFormatter *dateFormatter){
				[sinceDateFormatter setDateFormat:[NSString stringWithFormat:@"%@, %@",
												   [dateFormatter dateFormat],
												   [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES]]];
			}];
			
			//stringForTimeIntervalSinceDate may return @"" if it's too short of an interval.
			timeElapsed = [NSDateFormatter stringForTimeIntervalSinceDate:lastSeenDate showingSeconds:NO abbreviated:NO];
			if (timeElapsed && [timeElapsed length]) {
				timeElapsedWithDesignation = [NSString stringWithFormat:
					AILocalizedString(@"%@ ago", "%@ will be replaced by an amount of time such as '1 day, 4 hours'. This string is used in the 'Last Seen:' information shown when hovering over an offline contact."),
					timeElapsed];
			} else {
				timeElapsedWithDesignation = @"";
			}
			
			
			entry = [[NSAttributedString alloc] 
						initWithString:[NSString stringWithFormat:
							@"%@\n%@%@%@", 
							lastSeenStatus,
							timeElapsedWithDesignation,
							([timeElapsedWithDesignation length] ? @"\n" : @""),
							[sinceDateFormatter stringForObjectValue:lastSeenDate]]]; 
		}
	}
	
	return [entry autorelease];
}

- (BOOL)shouldDisplayInContactInspector
{
	return YES;
}

@end
