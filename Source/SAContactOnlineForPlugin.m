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
#import "SAContactOnlineForPlugin.h"
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

/*!
 * @class SAContactOnlineForPlugin
 * @brief Tooltip component: Online for
 */
@implementation SAContactOnlineForPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:NO];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return AILocalizedString(@"Online For", "A time interval such as '3 days' will be shown after this identifier");
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString	*entry = nil;
	
    if (inObject.online) {
        NSDate	*signonDate;

        if ([inObject isKindOfClass:[AIListContact class]] &&
			(signonDate = [(AIListContact *)inObject signonDate])) {
            entry = [[NSAttributedString alloc] initWithString:[NSDateFormatter stringForTimeIntervalSinceDate:signonDate 
																								showingSeconds:NO 
																								   abbreviated:NO]];
        }
    }

    return [entry autorelease];
}

- (BOOL)shouldDisplayInContactInspector
{
	/* Accounts should be including this information in the profile already */
	return NO;
}

@end
