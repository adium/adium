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

#import "ESPurpleICQAccountViewController.h"
#import "ESPurpleICQAccount.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

@interface ESPurpleICQAccountViewController (PRIVATE)
- (NSMenu *)encodingMenu;
- (void)addEncodingItemsWithNames:(NSArray *)inArray withTitle:(NSString *)inTitle toMenu:(NSMenu *)menu;
@end
										   
@implementation ESPurpleICQAccountViewController

- (NSString *)nibName{
    return @"ESPurpleICQAccountView";
}

//
- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[popUp_encoding setMenu:[self encodingMenu]];	
}

//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	[popUp_encoding selectItemWithRepresentedObject:[account preferenceForKey:KEY_ICQ_ENCODING
																		group:GROUP_ACCOUNT_STATUS]];
	[checkBox_webAware setState:[[account preferenceForKey:KEY_ICQ_WEB_AWARE
													 group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	[account setPreference:[[popUp_encoding selectedItem] representedObject]
					forKey:KEY_ICQ_ENCODING
					 group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_webAware state]]
					forKey:KEY_ICQ_WEB_AWARE
					 group:GROUP_ACCOUNT_STATUS];
}

- (NSMenu *)encodingMenu
{
	NSMenu		*menu = [[NSMenu alloc] init];
	NSArray		*nameArray;
	NSString	*title;
	
	//We'll do custom enabling/disabling and not change it after then, so we don't want auto menuItem validation
	[menu setAutoenablesItems:NO];
	
	title = @"European languages";
	nameArray = [NSArray arrayWithObjects:
		@"ASCII",
		@"ISO-8859-1",
		@"ISO-8859-2",
		@"ISO-8859-3",
		@"ISO-8859-4",
		@"ISO-8859-5",
		@"ISO-8859-7",
		@"ISO-8859-9",
		@"ISO-8859-10",
		@"ISO-8859-13",
		@"ISO-8859-14",
		@"ISO-8859-15",
		@"ISO-8859-16",
		@"KOI8-R",
		@"KOI8-U", 
		@"KOI8-RU",
		@"CP1250",
		@"CP1251",
		@"CP1252",
		@"CP1253",
		@"CP1254",
		@"CP1257",
		@"CP850",
		@"CP866",
		@"MacRoman",
		@"MacCentralEurope",
		@"MacIceland",
		@"MacCroatian",
		@"MacRomania",
		@"MacCyrillic",
		@"MacUkraine",
		@"MacGreek",
		@"MacTurkish",
		@"Macintosh",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Semitic languages";
	nameArray = [NSArray arrayWithObjects:
		@"ISO-8859-6",
		@"ISO-8859-8",
		@"CP1255",
		@"CP1256",
		@"CP862",
		@"MacHebrew",
		@"MacArabic",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Japanese";
	nameArray = [NSArray arrayWithObjects:
		@"EUC-JP",
		@"SHIFT_JIS",
		@"CP932",
		@"ISO-2022-JP",
		@"ISO-2022-JP-2",
		@"ISO-2022-JP-1",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];

	title = @"Chinese";
	nameArray = [NSArray arrayWithObjects:
		@"EUC-CN",
		@"HZ",
		@"GBK",
		@"GB18030",
		@"EUC-TW",
		@"BIG5",
		@"CP950",
		@"BIG5-HKSCS",
		@"ISO-2022-CN",
		@"ISO-2022-CN-EXT",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Korean";
	nameArray = [NSArray arrayWithObjects:
		@"EUC-KR",
		@"CP949",
		@"ISO-2022-KR",
		@"JOHAB",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];

	title = @"Armenian";
	nameArray = [NSArray arrayWithObjects:
		@"ARMSCII-8",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Georgian";
	nameArray = [NSArray arrayWithObjects:
		@"Georgian-Academy",
		@"Georgian-PS",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Tajik";
	nameArray = [NSArray arrayWithObjects:
		@"KOI8-T",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];

	title = @"Thai";
	nameArray = [NSArray arrayWithObjects:
		@"TIS-620",
		@"CP874",
		@"MacThai",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Laotian";
	nameArray = [NSArray arrayWithObjects:
		@"MuleLao-1",
		@"CP1133",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];
	
	title = @"Vietnamese";
	nameArray = [NSArray arrayWithObjects:
		@"VISCII",
		@"TCVN",
		@"CP1258",
		nil];
	[self addEncodingItemsWithNames:nameArray withTitle:title toMenu:menu];

	/*
		Platform specifics
		HP-ROMAN8, NEXTSTEP
		
		Full Unicode
		UTF-8 
	 */
	
	return [menu autorelease];
}

- (void)addEncodingItemsWithNames:(NSArray *)inArray withTitle:(NSString *)inTitle toMenu:(NSMenu *)menu
{
	NSEnumerator	*enumerator;
	NSString		*name;
	NSMenuItem		*menuItem;
    BOOL			canIndent = [NSMenuItem instancesRespondToSelector:@selector(setIndentationLevel:)];
	
    menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:inTitle
																	target:nil
																	action:nil
															 keyEquivalent:@""];
	[menuItem setEnabled:NO];
	[menu addItem:menuItem];
	[menuItem release];

	enumerator = [inArray objectEnumerator];
	while ((name = [enumerator nextObject])) {
		menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																		target:nil
																		action:nil
																 keyEquivalent:@""];
		[menuItem setRepresentedObject:name];
		if (canIndent) [menuItem setIndentationLevel:1];

		[menu addItem:menuItem];
		[menuItem release];
	}
}

@end
