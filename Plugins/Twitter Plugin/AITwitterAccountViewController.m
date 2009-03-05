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

#import "AITwitterAccount.h"
#import "AITwitterAccountViewController.h"
#import <AIUtilities/AIMenuAdditions.h>

@implementation AITwitterAccountViewController

/*!
 * @brief We have no privacy settings.
 */
- (NSView *)privacyView
{
	return nil;
}

/*!
 * @brief We do not yet have personal settings.
 */
- (NSView *)profileView
{
	return nil;
}

/*!
 * @brief Use the Twitter account view.
 */
- (NSString *)nibName
{
    return @"AITwitterAccountView";
}

- (void)awakeFromNib
{
	NSMenu *intervalMenu = [[[NSMenu alloc] init] autorelease];

	[intervalMenu addItemWithTitle:AILocalizedString(@"never", "Update tweets: never")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:0]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 2 minutes", "Update tweets: every 2 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:2]];

	[intervalMenu addItemWithTitle:AILocalizedString(@"every 5 minutes", "Update tweets: every 5 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:5]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 10 minutes", "Update tweets every: 10 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:10]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every 15 minutes", "Update tweets every: 15 minutes")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:15]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every half-hour", "Update tweets every: half-hour")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:30]];
	
	[intervalMenu addItemWithTitle:AILocalizedString(@"every hour", "Update tweets every hour")
							target:self
							action:nil
					 keyEquivalent:@""
				 representedObject:[NSNumber numberWithInt:60]];
	
	[intervalMenu setAutoenablesItems:YES];
	
	[popUp_updateInterval setMenu:intervalMenu];
}

/*!
 * @brief Configure the account view
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	if(inAccount != account) {
		NSNumber *updateInterval = [inAccount preferenceForKey:TWITTER_PREFERENCE_UPDATE_INTERVAL group:TWITTER_PREFERENCE_GROUP_UPDATES];
		[popUp_updateInterval selectItemAtIndex:[[popUp_updateInterval menu] indexOfItemWithRepresentedObject:updateInterval]];
	}
	
	[super configureForAccount:inAccount];
}

/*!
 * @brief The Update Interval combo box was changed.
 */
- (void)saveConfiguration
{
	[super saveConfiguration];
	
	[account setPreference:popUp_updateInterval.selectedItem.representedObject
					forKey:TWITTER_PREFERENCE_UPDATE_INTERVAL
					 group:TWITTER_PREFERENCE_GROUP_UPDATES];
}

@end
