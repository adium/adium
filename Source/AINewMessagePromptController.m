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

#import "AINewMessagePromptController.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIListContact.h>
#import "AIUserIcons.h"
#import "AIServiceIcons.h"
#import "AIStatusIcons.h"
#import "AIAttributedStringAdditions.h"
#import "AIImageDrawingAdditions.h"

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

static AINewMessagePromptController *sharedNewMessageInstance = nil;

/*!
 * @class AINewMessagePromptController
 * @brief Controller for the New Message prompt, which allows messaging an arbitrary contact
 */
@implementation AINewMessagePromptController

/*!
 * @brief Return our shared instance
 * @result The shared instance
 */
+ (id)sharedInstance 
{
	if (!sharedNewMessageInstance) [self createSharedInstance];
	
	return sharedNewMessageInstance;
}

/*!
 * @brief Create the shared instance
 * @result The shared instance
 */
+ (id)createSharedInstance 
{
	sharedNewMessageInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB];
	
	return sharedNewMessageInstance;
}

/*!
 * @brief Destroy the shared instance
 */
+ (void)destroySharedInstance 
{
	sharedNewMessageInstance = nil;
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[label_from setLocalizedString:AILocalizedString(@"From:",nil)];
	[label_to setLocalizedString:AILocalizedString(@"To:",nil)];
	
	[button_okay setLocalizedString:AILocalizedStringFromTable(@"Message", @"Buttons", "Button title to open a message window the specific contact from the 'New Chat' window")];
	
	[[self window] setTitle:AILocalizedString(@"New Message",nil)];
	
	[table_results setDataSource:self];
	[table_results setDelegate:self];
	[table_results setDoubleAction:@selector(okay:)];
	[table_results setTarget:self];
	
	accountMenu = [AIAccountMenu accountMenuWithDelegate:self
											 submenuType:AIAccountNoSubmenu
										  showTitleVerbs:NO];
}

/*!
 * @brief Open a chat with the desired contact
 */
- (IBAction)okay:(id)sender
{
	AIListContact *contact;
	
	if (account && table_results.selectedRow == results.count) {
		contact = [adium.contactController contactWithService:account.service
													  account:account
														  UID:[field_search stringValue]];
	} else {
		contact = [[results objectAtIndex:[table_results selectedRow]] objectForKey:@"Contact"];
	}
	
	AIChat *chat = [adium.chatController chatWithContact:contact];
	
	[adium.interfaceController openChat:chat];
	
	[adium.interfaceController setActiveChat:chat];
	
	[self closeWindow:nil];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[field_search setStringValue:@""];
	
	results = nil;
	
	[table_results reloadData];
	
	[[self class] destroySharedInstance];
}

- (NSString *)lastAccountIDKey
{
	return @"NewMessagePrompt";
}

- (NSInteger)_string:(NSMutableAttributedString *)astring matchesQuery:(NSString *)query
{
	NSRange matchRange = NSMakeRange(0, astring.length);
	NSInteger i;
	NSInteger score = 0;
	
	for (i = 0; i < query.length; i++) {
		NSString *chr = [query substringWithRange:NSMakeRange(i, 1)];
		
		NSRange newRange = [astring.string rangeOfString:chr options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch range:matchRange];
		
		if (newRange.location == NSNotFound) return NSNotFound;
		
		// Try to approximate Xcode's colors.
		[astring addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
								[NSColor colorWithCalibratedRed:244.0f / 255.0f
														  green:241.0f / 255.0f
														   blue:197.0f / 255.0f
														  alpha:1.0f], NSBackgroundColorAttributeName,
								[NSColor colorWithCalibratedRed:237.0 / 255.0f
														  green:204.0 / 255.0f
														   blue:0.0f
														  alpha:1.0f], NSUnderlineColorAttributeName, nil] range:newRange];
		
		score += newRange.location - matchRange.location;
		
		matchRange.location = newRange.location + 1;
		matchRange.length = astring.length - matchRange.location;
	}
	
	return score;
}

- (IBAction)textUpdated:(id)sender
{
	NSString *query = [field_search stringValue];
	
	if (query.length < 2) {
		results = [NSArray array];
		[table_results reloadData];
		
		return;
	}
	
	NSArray *contacts = [adium.contactController allContacts];
	
	NSMutableArray *matches = [NSMutableArray array];
	
	for (AIListContact *contact in contacts) {
		if (account && contact.account != account) continue;
		if (!contact.account.enabled) continue;
		
		NSMutableAttributedString *UID = [[NSMutableAttributedString alloc] initWithString:contact.UID
																				 attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11.0f]
																														forKey:NSFontAttributeName]];
		NSMutableAttributedString *displayName = [[NSMutableAttributedString alloc] initWithString:contact.displayName];
		
		NSInteger UIDScore = [self _string:UID matchesQuery:query];
		NSInteger nameScore = [self _string:displayName matchesQuery:query];
		NSInteger score = MIN(UIDScore, nameScore);
		
		if (score != NSNotFound) {
			[matches addObject:[NSDictionary dictionaryWithObjectsAndKeys:contact, @"Contact",
								[NSNumber numberWithInteger:score], @"Value",
								UID, @"UID", displayName, @"DisplayName", nil]];
		}
	}
	
	results = [matches sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 objectForKey:@"Value"] compare:[obj2 objectForKey:@"Value"]];
	}];
	
	[table_results reloadData];
}

#pragma mark Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (account && [field_search stringValue].length)
		return results.count + 1;
	else
		return results.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// As a last item, we include the literal query if only one account was selected.
	if (row == results.count) {
		if ([[tableColumn identifier] isEqualToString:@"icon"]) {
			return [AIServiceIcons serviceIconForObject:account
												   type:AIServiceIconLarge
											  direction:AIIconNormal];
		} else {
			NSMutableAttributedString *astring = [[NSMutableAttributedString alloc] initWithString:@"\n"];
			
			[astring appendString:[field_search stringValue] withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11.0f], NSFontAttributeName, [NSNumber numberWithInteger:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
																			 [NSColor colorWithCalibratedRed:244.0f / 255.0f
																									   green:241.0f / 255.0f
																										blue:197.0f / 255.0f
																									   alpha:1.0f], NSBackgroundColorAttributeName,
																			 [NSColor colorWithCalibratedRed:237.0 / 255.0f
																									   green:204.0 / 255.0f
																										blue:0.0f
																									   alpha:1.0f], NSUnderlineColorAttributeName, nil]];
			NSTextAttachment		*attachment;
			NSTextAttachmentCell	*cell;
			NSImage					*serviceIcon = [[AIServiceIcons serviceIconForObject:account
																		type:AIStatusIconTab
																   direction:AIIconNormal] imageByScalingToSize:NSMakeSize(11, 11)];
			
			cell = [[NSTextAttachmentCell alloc] init];
			[cell setImage:serviceIcon];
			
			attachment = [[NSTextAttachment alloc] init];
			[attachment setAttachmentCell:cell];
			
			[astring appendString:@" " withAttributes:nil];
			[astring appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			
			return  astring;
		}
	}
	
	AIListObject *listObject = [[results objectAtIndex:row] objectForKey:@"Contact"];
	
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
		NSImage *userIcon = [AIUserIcons userIconForObject:listObject];
		
		if (!userIcon) {
			userIcon = [AIServiceIcons serviceIconForObject:listObject
													   type:AIServiceIconLarge
												  direction:AIIconNormal];
		}
		
		return userIcon;
	} else {
		NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
		
		[result appendAttributedString:[[results objectAtIndex:row] objectForKey:@"DisplayName"]];
		[result appendString:@"\n" withAttributes:nil];
		
		NSImage *statusIcon = [[AIStatusIcons statusIconForListObject:listObject
																 type:AIStatusIconTab
															direction:AIIconNormal] imageByScalingToSize:NSMakeSize(11, 11)];
		if (statusIcon) {
			NSTextAttachment		*attachment;
			NSTextAttachmentCell	*cell;
			
			cell = [[NSTextAttachmentCell alloc] init];
			[cell setImage:statusIcon];
			
			attachment = [[NSTextAttachment alloc] init];
			[attachment setAttachmentCell:cell];
			
			[result appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			[result appendString:@" " withAttributes:nil];
		}
		
		[result appendAttributedString:[[results objectAtIndex:row] objectForKey:@"UID"]];
		
		NSImage *serviceIcon = [[AIServiceIcons serviceIconForObject:listObject type:AIServiceIconSmall direction:AIIconNormal]
								imageByScalingToSize:NSMakeSize(11, 11)];
		
		if (serviceIcon) {
			NSTextAttachment		*attachment;
			NSTextAttachmentCell	*cell;
			
			cell = [[NSTextAttachmentCell alloc] init];
			[cell setImage:serviceIcon];
			
			attachment = [[NSTextAttachment alloc] init];
			[attachment setAttachmentCell:cell];
			
			[result appendString:@" " withAttributes:nil];
			[result appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
		}
		
		return result;
	}
}

// Move the selection in the table
- (void)move:(NSInteger)diff
{
	NSInteger selectedRow = [table_results selectedRow];
	[table_results selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow + diff] byExtendingSelection:NO];
	[table_results scrollRowToVisible:selectedRow + diff];
}

#pragma mark Text field

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    if (control == field_search && command == @selector(moveUp:)) {
        [self move:-1];
        return YES;
    } else if (control == field_search && command == @selector(moveDown:)) {
        [self move:1];
        return YES;
    } else if (control == field_search && command == @selector(cancelOperation:)) {
        [self closeWindow:nil];
		
		// The search field should clear too, so it doesn't still have contents the next time it's opened
        return NO;
    } else if (control == field_search && command == @selector(insertNewline:)) {
		[self okay:nil];
		return YES;
	}
	
    return NO;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
	[table_results setNeedsDisplay];
}

#pragma mark Account menu

// Account menu delegate
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	[popup_account setMenu:[inAccountMenu menu]];
}

- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return inAccount.online;
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount
{
	account = inAccount;
	
	[self textUpdated:nil];
	
}

- (NSMenuItem *)accountMenuSpecialMenuItem:(AIAccountMenu *)inAccountMenu
{
	NSMenuItem *anyItem = nil;
	int numberOfOnlineAccounts = 0;
	
	for (AIAccount *anAccount in adium.accountController.accounts) {
		if ([self accountMenu:inAccountMenu shouldIncludeAccount:anAccount]) {
			account = anAccount;
			numberOfOnlineAccounts += 1;
			if (numberOfOnlineAccounts > 1) {
				account = nil;
				anyItem = [[NSMenuItem alloc] initWithTitle:
						   AILocalizedStringFromTableInBundle(@"Any",
															  nil,
															  [NSBundle bundleForClass:[AIAccountPlusFieldPromptController class]],
															  nil)
													 action:nil
											  keyEquivalent:@""];
				break;
			}
		}
	}
	
	return anyItem;
}

@end
