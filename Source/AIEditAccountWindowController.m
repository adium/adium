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

#import <Adium/AIAccountControllerProtocol.h>
#import "AIAccountProxySettings.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountViewController.h>
#import <Adium/AIService.h>

@interface AIEditAccountWindowController ()
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount;
- (void)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier
		runningHeight:(NSInteger *)height width:(NSInteger *)width;
- (void)_removeCustomViewAndTabs;
- (void)_localizeTabViewItemLabels;
- (void)saveConfiguration;
- (void)configureControlDimming;
@end

/*!
 * @class AIEditAccountWindowController
 * @brief Window controller for configuring an <tt>AIAccount</tt>
 */
@implementation AIEditAccountWindowController

/*!
 * @brief Init the window controller
 */
- (id)initWithAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget
{
	if ((self = [super initWithWindowNibName:@"EditAccountSheet"])) {
		account = inAccount;
		notifyTarget = inTarget;
		userIconData = nil;
		didDeleteUserIcon = NO;
	}
	return self;
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] center];
	
	[[self window] setTitle:AILocalizedString(@"Edit Account", nil)];

	//Account Overview
	[textField_serviceName setStringValue:[account.service longDescription]];
	[textField_accountDescription setStringValue:account.UID];

	[button_chooseIcon setLocalizedString:[AILocalizedString(@"Choose Icon",nil) stringByAppendingEllipsis]];
	[button_OK setLocalizedString:AILocalizedString(@"OK",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];
	[checkbox_autoconnect setLocalizedString:AILocalizedString(@"Connect when Adium opens", "Account preferences checkbox for automatically conencting the account when Adium opens")];

	[[matrix_userIcon cellWithTag:0] setTitle:AILocalizedString(@"Use global icon", "Radio button in the Personal tab of Account preferences.  This -must- be a short string of 20 characters or less.")];
	[[matrix_userIcon cellWithTag:1] setTitle:AILocalizedString(@"Use this icon:", "Radio button in the Personal tab of Account preferences; an image is shown beneath it to select the account's icon.  This -must- be a short string of 20 characters or less.")];
	
	//User icon
	if ([[account preferenceForKey:KEY_USE_USER_ICON group:GROUP_ACCOUNT_STATUS] boolValue]) {
		//If this account has the preference set, use its user icon.
		[matrix_userIcon selectCellWithTag:1];

	} else {
		//Otherwise it is using the global icon
		[matrix_userIcon selectCellWithTag:0];
	}

	[imageView_userIcon setMaxSize:NSMakeSize(256, 256)];
	[imageView_userIcon setImage:[account userIcon]];

	[checkbox_autoconnect setState:[[account preferenceForKey:KEY_AUTOCONNECT
														group:GROUP_ACCOUNT_STATUS] boolValue]];

	//Insert the custom controls for this account
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForAccount:account];
	[self _localizeTabViewItemLabels];
	
	[self configureControlDimming];
}

- (IBAction)showWindow:(id)sender {
	[super showWindow:sender];
	if([notifyTarget respondsToSelector:@selector(editAccountWindow:didOpenForAccount:)])
		[notifyTarget editAccountWindow:[self window] didOpenForAccount:account];
}

- (void)configureControlDimming
{
	BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);
	
	[imageView_userIcon setEnabled:enableUserIcon];
	[button_chooseIcon setEnabled:enableUserIcon];
}

/*!
 * @brief The user changed the selection in the icon setting matrix which determines availability of the icon controls
 */
- (IBAction)changedIconSetting:(id)sender
{
	[self configureControlDimming];
}

/*!
 * @brief Cancel
 *
 * Close without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	if (notifyTarget) [notifyTarget editAccountSheetDidEndForAccount:account withSuccess:NO];
	[self closeWindow:nil];
}

/*!
 * @brief Okay.
 *
 * Save changes and close.
 */
- (IBAction)okay:(id)sender
{
	[self saveConfiguration];
	[accountViewController saveConfiguration];
	[accountProxyController saveConfiguration];
	
	[account accountEdited];

	if (notifyTarget) [notifyTarget editAccountSheetDidEndForAccount:account withSuccess:YES];
	[self closeWindow:nil];
}

/*!
 * @brief Save any configuration managed by the window controller
 *
 * Most configuration is handled by the custom view controllers.  Save any other configuration, such as the user icon.
 */
- (void)saveConfiguration
{
	BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);

	if (!enableUserIcon) {
		userIconData = nil;
		didDeleteUserIcon = YES;
	}

	/* User icon - save if we have data or we deleted
	 * (so if we don't have data that's the desired thing to set as the pref) */
	if (userIconData || didDeleteUserIcon) {
		[account setPreference:userIconData
						forKey:KEY_USER_ICON
						 group:GROUP_ACCOUNT_STATUS];
	}
	
	[account setPreference:[NSNumber numberWithBool:[[matrix_userIcon selectedCell] tag]]
					forKey:KEY_USE_USER_ICON
					 group:GROUP_ACCOUNT_STATUS];

	[account setPreference:[NSNumber numberWithBool:[checkbox_autoconnect state]]
					forKey:KEY_AUTOCONNECT
					 group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Add the custom views for an account
 */
- (void)_addCustomViewAndTabsForAccount:(AIAccount *)inAccount
{
	NSRect	windowFrame = [[self window] frame];
	NSInteger		baseHeight = NSHeight([view_accountSetup frame]);
	NSInteger		baseWidth = NSWidth([view_accountSetup frame]);
	NSInteger		newHeight = baseHeight, newWidth = baseWidth;

	//Configure our account and proxy view controllers
	accountViewController = [inAccount.service accountViewController];
	[accountViewController configureForAccount:inAccount];

	accountProxyController = ([inAccount.service supportsProxySettings] ?
							  [[AIAccountProxySettings alloc] init] :
							  nil);
	[accountProxyController configureForAccount:inAccount];

	//Account setup view
	[self _addCustomView:[accountViewController setupView]
				  toView:view_accountSetup
   tabViewItemIdentifier:@"account"
		 runningHeight:&newHeight
				   width:&newWidth];
	
	//Account Profile View
	[self _addCustomView:[accountViewController profileView]
				  toView:view_accountProfile
   tabViewItemIdentifier:@"profile"
		 runningHeight:&newHeight
				   width:NULL];
	
	//Account Options view
	[self _addCustomView:[accountViewController optionsView]
				  toView:view_accountOptions
   tabViewItemIdentifier:@"options"
		 runningHeight:&newHeight
				   width:&newWidth];
	
	//Account Privacy view
	[self _addCustomView:[accountViewController privacyView]
				  toView:view_accountPrivacy
   tabViewItemIdentifier:@"privacy"
		 runningHeight:&newHeight
				   width:&newWidth];
	
	//Add proxy view
	[self _addCustomView:[accountProxyController view]
				  toView:view_accountProxy
   tabViewItemIdentifier:@"proxy"
		 runningHeight:&newHeight
				   width:&newWidth];
	
	//Resize our window as necessary to make room for the custom views
	windowFrame.size.height += newHeight - baseHeight;
	windowFrame.size.width += newWidth - baseWidth;

	[[self window] setFrame:windowFrame display:YES];

	//Responder chains are a pain in 10.3.  The tab view will set them up correctly when we switch tabs, but doesn't
	//get a chance to setup the responder chain for our default tab.  A quick hack to get the tab view to set things
	//up correctly is to switch tabs away and then back to our default.  This causes little harm, since our window
	//isn't visible at this point anyway.
	//XXX - I believe we're getting a method that will avoid the need for this hack in 10.4 -ai
	[tabView_auxiliary selectLastTabViewItem:nil];
	[tabView_auxiliary selectFirstTabViewItem:nil];
}

/*!
 * @brief Used when configuring to add custom views and remove tabs as necessary
 *
 * Add customView to setupView and return the height difference between the two if customView is taller than setupView.
 * Remove the tabViewItem with the passed identifier if no customView exists, avoiding empty tabs.
 *
 * @param customView The view to add
 * @param setupView The view within our nib which will be filled by customView
 * @param identifier Identifier of the <tt>NSTabViewItem</tt> which will be removed from tabView_auxiliary if customView == nil
 * @param requiredHeight The current required view height to display all our views
 * @result The new required window height to display our existing views and the newly added view
 */
- (void)_addCustomView:(NSView *)customView toView:(NSView *)setupView tabViewItemIdentifier:(NSString *)identifier
	  runningHeight:(NSInteger *)height width:(NSInteger *)width
{
	if (customView) {
		//Adjust height as necessary if our view needs more room
		if (NSHeight([customView frame]) > *height) {
			*height = NSHeight([customView frame]);
		}

		//Adjust height as necessary if our view needs more room
		if (width && (NSWidth([customView frame]) > *width)) {
			*width = NSWidth([customView frame]);
		}
		
		//Align our view to the top and insert it into the window
		if (width && (NSWidth([setupView frame]) > NSWidth([customView frame])))
			[customView setFrameOrigin:NSMakePoint(AIfloor((NSWidth([setupView frame]) - NSWidth([customView frame])) / 2),
												   NSHeight([setupView frame]) - NSHeight([customView frame]))];
		else
			[customView setFrameOrigin:NSMakePoint(0,
												   NSHeight([setupView frame]) - NSHeight([customView frame]))];

		[customView setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin | NSViewMaxXMargin)];
		[setupView addSubview:customView];

	} else {
		//If no view is available, remove the corresponding tab
		[tabView_auxiliary removeTabViewItem:[tabView_auxiliary tabViewItemWithIdentifier:identifier]];
	}
}

/*!
 * @brief Remove any existing custom views
 */
- (void)_removeCustomViewAndTabs
{
    //Close any currently open controllers
    [view_accountSetup removeAllSubviews];
	accountViewController = nil;
}

/*!
 * @brief Localization
 */
- (void)_localizeTabViewItemLabels
{
	[[tabView_auxiliary tabViewItemWithIdentifier:@"account"] setLabel:AILocalizedString(@"Account",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"profile"] setLabel:AILocalizedString(@"Personal",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"options"] setLabel:AILocalizedString(@"Options",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"privacy"] setLabel:AILocalizedString(@"Privacy",nil)];
	[[tabView_auxiliary tabViewItemWithIdentifier:@"proxy"] setLabel:AILocalizedString(@"Proxy",nil)];
}


// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
#pragma mark AIImageViewWithImagePicker Delegate
- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	userIconData = nil;
	didDeleteUserIcon = YES;

	//User icon - restore to the default icon
	[imageView_userIcon setImage:[account userIcon]];
	
	//We're now using the global icon
	[matrix_userIcon selectCellWithTag:0];
}

- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	userIconData = imageData;
	
	if (!userIconData) {
		//If we got a nil user icon, that means the icon was deleted
		[self deleteInImageViewWithImagePicker:sender];
	}
}

- (NSString *)fileNameForImageInImagePicker:(AIImageViewWithImagePicker *)picker
{
	NSString *fileName = [account.displayName safeFilenameString];
	if ([fileName hasPrefix:@"."]) {
		fileName = [fileName substringFromIndex:1];
	}
	return fileName;
}

- (NSImage *)emptyPictureImageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return [AIServiceIcons serviceIconForObject:account type:AIServiceIconLarge direction:AIIconNormal];
}

@end
