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
#import "AIAutoScrollTextView.h"

@interface LNAboutBoxController : AIWindowController {

@private
	IBOutlet	NSPanel		*panel_licenseSheet;
	IBOutlet	NSTextView	*textView_license;
	
	IBOutlet	NSButton				*button_duckIcon;
	IBOutlet	NSButton				*button_buildButton;
	IBOutlet	NSButton				*button_homepage;
	IBOutlet	NSButton				*button_license;
	IBOutlet	NSTextField				*textField_version;
	IBOutlet	AIAutoScrollTextView	*textView_credits;

	// Version and duck clicking
    NSInteger numberOfDuckClicks, numberOfBuildFieldClicks;
}

+ (LNAboutBoxController *)aboutBoxController;
- (IBAction)adiumDuckClicked:(id)sender;
- (IBAction)buildFieldClicked:(id)sender;
- (IBAction)visitHomepage:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)hideLicense:(id)sender;

@end
