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

#import "AIContactAwayPlugin.h"
#import "AIStatusController.h"
#import <Adium/AIListObject.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIListBookmark.h>

#define	AWAY				AILocalizedString(@"Away",nil)
#define	AWAY_MESSAGE_LABEL	AILocalizedString(@"Away Message",nil)
#define	STATUS_LABEL		AILocalizedString(@"Status",nil)

/*!
 * @class AIContactAwayPlugin
 * @brief Tooltip component: Away messages and states
 */
@implementation AIContactAwayPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];
}

/*!
 * @brief Return the description of the object's status to show after Status:
 *
 * If a statusName exists for the object's status, its localized description will be shown.
 * If the object is away and no statusName is set, Away will be shown.
 */
- (NSString *)awayDescriptionForObject:(AIListObject *)inObject
{
	NSString *awayDescriptionString = nil;
	NSString *statusName = inObject.statusName;
	AIStatusType statusType = inObject.statusType;
	
	if (statusName) {
		awayDescriptionString = [adium.statusController localizedDescriptionForStatusName:statusName
																			   statusType:statusType];
	}
	
	if (!statusName && (statusType == AIAwayStatusType)) {
		awayDescriptionString = AWAY;
	}
	
	return awayDescriptionString;
}
/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
    NSString			*label = nil;
    NSAttributedString 	*statusMessage = nil;
    BOOL				away;
    
    away = (inObject.statusType == AIAwayStatusType);
    
    //Get the status message
    statusMessage = inObject.statusMessage;
    
	//Return the correct string
	if (statusMessage != nil && [statusMessage length] != 0) {
		if ([inObject isKindOfClass:[AIListBookmark class]]) {
			/* It's actually a bookmark, show "Topic: " instead */
			
			label = AILocalizedString(@"Topic", nil);
			
		} else if (away) {
			/* Away with a status message */
			
			//Check to make sure we're not duplicating server display name information
			NSString	*serverDisplayName = [inObject valueForProperty:@"serverDisplayName"];
			
			if ([serverDisplayName isEqualToString:[statusMessage string]]) {
				/* If the server display name is the status message, awayDescriptionForObject: will be the entry */
				label = STATUS_LABEL;
			} else {
				label = [self awayDescriptionForObject:inObject];
			}
			
		} else {
			/* Available with a status message */
			label = STATUS_LABEL;
		}
    } else if (away) {
		/* Away without a status message */
		label = STATUS_LABEL;
    }
    
    return label;
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString	*entry = nil;
    NSAttributedString 	*statusMessage = nil;
	NSString			*serverDisplayName = nil;
	
    //Get the status message
    statusMessage = inObject.statusMessage;
	
	//Check to make sure we're not duplicating server display name information
	serverDisplayName = [inObject valueForProperty:@"serverDisplayName"];
	
    //Return the correct string
	if ([serverDisplayName isEqualToString:[statusMessage string]]) {
		/* If the status and server display name are the same, just display the status as appropriate since
		 * we'll display the server display name itself in the proper place.
		 */
		NSString *awayDescription = [self awayDescriptionForObject:inObject];
		entry = (awayDescription ?
				 [[NSAttributedString alloc] initWithString:awayDescription] :
				 nil);
		
	} else {
		if (statusMessage != nil && [statusMessage length] != 0) {
			if ([[statusMessage string] rangeOfString:@"\t" options:NSLiteralSearch].location == NSNotFound) {
				entry = statusMessage;
				
			} else {
				/* We don't display tabs well in the tooltips because we use them for alignment, so
				* turn them into 4 spaces. */
				NSMutableAttributedString	*mutableStatusMessage = [statusMessage mutableCopy];
				[mutableStatusMessage replaceOccurrencesOfString:@"\t"
													  withString:@"    "
														 options:NSLiteralSearch
														   range:NSMakeRange(0, [mutableStatusMessage length])];
				entry = mutableStatusMessage;
			}
			
			
			
		} else {
			NSString *awayDescription = [self awayDescriptionForObject:inObject];
			entry = (awayDescription ?
					 [[NSAttributedString alloc] initWithString:awayDescription] :
					 nil);
		}
	}
	
    return entry;
}

- (BOOL)shouldDisplayInContactInspector
{
	/* Accounts should be including this information in the profile already */
	return NO;
}
@end
