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

#import "SMContactListShowDetailsPane.h"

@implementation SMContactListShowDetailsPane
/*!
* @brief Returns the name of our pane
 *
 * Since this is a detail pain, we return @"".
 */
- (NSString *)label
{ 
	return @"";
}

/*!
* @brief Returns the name of the Nib to load
 */
- (NSString *)nibName
{
	return @"ContactListShowBehavior";
}

/*!
* @brief View did load
 */
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[label_secondsToShow setLocalizedString:AILocalizedString(@"Seconds To Show:", "Label before a slider which sets the number of seconds to show the contact list when an action is triggerred")];
	[label_note setLocalizedString:AILocalizedString(@"Note: This behavior is only available if the contact list is set to hide.", "Explanation of when the 'show contact list' action is available for use")];
}

/*!
* @brief Load the state of our controls
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	[slider_secondsToShow setDoubleValue:[[inDetails objectForKey:KEY_SECONDS_TO_SHOW_LIST] doubleValue]];
}

/*!
* @brief Return the state of our controls
 */
- (NSDictionary *)actionDetails
{
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[slider_secondsToShow doubleValue]] forKey:KEY_SECONDS_TO_SHOW_LIST];
}

/*!
* @brief Called when any of our controls change
 */
- (IBAction)changePreference:(id)sender
{
	[self detailsForHeaderChanged];
}

@end
