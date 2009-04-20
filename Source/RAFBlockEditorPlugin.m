//
//  RAFBlockEditorPlugin.m
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "RAFBlockEditorPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>

@implementation RAFBlockEditorPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockEditorMenuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Privacy Settings", nil) stringByAppendingEllipsis]
													  target:self
													  action:@selector(showEditor:)
											   keyEquivalent:@"p"];
	[blockEditorMenuItem setKeyEquivalentModifierMask:(NSAlternateKeyMask | NSCommandKeyMask)];
	[adium.menuController addMenuItem:blockEditorMenuItem toLocation:LOC_Adium_Preferences];
}

- (void)uninstallPlugin
{
	[blockEditorMenuItem release];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	for (AIAccount *account in adium.accountController.accounts) {
		if(account.online && [account conformsToProtocol:@protocol(AIAccount_Privacy)])
			return YES;
	}

	return NO;
}

- (IBAction)showEditor:(id)sender
{
	[RAFBlockEditorWindowController showWindow];
}
@end
