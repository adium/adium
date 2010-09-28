//
//  AIAdvancedInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import "AIContactInfoContentController.h"

#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>

@class AIAccountMenu, AIContactMenu, AIAccount, AIListContact;

@interface AIAdvancedInspectorPane : NSObject <AIContentInspectorPane, AIAccountMenuDelegate, AIContactMenuDelegate> {
	IBOutlet	NSView							*inspectorContentView;
	
	IBOutlet	NSTextField						*label_account;
	IBOutlet	NSPopUpButton					*popUp_accounts;
	
	IBOutlet	NSTextField						*label_contact;
	IBOutlet	NSPopUpButton					*popUp_contact;
	
	IBOutlet	NSTableView						*tableView_groups;
	IBOutlet	NSButton						*button_addGroup;
	IBOutlet	NSButton						*button_removeGroup;
	
	IBOutlet	NSTextField						*label_encryption;
	IBOutlet	NSPopUpButton					*popUp_encryption;
	
	IBOutlet	NSButton						*checkBox_alwaysShow;
	IBOutlet	NSButton						*checkBox_autoJoin;
	IBOutlet	NSButton						*checkBox_stayInChat;
	
	BOOL										switchingContacts;
	
	AIAccountMenu								*accountMenu;
	AIContactMenu								*contactMenu;
	
	AIAccount									*currentSelectedAccount;
	AIListContact								*currentSelectedContact;
	
	AIListObject								*displayedObject;
}

-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)selectedEncryptionPreference:(id)sender;
- (IBAction)setVisible:(id)sender;
- (IBAction)setAutoJoin:(id)sender;
- (IBAction)setStayInChat:(id)sender;

- (void)removeSelectedGroups:(id)sender;
@end
