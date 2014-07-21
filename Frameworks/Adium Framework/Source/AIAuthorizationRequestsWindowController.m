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

#import "AIAuthorizationRequestsWindowController.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/MVMenuButton.h>

#define MINIMUM_ROW_HEIGHT				42.0f // It's, like, the answer.
#define MAXIMUM_ROW_HEIGHT				300.0f
#define MINIMUM_CELL_SPACING			4

@interface AIValidatingToolbarItem : NSToolbarItem {
}
@end

@implementation AIValidatingToolbarItem

- (void)validate {
	if ([self view]) {
		BOOL enabled = YES;
		
		if ([[self toolbar] delegate]) {
			if ([[[self toolbar] delegate] respondsToSelector:@selector(validateToolbarItem:)]) {
				enabled = [(id)[[self toolbar] delegate] validateToolbarItem:self];
			}
		}
		
		[self setEnabled:enabled];
	} else {
		[super validate];
	}
}

@end

@interface AIAuthorizationRequestsWindowController()
- (void)reloadData;
- (void)rebuildHeights;

- (void)configureToolbar;
- (void)applyResponse:(AIAuthorizationResponse)response;

- (void)authorize:(id)sender;
- (void)getInfo:(id)sender;
- (void)deny:(id)sender;
- (void)denyBlock:(id)sender;
- (void)ignore:(id)sender;
- (void)ignoreBlock:(id)sender;
- (void)authorizeAdd:(id)sender;
@end

@implementation AIAuthorizationRequestsWindowController

static AIAuthorizationRequestsWindowController *sharedController = nil;

+ (AIAuthorizationRequestsWindowController *)sharedController
{
	if (!sharedController) {
		sharedController = [[self alloc] initWithWindowNibName:@"AIAuthorizationRequestsWindow"];
	}
	
	return sharedController;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		requests = [[NSMutableArray alloc] init];
		requiredHeightDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

#pragma mark Window control
- (void)windowDidLoad
{
	[self configureToolbar];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(rebuildHeights)
												 name:NSWindowDidResizeNotification
											   object:self.window];
	
	[tableView accessibilitySetOverrideValue:AILocalizedString(@"Authorization Requests", nil)
								forAttribute:NSAccessibilityTitleAttribute];
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	
	[self.window setTitle:AUTHORIZATION_REQUESTS];
}

- (void)windowWillClose:(id)sender 
{
	[super windowWillClose:sender];
	
	// Fade into oblivion only if we don't have any oustanding requests.
	if (!requests.count) {
		sharedController = nil;
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Toolbar

/*!
 * @brief Configure our toolbar
 */
- (void)configureToolbar
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"AdiumAuthorizeWindow"];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	
	toolbarItems = [[NSMutableDictionary alloc] init];
	
	AIValidatingToolbarItem 	*toolbarItem;
	MVMenuButton				*button;
	
	// Authorize
	button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[button setImage:[NSImage imageNamed:@"Authorize" forClass:[self class]]];
	
	toolbarItem = [[AIValidatingToolbarItem alloc] initWithItemIdentifier:AUTHORIZE];
    [toolbarItem setLabel:AUTHORIZE];
    [toolbarItem setPaletteLabel:AUTHORIZE];
	[toolbarItem setToolTip:AILocalizedString(@"Authorize Selected",nil)];
	[toolbarItem setTarget:self];
	[toolbarItem performSelector:@selector(setView:) withObject:button];
	[toolbarItem setAction:@selector(authorize:)];
	[button setToolbarItem:toolbarItem];

	[toolbarItems setObject:toolbarItem forKey:AUTHORIZE];
	
	// Get Info
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:GET_INFO
											 label:GET_INFO
									  paletteLabel:GET_INFO
										   toolTip:AILocalizedString(@"Get Info",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"get-info.tiff"]]
											action:@selector(getInfo:)
											  menu:nil];
	
	// Deny
	button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[button setImage:[NSImage imageNamed:@"Deny" forClass:[self class]]];

	toolbarItem = [[AIValidatingToolbarItem alloc] initWithItemIdentifier:DENY];
	[toolbarItem setLabel:DENY];
    [toolbarItem setPaletteLabel:DENY];
	[toolbarItem setToolTip:AILocalizedString(@"Deny Selected",nil)];
	[toolbarItem setTarget:self];
	[toolbarItem performSelector:@selector(setView:) withObject:button];
	[toolbarItem setAction:@selector(deny:)];
	[button setToolbarItem:toolbarItem];
	
	[toolbarItems setObject:toolbarItem forKey:DENY];
	
	// Ignore
	button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[button setImage:[NSImage imageNamed:@"Ignore" forClass:[self class]]];

	toolbarItem = [[AIValidatingToolbarItem alloc] initWithItemIdentifier:IGNORE];
	[toolbarItem setLabel:IGNORE];
    [toolbarItem setPaletteLabel:IGNORE];
	[toolbarItem setToolTip:AILocalizedString(@"Ignore Selected",nil)];
	[toolbarItem setTarget:self];
	[toolbarItem performSelector:@selector(setView:) withObject:button];
	[toolbarItem setAction:@selector(ignore:)];
	[button setToolbarItem:toolbarItem];

	[toolbarItems setObject:toolbarItem forKey:IGNORE];

	
	[[self window] setToolbar:toolbar];
}

- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if ([[item itemIdentifier] isEqualToString:AUTHORIZE]) {
		NSMenu *menu = [[NSMenu alloc] init];
		
		[menu addItemWithTitle:AUTHORIZE
						target:self
						action:@selector(authorize:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:AUTHORIZE_ADD
						target:self
						action:@selector(authorizeAdd:)
				 keyEquivalent:@""];
		
		[[item view] setMenu:menu];
	} else if ([[item itemIdentifier] isEqualToString:DENY]) {
		NSMenu *menu = [[NSMenu alloc] init];
		
		[menu addItemWithTitle:DENY
						target:self
						action:@selector(deny:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:DENY_BLOCK
						target:self
						action:@selector(denyBlock:)
				 keyEquivalent:@""];
		
		[[item view] setMenu:menu];
	} else if ([[item itemIdentifier] isEqualToString:IGNORE]) {
		NSMenu *menu = [[NSMenu alloc] init];
		
		[menu addItemWithTitle:IGNORE
						target:self
						action:@selector(ignore:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:IGNORE_BLOCK
						target:self
						action:@selector(ignoreBlock:)
				 keyEquivalent:@""];
		
		[[item view] setMenu:menu];
	}
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
			AUTHORIZE,
			NSToolbarSeparatorItemIdentifier,
			GET_INFO,
			NSToolbarFlexibleSpaceItemIdentifier,
			IGNORE, DENY, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
			[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			 NSToolbarSpaceItemIdentifier,
			 NSToolbarFlexibleSpaceItemIdentifier,
			 NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return [tableView numberOfSelectedRows] > 0;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return [tableView numberOfSelectedRows] > 0;
}

#pragma mark Request management
/*!
 * @brief Add a request from a dictionary
 *
 * @param dict The request's dictionary
 *
 * The dictionary should be set up accordingly:
 *
 * @"Account" => AIAccount for this request
 * @"Remote Name" => UID of contact
 * @"Reason" => NSString of reason.
 *
 * Returns a pointer to the dictionary added so libpurple can keep track.
 *
 * The account will be called back with:
 * - (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict response:(AIAuthorizationResponse)authorizationResponse
 */
- (void)addRequestWithDict:(NSDictionary *)dict
{
	NSParameterAssert([dict isKindOfClass:[NSDictionary class]]);
	NSParameterAssert([[dict objectForKey:@"Account"] isKindOfClass:[AIAccount class]]);
	NSParameterAssert([[dict objectForKey:@"Remote Name"] isKindOfClass:[NSString class]]);
	NSParameterAssert(![dict objectForKey:@"Reason"] || [[dict objectForKey:@"Reason"] isKindOfClass:[NSString class]]);
	
	[requests addObject:dict];
	
	[self showWindow:nil];
	
	[self reloadData];
}

/*!
 * @brief Remove requests for a given account
 *
 * Called in the case of, for example, an account going offline.
 */
- (void)removeRequest:(id)request
{
	[requests removeObject:request];

	[self reloadData];
}

/*!
 * @brief Authorize the selected requests.
 */
- (void)authorize:(id)sender
{
	[self applyResponse:AIAuthorizationAllowed];
}

/*!
 * @brief Open an add contact window for the selected requests, then authorize them
 */
- (void)authorizeAdd:(id)sender
{
	for (NSDictionary *dict in [requests objectsAtIndexes:[tableView selectedRowIndexes]]) {
		AIAccount *account = [dict objectForKey:@"Account"];
		
		[adium.contactController requestAddContactWithUID:[dict objectForKey:@"Remote Name"]
												  service:account.service
												  account:account];
	}
	
	[self applyResponse:AIAuthorizationAllowed];
}

/*!
 * @brief Deny the selected requests
 */
- (void)deny:(id)sender
{
	[self applyResponse:AIAuthorizationDenied];
}

/*!
 * @brief Block the contacts of selected requests, then deny them.
 */
- (void)denyBlock:(id)sender
{
	for (NSDictionary *dict in [requests objectsAtIndexes:[tableView selectedRowIndexes]]) {
		AIAccount *account = [dict objectForKey:@"Account"];
		
		AIListContact *contact = [account contactWithUID:[dict objectForKey:@"Remote Name"]];
		
		[contact setIsBlocked:YES updateList:YES];
	}
	
	[self applyResponse:AIAuthorizationDenied];
}

/*!
 * @brief Ignore the selected requests
 */
- (void)ignore:(id)sender
{
	[self applyResponse:AIAuthorizationNoResponse];
}

/*!
 * @brief Block the contacts of selected requests, then ignore them.
 */
- (void)ignoreBlock:(id)sender
{
	for (NSDictionary *dict in [requests objectsAtIndexes:[tableView selectedRowIndexes]]) {
		AIAccount *account = [dict objectForKey:@"Account"];
		
		AIListContact *contact = [account contactWithUID:[dict objectForKey:@"Remote Name"]];
		
		[contact setIsBlocked:YES updateList:YES];
	}

	[self applyResponse:AIAuthorizationNoResponse];
}

/*!
 * @brief Applies the given response to all selected requests
 */
- (void)applyResponse:(AIAuthorizationResponse)response
{
	for (NSDictionary *dict in [[requests objectsAtIndexes:[tableView selectedRowIndexes]] mutableCopy]) {
		AIAccount *account = [dict objectForKey:@"Account"];
		
		[account authorizationWithDict:dict response:response];
		
		[requests removeObject:dict];
	}
	
	[tableView deselectAll:nil];
	[self reloadData];	
}

/*!
  * @brief Posts a notification to get info on the selected object
 */
- (void)getInfo:(id)sender
{
	NSDictionary *selectedItem = [requests objectAtIndex:tableView.selectedRowIndexes.firstIndex];
	
	AIListContact *contact = [[selectedItem objectForKey:@"Account"] contactWithUID:[selectedItem objectForKey:@"Remote Name"]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIShowContactInfo" object:contact];
}

#pragma mark NSTableView data source methods
/*!
 * @brief Reload data
 *
 * Reloads the data and reformats accordingly.
 */
- (void)reloadData
{
	[self rebuildHeights];
	[tableView reloadData];	
}

/*!
 * @brief Rebuild the saved height information.
 */
- (void)rebuildHeights
{
	[requiredHeightDict removeAllObjects];
	
	for(NSInteger row = 0; row < requests.count; row++) {
		NSTableColumn		*tableColumn = [tableView tableColumnWithIdentifier:@"request"];
		
		[self tableView:tableView willDisplayCell:[tableColumn dataCell] forTableColumn:tableColumn row:row];
		
		// Main string (account name)
		NSDictionary		*mainStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
		NSAttributedString	*mainTitle = [[NSAttributedString alloc] initWithString:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]
																		attributes:mainStringAttributes];
		
		CGFloat combinedHeight = [mainTitle heightWithWidth:[tableColumn width]];
		
		// Substring (the status message)
		NSString *reason = [[requests objectAtIndex:row] objectForKey:@"Reason"];
		
		if (reason) {
			NSDictionary		*subStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10], NSFontAttributeName, nil];
			NSAttributedString	*subStringTitle = [[NSAttributedString alloc] initWithString:[[requests objectAtIndex:row] objectForKey:@"Reason"]
																				 attributes:subStringAttributes];
			
			combinedHeight += [subStringTitle heightWithWidth:[tableColumn width]] + MINIMUM_CELL_SPACING;
		}
		
		[tableView setNeedsDisplayInRect:[tableView rectOfRow:row]];
		[tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
		
        CGFloat bottomClampedRowHeight = MAX(MINIMUM_ROW_HEIGHT, combinedHeight);
		[requiredHeightDict setObject:[NSNumber numberWithDouble:MIN(MAXIMUM_ROW_HEIGHT, bottomClampedRowHeight)]
							   forKey:[NSNumber numberWithInteger:row]];
	}
}

/*!
 * @brief The number of rows in our table view.
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return requests.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"icon"]) {
		return [[AIServiceIcons serviceIconForObject:[[requests objectAtIndex:rowIndex] objectForKey:@"Account"]
											   type:AIServiceIconLarge
										   direction:AIIconNormal] imageByScalingToSize:NSMakeSize(MINIMUM_ROW_HEIGHT-2, MINIMUM_ROW_HEIGHT-2)];
	} else if ([identifier isEqualToString:@"request"]) {
		AIAccount *account = [[requests objectAtIndex:rowIndex] objectForKey:@"Account"];
		NSString *displayName = [[requests objectAtIndex:rowIndex] objectForKey:@"Alias"];
		NSString *UID = [[requests objectAtIndex:rowIndex] objectForKey:@"Remote Name"];
		NSString *finalDisplay = nil;
		
		if (displayName && UID) {
			finalDisplay = [NSString stringWithFormat:@"%@ (%@)", displayName, UID];
		} else if (displayName) {
			finalDisplay = displayName;
		} else { // if (UID) {
			finalDisplay = UID;
		}
		
		NSArray *accounts = [adium.accountController accountsCompatibleWithService:account.service];
		
		if (accounts.count > 1) {
			// Only show the account if it's the only one of its type.
			return [NSString stringWithFormat:AILocalizedString(@"%@ on the account %@", nil),
					finalDisplay,
					((AIAccount *)[[requests objectAtIndex:rowIndex] objectForKey:@"Account"]).explicitFormattedUID];	
		} else {
			return finalDisplay;
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = tableColumn.identifier;
	NSDictionary *request = [requests objectAtIndex:rowIndex];
	
	if ([identifier isEqualToString:@"request"]) {
		[(AIImageTextCell *)cell setSubString:[request objectForKey:@"Reason"]];
	} else if ([identifier isEqualToString:@"icon"]) {
		[cell accessibilitySetOverrideValue:[[[request objectForKey:@"Account"] service] longDescription]
							   forAttribute:NSAccessibilityTitleAttribute];
		
		[cell accessibilitySetOverrideValue:@" "
							   forAttribute:NSAccessibilityRoleDescriptionAttribute];		 
	}
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSNumber *cachedHeight = [requiredHeightDict objectForKey:[NSNumber numberWithInteger:row]];
	if (cachedHeight) {
		return (CGFloat)[cachedHeight doubleValue];
	}
	
	// The row should be cached, so this shouldn't be hit.
	return MINIMUM_ROW_HEIGHT;
}

- (NSMenu *)tableView:(NSTableView *)inTableView menuForEvent:(NSEvent *)theEvent
{
	NSIndexSet	*selectedIndexes	= [inTableView selectedRowIndexes];
	NSInteger			mouseRow			= [inTableView rowAtPoint:[inTableView convertPoint:[theEvent locationInWindow] toView:nil]];
	
	//Multiple rows selected where the right-clicked row is in the selection
	if (!selectedIndexes.count || ![selectedIndexes containsIndex:mouseRow]) {
		[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:mouseRow] byExtendingSelection:NO];
	}
	
	if (!inTableView.selectedRowIndexes.count) {
		return nil;
	}
	
	NSMenu *menu = [[NSMenu alloc] init];
	
	if (inTableView.selectedRowIndexes.count == 1) {
		[menu addItemWithTitle:GET_INFO
						target:self
						action:@selector(getInfo:)
				 keyEquivalent:@""];
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	[menu addItemWithTitle:AUTHORIZE
					target:self
					action:@selector(authorize:)
			 keyEquivalent:@""];
	
	[menu addItemWithTitle:AUTHORIZE_ADD
					target:self
					action:@selector(authorizeAdd:)
			 keyEquivalent:@""];

	[menu addItem:[NSMenuItem separatorItem]];

	[menu addItemWithTitle:IGNORE
					target:self
					action:@selector(ignore:)
			 keyEquivalent:@""];
	
	[menu addItemWithTitle:IGNORE_BLOCK
					target:self
					action:@selector(ignoreBlock:)
			 keyEquivalent:@""];	
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:DENY
					target:self
					action:@selector(deny:)
			 keyEquivalent:@""]; 
	
	[menu addItemWithTitle:DENY_BLOCK
					target:self
					action:@selector(denyBlock:)
			 keyEquivalent:@""]; 
	
	return menu;
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self applyResponse:AIAuthorizationNoResponse];
}

@end
