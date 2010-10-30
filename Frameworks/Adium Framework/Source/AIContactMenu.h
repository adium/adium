//
//  AIContactMenu.h
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIAbstractListObjectMenu.h>
#import <Adium/AIContactObserverManager.h>

@class AIAccount, AIListContact, AIListObject;

@protocol AIContactMenuDelegate;

@interface AIContactMenu : AIAbstractListObjectMenu <AIListObjectObserver> {
	AIListObject			*containingObject;
	
	id<AIContactMenuDelegate>						delegate;
	BOOL					delegateRespondsToDidSelectContact;
	BOOL					delegateRespondsToShouldIncludeContact;	
	BOOL					delegateRespondsToValidateContact;
	BOOL					shouldUseDisplayName;
	BOOL					shouldDisplayGroupHeaders;
	BOOL					shouldUseUserIcon;
	BOOL					shouldSetTooltip;
	BOOL					shouldIncludeContactListMenuItem;
	BOOL					populateMenuLazily;
}

+ (id)contactMenuWithDelegate:(id<AIContactMenuDelegate>)inDelegate forContactsInObject:(AIListObject *)inContainingObject;
- (void)setContainingObject:(AIListObject *)inContainingObject;

@property (readwrite, nonatomic, assign) id<AIContactMenuDelegate> delegate;

@end

@protocol AIContactMenuDelegate <NSObject>
- (void)contactMenuDidRebuild:(AIContactMenu *)inContactMenu;
@optional
- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact; 
- (AIListContact *)contactMenu:(AIContactMenu *)inContactMenu validateContact:(AIListContact *)inContact; 
- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact; 
- (BOOL)contactMenuShouldUseUserIcon:(AIContactMenu *)inContactMenu; 
- (BOOL)contactMenuShouldSetTooltip:(AIContactMenu *)inContactMenu; 
- (BOOL)contactMenuShouldIncludeContactListMenuItem:(AIContactMenu *)inContactMenu; 
- (BOOL)contactMenuShouldPopulateMenuLazily:(AIContactMenu *)inContactMenu; 

// Called on each rebuild:
- (BOOL)contactMenuShouldDisplayGroupHeaders:(AIContactMenu *)inContactMenu; //only applies to contained groups
- (BOOL)contactMenuShouldUseDisplayName:(AIContactMenu *)inContactMenu; 
@end
