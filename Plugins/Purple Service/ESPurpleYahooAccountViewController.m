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

#import "ESPurpleYahooAccountViewController.h"
#import "ESPurpleYahooAccount.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

@interface ESPurpleYahooAccountViewController ()
- (NSMenu *)chatServerMenu;
@end

@implementation ESPurpleYahooAccountViewController

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ESPurpleYahooAccountView";
}

/*!
 * @brief Awake from nib
 */
- (void)awakeFromNib
{
	[super awakeFromNib];
	[popUp_chatServer setMenu:[self chatServerMenu]];
}

/*!
 * @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];

	[popUp_chatServer selectItemWithRepresentedObject:[inAccount preferenceForKey:KEY_YAHOO_ROOM_LIST_LOCALE
																			group:GROUP_ACCOUNT_STATUS]];
}

/*!
 * @brief Save controls
 */
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	[account setPreference:[[popUp_chatServer selectedItem] representedObject]
					forKey:KEY_YAHOO_ROOM_LIST_LOCALE
					 group:GROUP_ACCOUNT_STATUS];
}

- (NSMenu *)chatServerMenu
{
	NSMenu			*chatServerMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMutableArray	*menuItems = [NSMutableArray array];
	NSMenuItem		*menuItem;
	NSEnumerator	*enumerator;
	NSString		*prefix;
	NSDictionary	*roomListServersDict;

	roomListServersDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Asia", @"aa",
		@"Argentina", @"ar",
		@"Australia", @"au",
		@"Brazil", @"br",
		@"Canada", @"ca",
		@"Central African Republic", @"cf",
		@"China", @"cn",
/*		@"Germany", @"de",*/
		@"Denmark", @"dk",
		@"Spain", @"es",
		@"France", @"fr",
		@"Hong Kong", @"hk",
		@"India", @"in",
		@"Italy", @"it",
		@"Korea, Republic of", @"kr",
		@"Mexico", @"mx",
		@"Norway", @"no",
		@"Sweden", @"se",
		@"Singapore", @"sg",
		@"Taiwan", @"tw",
		@"United Kingdom", @"uk",
		nil];

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"United States",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setRepresentedObject:@"us"];
	[menuItems addObject:menuItem];

	enumerator = [roomListServersDict keyEnumerator];
	while ((prefix = [enumerator nextObject])) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[roomListServersDict objectForKey:prefix]
																		 target:nil
																		 action:nil
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:prefix];
		[menuItems addObject:menuItem];		
	}

	[menuItems sortUsingSelector:@selector(titleCompare:)];

	for (menuItem in menuItems) {
		[chatServerMenu addItem:menuItem];
	}

	return [chatServerMenu autorelease];
}

@end
