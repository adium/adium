//
//  AIAddressBookInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIAddressBookInspectorPane.h"
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIDelayedTextField.h>

#define ADDRESS_BOOK_NIB_NAME (@"AIAddressBookInspectorPane")

@implementation AIAddressBookInspectorPane

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		[label_notes setLocalizedString:AILocalizedString(@"Notes:", "Label beside the field for contact notes in the Settings tab of the Get Info window")];
		[button_chooseCard setLocalizedString:[AILocalizedStringFromTable(@"Choose Address Book Card", @"Buttons", "Button title to choose an Address Book card for a contact") stringByAppendingEllipsis]];
		
		[label_abPeoplePickerChooseAnAddressCard setLocalizedString:AILocalizedString(@"Choose an Address Card:", nil)];
		[button_abPeoplePickerOkay setLocalizedString:AILocalizedStringFromTable(@"Choose Card", @"Buttons", nil)];
		[button_abPeoplePickerCancel setLocalizedString:AILocalizedStringFromTable(@"Cancel", @"Buttons", nil)];
	}

	return self;
}

- (void)dealloc
{
	[inspectorContentView release]; inspectorContentView = nil;
	[addressBookPanel release]; addressBookPanel = nil;
	
	[super dealloc];
}

-(NSString *)nibName
{
	return ADDRESS_BOOK_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	NSString	*currentNotes;

	//Hold onto the object, using the highest-up metacontact if necessary
	[displayedObject release];
	displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
				  [(AIListContact *)inObject parentContact] :
				  inObject);
	[displayedObject retain];

	//Current note
    if ((currentNotes = [displayedObject notes])) {
        [contactNotes setStringValue:currentNotes];
    } else {
        [contactNotes setStringValue:@""];
    }
}

- (IBAction)setNotes:(id)sender
{
	if(!displayedObject)
		return;
	
	NSString *currentNote = [contactNotes stringValue];
	[displayedObject setNotes:currentNote];
}

//Address Book Panel methods.
-(IBAction)runABPanel:(id)sender
{
	[NSApp beginSheet:addressBookPanel
	   modalForWindow:[inspectorContentView window]
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) 
		  contextInfo:nil];
}

-(IBAction)cardSelected:(id)sender
{
	//This method will be different during Adium integration, until then we simply print out some details about the ABPerson
	//that has been selected. Pretty simple.
	NSArray *selectedCards = [addressBookPicker selectedRecords];
	
	if ([selectedCards count]) {
		[(AIListContact *)displayedObject setAddressBookPerson:[selectedCards objectAtIndex:0]];
	}

	[NSApp endSheet:addressBookPanel];	
}

-(IBAction)cancelABPanel:(id)sender
{
	//This method simply ends the panel when the user clicks cancel.
	[NSApp endSheet:addressBookPanel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [addressBookPanel orderOut:self];
}


@end
