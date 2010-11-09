//
//  OWABSearchWindowController.h
//  Adium
//
//  Created by Ofri Wolfus on 19/07/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

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
