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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import "ESSendMessageAlertDetailPane.h"
#import "ESSendMessageContactAlertPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIService.h>

@interface ESSendMessageAlertDetailPane ()
- (void)setDestinationContact:(AIListContact *)inContact;
@end

@implementation ESSendMessageAlertDetailPane

//Pane Details
- (NSString *)label{
	return @"";
}
- (NSString *)nibName{
    return @"SendMessageContactAlert";    
}

//Configure the detail view
- (void)viewDidLoad
{
	toContact = nil;
	
	[label_To setLocalizedString:AILocalizedString(@"To:",nil)];
	[label_From setLocalizedString:AILocalizedString(@"From:",nil)];	
	[label_Message setLocalizedString:AILocalizedString(@"Message:",nil)];

	[button_useAnotherAccount setLocalizedString:AILocalizedString(@"Use another account if necessary",nil)];
	
	accountMenu = [AIAccountMenu accountMenuWithDelegate:self
							   submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO];
	//Update 'from' menu
	[popUp_messageFrom setMenu:[accountMenu menu]];
}

- (void)viewWillClose
{
	toContact = nil;
	accountMenu = nil;
	contactMenu = nil;
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	AIAccount			*sourceAccount;
	NSAttributedString  *messageText;
	AIListObject		*destObject = nil;

	//Attempt to find a saved destination object; if none is found, use the one we were passed
	NSString	*destUniqueID = [inDetails objectForKey:KEY_MESSAGE_SEND_TO];
	if (destUniqueID) destObject = [adium.contactController existingListObjectWithUniqueID:destUniqueID];
	if (!destObject) destObject = inObject;
		
	//Configure the destination menu
	contactMenu = [AIContactMenu contactMenuWithDelegate:self forContactsInObject:nil];
	
	if (destObject && [destObject isKindOfClass:[AIListContact class]]) {
		[self setDestinationContact:(AIListContact *)destObject];
	} else {
		[self setDestinationContact:nil];
	}
	
	//Configure the remaining controls
	id accountID = [inDetails objectForKey:KEY_MESSAGE_SEND_FROM];
	if (![accountID isKindOfClass:[NSString class]]) {
		//Old code stored this as an NSNumber; upgrade.
		if ([accountID isKindOfClass:[NSNumber class]]) {
			accountID = [NSString stringWithFormat:@"%i",[(NSNumber *)accountID intValue]];
		} else {
			accountID = nil; //Unrecognizable, ignore
		}
	}

	if ((sourceAccount = [adium.accountController accountWithInternalObjectID:(NSString *)accountID])) {
		[popUp_messageFrom selectItemWithRepresentedObject:sourceAccount];
	}
	
	if ((messageText = [NSAttributedString stringWithData:[inDetails objectForKey:KEY_MESSAGE_SEND_MESSAGE]])) {
		[[textView_message textStorage] setAttributedString:messageText];
	} else {
		[textView_message setString:@""];
	}

	[button_useAnotherAccount setState:[[inDetails objectForKey:KEY_MESSAGE_OTHER_ACCOUNT] boolValue]];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSDictionary	*actionDetails;

	if (toContact &&
		[popUp_messageFrom numberOfItems] && [popUp_messageFrom selectedItem]) {
		actionDetails = [NSDictionary dictionaryWithObjectsAndKeys:
			toContact.internalObjectID, KEY_MESSAGE_SEND_TO,
			[[[popUp_messageFrom selectedItem] representedObject] internalObjectID], KEY_MESSAGE_SEND_FROM,
			[NSNumber numberWithBool:[button_useAnotherAccount state]], KEY_MESSAGE_OTHER_ACCOUNT,
			[[textView_message textStorage] dataRepresentation], KEY_MESSAGE_SEND_MESSAGE,
			nil];
	} else {
		actionDetails = nil;
	}
	
	return actionDetails;
}

//Set our destination contact
- (void)setDestinationContact:(AIListContact *)inContact
{
	if (inContact != toContact) {
		NSMenuItem	*firstMenuItem;
		AIAccount	*preferredAccount;
		
		toContact = inContact;
		
		//NSPopUpButton doesn't handle submenus well at all. We put a blank menu item at the top of our
		//menu when we created it. We can now change its attributes to affect the way the unclicked button
		//displays.
		firstMenuItem = (NSMenuItem *)[[popUp_messageTo menu] itemAtIndex:0];
		[firstMenuItem setTitle:([toContact isKindOfClass:[AIMetaContact class]] ?
								 toContact.displayName :
								 toContact.formattedUID)];
		[firstMenuItem setImage:[AIUserIcons menuUserIconForObject:toContact]];
		[popUp_messageTo selectItemAtIndex:0];
		
		//Select preferred account
		preferredAccount = [adium.accountController preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																							   toContact:toContact];
		if (preferredAccount) [popUp_messageFrom selectItemWithRepresentedObject:preferredAccount];

		//Rebuild the account menu to be appropriate
		[accountMenu rebuildMenu];
	}
}

- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact
{
	[self setDestinationContact:inContact];
	
	[self detailsForHeaderChanged];
}

- (void)contactMenuDidRebuild:(AIContactMenu *)inContactMenu 
{
	NSMenu *tempMenu = [inContactMenu menu];
	[tempMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
	[popUp_messageTo setMenu:tempMenu];
	
	[popUp_messageTo synchronizeTitleAndSelectedItem];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popUp_messageFrom setMenu:[accountMenu menu]];

	[popUp_messageFrom synchronizeTitleAndSelectedItem];
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	BOOL		shouldInclude = NO;
	NSString	*accountServiceClass = inAccount.service.serviceClass;

	if ([toContact isKindOfClass:[AIMetaContact class]]) {
		NSEnumerator	*enumerator;
		AIListContact	*listContact;
		
		enumerator = [((AIMetaContact *)toContact).uniqueContainedObjects objectEnumerator];
		while ((listContact = [enumerator nextObject]) && !shouldInclude) {
			shouldInclude = [accountServiceClass isEqualToString:listContact.service.serviceClass];
		}

	} else {
		shouldInclude = [accountServiceClass isEqualToString:toContact.service.serviceClass];
	}
	
	return shouldInclude;
}

@end
