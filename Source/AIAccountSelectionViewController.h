//
//  AIAccountSelectionViewController.h
//  Adium
//
//  Created by Thijs Alkemade on 20-10-12.
//  Copyright (c) 2012 The Adium Team. All rights reserved.
//

#import "AIMessageViewTopBarController.h"
#import "AIAccountSelectionView.h"

#import <Adium/AIAccountMenu.h>
#import <Adium/AIContactMenu.h>

#import <Adium/AIChat.h>

@interface AIAccountSelectionViewController : AIMessageViewTopBarController <AIAccountMenuDelegate, AIContactMenuDelegate> {
    IBOutlet AIAccountSelectionView *view_backgroundView;
    IBOutlet NSPopUpButton		*popUp_accounts;
	IBOutlet NSTextField		*label_accounts;
    
	IBOutlet NSPopUpButton   	*popUp_contacts;
	IBOutlet NSTextField		*label_contacts;
	
	AIAccountMenu		*accountMenu;
	AIContactMenu		*contactMenu;
	AIChat				*chat;
    
    BOOL                choicesForContact;
    BOOL                choicesForAccount;
}

- (void)setChat:(AIChat *)chat;

@end
