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

#import "AIContactInfoContentController.h"

@class AIDelayedTextField;

@interface AIAddressBookInspectorPane : NSObject <AIContentInspectorPane> {
	IBOutlet	NSView					*inspectorContentView;
	AIListObject			*displayedObject;
	
	IBOutlet	NSTextField				*label_notes;
	IBOutlet	AIDelayedTextField		*contactNotes;

	IBOutlet	NSButton				*button_chooseCard;

	IBOutlet	NSPanel					*addressBookPanel;
	IBOutlet	ABPeoplePickerView		*addressBookPicker;

	IBOutlet	NSTextField				*label_abPeoplePickerChooseAnAddressCard;
	IBOutlet	NSButton				*button_abPeoplePickerOkay;
	IBOutlet	NSButton				*button_abPeoplePickerCancel;
}
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)setNotes:(id)sender;

//Address Book panel methods.
-(IBAction)runABPanel:(id)sender;
-(IBAction)cardSelected:(id)sender;
-(IBAction)cancelABPanel:(id)sender;

@end
