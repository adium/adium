//
//  ESPurpleQQAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 8/7/06.
//

#import "ESPurpleQQAccountViewController.h"
#import "ESPurpleQQAccount.h"

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

@interface ESPurpleQQAccountViewController()
- (NSMenu *)clientVersionMenu;
@end

@implementation ESPurpleQQAccountViewController
- (NSString *)nibName{
    return @"PurpleQQAccountView";
}

/*!
 * @brief Awake from nib
 */
- (void)awakeFromNib
{
	[super awakeFromNib];
	[popUp_clientVersion setMenu:[self clientVersionMenu]];
}


//Configure controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];

	[checkBox_useTCP setState:[[account preferenceForKey:KEY_QQ_USE_TCP 
												   group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_useTCP setLocalizedString:AILocalizedString(@"Connect using TCP", nil)];

	[label_connection setLocalizedString:AILocalizedString(@"Connection:", nil)];
	
	[label_clientVersion setLocalizedString:AILocalizedString(@"Client Version:", nil)];
	
	[popUp_clientVersion selectItemWithRepresentedObject:[inAccount preferenceForKey:KEY_QQ_CLIENT_VERSION
																			   group:GROUP_ACCOUNT_STATUS]];
}

//Save controls
- (void)saveConfiguration
{
	[account setPreference:[NSNumber numberWithBool:[checkBox_useTCP state]] 
					forKey:KEY_QQ_USE_TCP group:GROUP_ACCOUNT_STATUS];
	
	[account setPreference:[[popUp_clientVersion selectedItem] representedObject]
					forKey:KEY_QQ_CLIENT_VERSION
					 group:GROUP_ACCOUNT_STATUS];

	[super saveConfiguration];
}

- (NSMenu *)clientVersionMenu
{
	NSMenu			*clientVersionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSDictionary	*clientVersionDict = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"2008", @"qq2008",
										  @"2007", @"qq2007",
										  @"2005", @"qq2005",
										  nil];
	
	for (NSString *prefix in clientVersionDict.allKeys) {
		[clientVersionMenu addItemWithTitle:[clientVersionDict objectForKey:prefix]
									 target:nil
									 action:nil
							  keyEquivalent:@""
						  representedObject:prefix];
	}

	return [clientVersionMenu autorelease];
}

@end
