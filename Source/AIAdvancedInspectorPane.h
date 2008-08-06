//
//  AIAdvancedInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringFormatter.h>
#import <AIContactInfoContentController.h>

//imports from old accounts pane
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AILocalizationTextField.h>
#import <Adium/AIMetaContact.h>

@class AIAccountMenu;

@interface AIAdvancedInspectorPane : NSObject <AIContentInspectorPane> {
	IBOutlet	NSView							*inspectorContentView;
	
	IBOutlet	AIAlternatingRowTableView		*accountsTableView;
	IBOutlet	NSTableColumn					*contactsColumn;
	
	IBOutlet	NSTextField						*label_account;
	IBOutlet	NSPopUpButton					*popUp_accounts;
	
	IBOutlet	NSTextField						*label_encryption;
	IBOutlet	NSPopUpButton					*popUp_encryption;
	
	IBOutlet	NSButton						*checkBox_alwaysShow;
	
	AIAccountMenu	*accountMenu;
	
	AIListObject					*displayedObject;
	NSArray							*accounts;
	NSArray							*contacts;
	BOOL							contactsColumnIsInAccountsTableView;
	
	BOOL							rebuildingContacts;
}

-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)selectedEncryptionPreference:(id)sender;
- (IBAction)setVisible:(id)sender;

@end
