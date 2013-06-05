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

#import <AIUtilities/AIMenuAdditions.h>

@interface CBGrowlAlertDetailPane()
- (NSMenu *)priorityMenu;
- (void)dummyAction;
@end

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
	
	[checkBox_sticky setLocalizedString:AILocalizedString(@"Show until dismissed","Growl contact alert label")];
    [checkBox_timestamp setLocalizedString:AILocalizedString(@"Show time stamp", "Growl contact alert label")];
	[label_priority setLocalizedString:AILocalizedString(@"Growl priority:", "Priority label for Growl")];
	
	[popUp_priority setMenu:[self priorityMenu]];
	
	BOOL isGrowlRunning = [GrowlApplicationBridge isGrowlRunning];
	
	[popUp_priority setEnabled:isGrowlRunning];
	[label_priority setEnabled:isGrowlRunning];
}

/*!
 * @brief The priority menu
 *
 * @return A menu of elements with Name (Tag) as follows: Very Low (-2), Moderate (-1), Normal (0), High (1), Emergency (2).
 */
- (NSMenu *)priorityMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	
	[menu addItemWithTitle:AILocalizedString(@"Very Low", "Growl priority")
					target:self
					action:@selector(dummyAction)
			 keyEquivalent:@""
					   tag:-2];
	
	[menu addItemWithTitle:AILocalizedString(@"Moderate", "Growl priority")
					target:self
					action:@selector(dummyAction)
			 keyEquivalent:@""
					   tag:-1];
	
	[menu addItemWithTitle:AILocalizedString(@"Normal", "Growl priority")
					target:self
					action:@selector(dummyAction)
			 keyEquivalent:@""
					   tag:0];
	
	[menu addItemWithTitle:AILocalizedString(@"High", "Growl priority")
					target:self
					action:@selector(dummyAction)
			 keyEquivalent:@""
					   tag:1];
	
	[menu addItemWithTitle:AILocalizedString(@"Emergency", "Growl priority")
					target:self
					action:@selector(dummyAction)
			 keyEquivalent:@""
					   tag:2];
	
	return menu;
}

/*!
 * @brief Does nothing.
 */
- (void)dummyAction {}

/*!
 * @brief Load the state of our controls
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	[checkBox_sticky setState:([[inDetails objectForKey:KEY_GROWL_ALERT_STICKY] boolValue] ? NSOnState : NSOffState)];
    [checkBox_timestamp setState:([[inDetails objectForKey:KEY_GROWL_ALERT_TIME_STAMP] boolValue] ? NSOnState : NSOffState)];
	[popUp_priority selectItemWithTag:[[inDetails objectForKey:KEY_GROWL_PRIORITY] integerValue]];
}

/*!
 * @brief Return the state of our controls
 */
- (NSDictionary *)actionDetails
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:([checkBox_sticky state] == NSOnState)], KEY_GROWL_ALERT_STICKY,
            [NSNumber numberWithBool:([checkBox_timestamp state] == NSOnState)], KEY_GROWL_ALERT_TIME_STAMP,
			[NSNumber numberWithInteger:[popUp_priority selectedItem].tag], KEY_GROWL_PRIORITY, nil];
}

/*!
 * @brief Called when any of our controls change
 */
- (IBAction)changePreference:(id)sender
{
	[self detailsForHeaderChanged];
}

@end
