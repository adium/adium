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

#import "CBGrowlAlertDetailPane.h"
#import "NEHGrowlPlugin.h"

/*!
 * @class CBGrowlAlertDetailPane
 * @brief Provide and manage custom controls for configuring the Growl contact alert
 *
 * The only control currently provided is the ability to make a Growl notification sticky (i.e. does not disappear until
 * the user dismisses it).
 */
@implementation CBGrowlAlertDetailPane

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
	return @"GrowlAlert";
}

/*!
 * @brief Configure the detail view, and set up our localized controls
 */
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[checkBox_sticky setLocalizedString:AILocalizedString(@"Sticky","Growl contact alert label")];
}

/*!
 * @brief Load the state of our controls
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	[checkBox_sticky setState:([[inDetails objectForKey:KEY_GROWL_ALERT_STICKY] boolValue] ? NSOnState : NSOffState)];
}

/*!
 * @brief Return the state of our controls
 */
- (NSDictionary *)actionDetails
{
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:([checkBox_sticky state] == NSOnState)]
									   forKey:KEY_GROWL_ALERT_STICKY];
}

/*!
 * @brief Called when any of our controls change
 */
- (IBAction)changePreference:(id)sender
{
	[self detailsForHeaderChanged];
}

@end
