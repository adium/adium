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

#import <Adium/AIWindowController.h>

@class AIAccountProxySettings, AIAccountViewController, AIImageViewWithImagePicker;

@interface AIEditAccountWindowController : AIWindowController {
	//Account preferences
	IBOutlet	NSMatrix					*matrix_userIcon;
	IBOutlet	NSButton					*button_chooseIcon;
	IBOutlet	NSTextField					*textField_accountDescription;
	IBOutlet	NSTextField					*textField_serviceName;
	IBOutlet	AIImageViewWithImagePicker  *imageView_userIcon;
    IBOutlet	NSTabView					*tabView_auxiliary;
	IBOutlet	NSButton					*button_cancel;
	IBOutlet	NSButton					*button_OK;
	IBOutlet	NSButton					*checkbox_autoconnect;
	
	//Replacable views
	IBOutlet	NSView						*view_accountSetup;
	IBOutlet	NSView						*view_accountProxy;
	IBOutlet	NSView						*view_accountProfile;
	IBOutlet	NSView						*view_accountOptions;
	IBOutlet	NSView						*view_accountPrivacy;

	//Current configuration
    AIAccountViewController		*accountViewController;
	AIAccountProxySettings 		*accountProxyController;
	AIAccount					*account;
	
	NSData						*userIconData;
	BOOL						didDeleteUserIcon;
	
	id							notifyTarget;
}

- (void)showOnWindow:(id)parentWindow __attribute__((ns_consumes_self));

- (id)initWithAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)changedIconSetting:(id)sender;

@end

