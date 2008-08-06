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

@class AILocalizationTextField, AILocalizationButton;

@interface AINewGroupWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_groupName;
	
	IBOutlet	AILocalizationTextField	*label_groupName;
	IBOutlet	AILocalizationButton	*button_add;
	IBOutlet	AILocalizationButton	*button_cancel;
}

+ (AINewGroupWindowController *)promptForNewGroupOnWindow:(NSWindow *)parentWindow;
- (NSString *)newGroupUID;
- (IBAction)cancel:(id)sender;
- (IBAction)addGroup:(id)sender;

@end
