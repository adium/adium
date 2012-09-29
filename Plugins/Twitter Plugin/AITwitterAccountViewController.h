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

#import <Adium/AIAccountViewController.h>
#import "AITwitterAccountOAuthSetup.h"

@interface AITwitterAccountViewController : AIAccountViewController <AITwitterAccountOAuthSetupDelegate> {
	// Setup - OAuth
	IBOutlet	NSTabView		*tabView_authenticationType;
	IBOutlet	NSTabViewItem	*tabViewItem_basicAuthentication;
	IBOutlet	NSTabViewItem	*tabViewItem_OAuth;
	IBOutlet	NSProgressIndicator *progressIndicator;
	
	IBOutlet	NSTextField		*textField_OAuthStatus;
	IBOutlet	NSTextField		*textField_OAuthVerifier;
	IBOutlet	NSButton		*button_OAuthStart;
	
	// Options
	
	IBOutlet	NSTextField		*textField_APIpath;
	IBOutlet	NSButton		*checkBox_useSSL;
	
	IBOutlet	NSButton		*checkBox_loadContacts;
	
	IBOutlet	NSPopUpButton	*popUp_updateInterval;
	IBOutlet	NSButton		*checkBox_updateAfterSend;
	
	IBOutlet	NSButton		*checkBox_updateGlobalStatus;
	IBOutlet	NSButton		*checkBox_updateGlobalIncludeReplies;
	
	// Personal
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*textField_url;
	IBOutlet	NSTextField		*textField_location;
	IBOutlet	NSTextField		*textField_description;

	// OAuth setup
	AITwitterAccountOAuthSetup	*OAuthSetup;
	AIOAuthSetupStep			OAuthSetupStep;
}

@end
