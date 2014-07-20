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
#import <Adium/AIContactObserverManager.h>

#define PREF_GROUP_ADD_CONTACT  @"Add Contact"
#define KEY_ADD_CONTACT_TO		@"Add Contacts to account"

@class AIAccount, AIService, AILocalizationButton, AILocalizationTextField;
@class ABPerson;

@interface AINewContactWindowController : AIWindowController <AIListObjectObserver> {
	IBOutlet	NSPopUpButton				*popUp_contactType;
	IBOutlet	NSPopUpButton				*popUp_targetGroup;
	IBOutlet	NSTextField					*textField_contactName;
	IBOutlet	NSTextField					*textField_contactAlias;
	IBOutlet	NSTableView					*tableView_accounts;
	IBOutlet	NSImageView					*imageView_service;

	IBOutlet	AILocalizationButton		*button_add;
	IBOutlet	AILocalizationButton		*button_cancel;

	IBOutlet	AILocalizationTextField		*textField_type;
	IBOutlet	AILocalizationTextField		*textField_alias;
	IBOutlet	AILocalizationTextField		*textField_inGroup;
	IBOutlet	AILocalizationTextField		*textField_addToAccounts;
	IBOutlet	NSTextField					*textField_contactNameLabel;
	
	IBOutlet	AILocalizationTextField		*textField_searchInAB;

	NSArray							*accounts;
	NSMutableSet					*checkedAccounts;
	NSString						*contactName;
	AIService						*service;
	AIAccount						*initialAccount;
	ABPerson						*person;
	NSString						*groupName;
}

- (id)initWithContactName:(NSString *)inName service:(AIService *)inService account:(AIAccount *)inAccount;
- (id)initWithGroupName:(NSString *)inGroup;
- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;
- (IBAction)searchInAB:(id)sender;

@end
