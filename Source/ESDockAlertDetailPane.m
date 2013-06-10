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

#import "AIDockBehaviorPlugin.h"
#import "AIDockController.h"
#import "ESDockAlertDetailPane.h"
#import <AIUtilities/AIMenuAdditions.h>

@interface ESDockAlertDetailPane ()
- (NSMenuItem *)menuItemForBehavior:(AIDockBehavior)behavior withName:(NSString *)name;
- (NSMenu *)behaviorListMenu;
@end

/*!
 * @class ESDockAlertDetailPane
 * @brief Details pane for the Bounce Dock action
 */
@implementation ESDockAlertDetailPane

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"DockBehaviorContactAlert";    
}

/*!
 * @brief Configure the detail view
 */
- (void)viewDidLoad
{
	[super viewDidLoad];

	[label_behavior setStringValue:AILocalizedString(@"Behavior","Dock behavior contact alert label")];

    [popUp_actionDetails setMenu:[self behaviorListMenu]];
}

/*!
 * @brief Configure for the action
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	NSInteger behaviorIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:[inDetails objectForKey:KEY_DOCK_BEHAVIOR_TYPE]];
	if (behaviorIndex >= 0 && behaviorIndex < [popUp_actionDetails numberOfItems]) {
		[popUp_actionDetails selectItemAtIndex:behaviorIndex];        
	}
}

/*!
 * @brief Return our current configuration
 */
- (NSDictionary *)actionDetails
{
	NSString	*behavior = [[popUp_actionDetails selectedItem] representedObject];
	
	if (behavior) {
		return [NSDictionary dictionaryWithObject:behavior forKey:KEY_DOCK_BEHAVIOR_TYPE];
	} else {
		return nil;
	}	
}

/*!
 * @brief The user selected a behavior
 */
- (IBAction)selectBehavior:(id)sender
{
	[self detailsForHeaderChanged];
}

/*!
 * @brief Builds and returns a dock behavior list menu
 */
- (NSMenu *)behaviorListMenu
{
    NSMenu			*behaviorMenu = [[NSMenu alloc] init];
    AIDockBehavior	behavior;

	for (behavior = AIDockBehaviorBounceOnce; behavior <= AIDockBehaviorBounceDelay_OneMinute; behavior++) {
		NSString *name = [adium.dockController descriptionForBehavior:behavior];
		[behaviorMenu addItem:[self menuItemForBehavior:behavior withName:name]];
	}
    
    [behaviorMenu setAutoenablesItems:NO];
    
    return behaviorMenu;
}

/*!
 * @brief Convenience behaviorListMenu method
 * @result An NSMenuItem
 */
- (NSMenuItem *)menuItemForBehavior:(AIDockBehavior)behavior withName:(NSString *)name
{
    NSMenuItem		*menuItem;
    menuItem = [[NSMenuItem alloc] initWithTitle:name
																	 target:self
																	 action:@selector(selectBehavior:)
															  keyEquivalent:@""];
    [menuItem setRepresentedObject:[NSNumber numberWithInteger:behavior]];
    
    return menuItem;
}


@end

