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

@class AILocalizationButton, ABPeoplePickerView, AIService, ABPerson, AIImageViewWithImagePicker;

@interface OWABSearchWindowController : AIWindowController <NSWindowDelegate> {
	//Search View
	IBOutlet ABPeoplePickerView			*peoplePicker;
	
	IBOutlet AILocalizationButton		*selectButton;
	IBOutlet AILocalizationButton		*cancelButton;
	IBOutlet AILocalizationButton		*newPersonButton;
	
	//New Contact View
	IBOutlet NSPanel					*newContactPanel;
	IBOutlet NSPopUpButton				*popUp_contactType;
	
	IBOutlet NSTextField				*textField_contactID;
	IBOutlet NSTextField				*textField_firstName;
	IBOutlet NSTextField				*textField_lastName;
	IBOutlet NSTextField				*textField_nickname;
	IBOutlet NSTextField				*textField_email;
	
	IBOutlet AIImageViewWithImagePicker	*imageView_contactIcon;
	
	IBOutlet AILocalizationTextField	*label_mainTitle;
	IBOutlet AILocalizationTextField	*label_contactType;
	IBOutlet AILocalizationTextField	*label_contactID;
	IBOutlet AILocalizationTextField	*label_secondaryTitle;
	IBOutlet AILocalizationTextField	*label_firstName;
	IBOutlet AILocalizationTextField	*label_lastName;
	IBOutlet AILocalizationTextField	*label_nickname;
	IBOutlet AILocalizationTextField	*label_email;
	IBOutlet AILocalizationTextField	*label_contactIcon;
	
	IBOutlet AILocalizationButton		*addContactButton;
	IBOutlet AILocalizationButton		*addContactCancelButton;
	
	//Other variables
	NSWindow		*carryingWindow;
	id				delegate;
	ABPerson		*person;
	NSString		*screenName;
	AIService		*service;
	NSData			*contactImage;
}

+ (id)promptForNewPersonSearchOnWindow:(NSWindow *)parentWindow initialService:(AIService *)inService;
- (IBAction)select:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)createNewPerson:(id)sender;
- (IBAction)addPerson:(id)sender;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (ABPerson *)selectedPerson;
- (NSString *)selectedScreenName;
- (NSString *)selectedName;
- (NSString *)selectedAlias;
- (AIService *)selectedService;

@end

//Delegate Methods
@interface NSObject (OWABSearchWindowControllerDelegate)
- (void)absearchWindowControllerDidSelectPerson:(OWABSearchWindowController *)controller;
@end

//Notifications
#define OWABSearchWindowControllerDidSelectPersonNotification	@"OWABSearchWindowControllerDidSelectPerson"
