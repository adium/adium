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

@class AIAccount;

@interface AIGuestAccountWindowController : AIWindowController {
	IBOutlet	NSPopUpButton	*popUp_service;
	IBOutlet	NSTextField		*label_service;
	
	IBOutlet	NSTextField		*textField_name;
	IBOutlet	NSTextField		*label_name;
	
	IBOutlet	NSTextField		*textField_password;
	IBOutlet	NSTextField		*label_password;

	IBOutlet	NSButton		*button_okay;
	IBOutlet	NSButton		*button_cancel;
	IBOutlet	NSButton		*button_advanced;
	
	AIAccount	*account;
}

+ (void)showGuestAccountWindow;

- (IBAction)okay:(id)sender;
- (IBAction)displayAdvanced:(id)sender;

@end
