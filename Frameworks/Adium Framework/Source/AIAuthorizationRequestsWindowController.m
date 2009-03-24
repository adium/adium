//
//  AIAuthorizationRequestsWindowController.m
//  Adium
//
//  Created by Zachary West on 2009-03-23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AIAuthorizationRequestsWindowController.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define GET_INFO					AILocalizedString(@"Get Info", nil)
#define AUTHORIZE					AILocalizedStringFromTable(@"Authorize", @"Buttons", nil)
#define AUTHORIZE_ADD				AILocalizedStringFromTable(@"Authorize and Add", @"Buttons", nil)
#define DENY						AILocalizedStringFromTable(@"Deny", @"Buttons", nil)

#define MINIMUM_ROW_HEIGHT				42.0 // It's, like, the answer.
#define MAXIMUM_ROW_HEIGHT				300.0
#define MINIMUM_CELL_SPACING			4

@interface AIAuthorizationRequestsWindowController()
- (void)reloadData;

- (void)configureToolbar;
- (void)applyResponse:(AIAuthorizationResponse)response;
@end

@implementation AIAuthorizationRequestsWindowController

static AIAuthorizationRequestsWindowController *sharedController = nil;

+ (AIAuthorizationRequestsWindowController *)sharedController
{
	if (!sharedController) {
		sharedController = [[self alloc] initWithWindowNibName:@"AIAuthorizationRequestsWindow"];
	}
	
	// Make sure our window loads.
	[sharedController showWindow:nil];
	[[sharedController window] makeKeyAndOrderFront:nil];
	
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
	
	[self.window setTitle:AILocalizedString(@"Authorization Requests", nil)];
}

- (void)windowWillClose:(id)sender
{
	[tableView selectAll:nil];	
	[self applyResponse:AIAuthorizationNoResponse];
	
	[sharedController autorelease]; sharedController = nil;
	
	[super windowWillClose:sender];
}

- (void)dealloc
{
	[toolbarItems release];
	[requests release];
	[super dealloc];
}

#pragma mark Toolbar

/*!
 * @brief Configure our toolbar
 */
- (void)configureToolbar
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"AdiumAuthorizeWindow"] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	
	toolbarItems = [[NSMutableDictionary alloc] init];
	
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"authorize"
											 label:AUTHORIZE
									  paletteLabel:AUTHORIZE
										   toolTip:AILocalizedString(@"Authorize Selected",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageForSSL]// just for the sake of having an image; [NSImage imageNamed:@"" forClass:[self class]]
											action:@selector(authorize:)
											  menu:nil];

	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"authorizeAdd"
											 label:AUTHORIZE_ADD
									  paletteLabel:AUTHORIZE_ADD
										   toolTip:AILocalizedString(@"Authorize And Add Selected",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageForSSL]// just for the sake of having an image; [NSImage imageNamed:@"" forClass:[self class]]
											action:@selector(authorizeAdd:)
											  menu:nil];
	
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"getInfo"
											 label:GET_INFO
									  paletteLabel:GET_INFO
										   toolTip:AILocalizedString(@"Get Info",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageForSSL]// just for the sake of having an image; [NSImage imageNamed:@"" forClass:[self class]]
											action:@selector(getInfo:)
											  menu:nil];
	
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"deny"
											 label:DENY
									  paletteLabel:DENY
										   toolTip:AILocalizedString(@"Deny Selected",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageForSSL]// just for the sake of having an image; [NSImage imageNamed:@"" forClass:[self class]]
											action:@selector(deny:)
											  menu:nil];
	
	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
			@"authorize", @"authorizeAdd",
			NSToolbarSeparatorItemIdentifier,
			@"getInfo",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"deny", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
			[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			 NSToolbarSpaceItemIdentifier,
			 NSToolbarFlexibleSpaceItemIdentifier,
			 NSToolbarCustomizeToolbarItemIdentifier, nil]];
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
	
	[self reloadData];
}

/*!
 * @brief Remove requests for a given account
 *
 * Called in the case of, for example, an account going offline. Returns the dict removed.
 */
- (void)removeRequest:(id)request
{
	for (NSDictionary *dict in [[requests mutableCopy] autorelease]) {
		if (dict == request) {
			[requests removeObject:dict];
		}
	}

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
 * @brief Applies the given response to all selected requests
 */
- (void)applyResponse:(AIAuthorizationResponse)response
{
	for (NSDictionary *dict in [[[requests objectsAtIndexes:[tableView selectedRowIndexes]] mutableCopy] autorelease]) {
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
 * Also recalculates the height for the rows.
 */
- (void)reloadData
{
	[tableView reloadData];
	
	[requiredHeightDict removeAllObjects];
	
	for(NSInteger row = 0; row < requests.count; row++) {
		NSTableColumn		*tableColumn = [tableView tableColumnWithIdentifier:@"request"];
		
		[self tableView:tableView willDisplayCell:[tableColumn dataCell] forTableColumn:tableColumn row:row];
		
		// Main string (account name)
		NSDictionary		*mainStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
		NSAttributedString	*mainTitle = [[NSAttributedString alloc] initWithString:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]
																		attributes:mainStringAttributes];
		
		CGFloat combinedHeight = [mainTitle heightWithWidth:[tableColumn width]];
		
		[mainTitle release];
		
		// Substring (the status message)
		NSString *reason = [[requests objectAtIndex:row] objectForKey:@"Reason"];
		
		if (reason) {
			NSDictionary		*subStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10], NSFontAttributeName, nil];
			NSAttributedString	*subStringTitle = [[NSAttributedString alloc] initWithString:[[requests objectAtIndex:row] objectForKey:@"Reason"]
																				 attributes:subStringAttributes];
			
			combinedHeight += [subStringTitle heightWithWidth:[tableColumn width]] + MINIMUM_CELL_SPACING;
			
			[subStringTitle release];
		}

		[requiredHeightDict setObject:[NSNumber numberWithDouble:MIN(MAXIMUM_ROW_HEIGHT, MAX(MINIMUM_ROW_HEIGHT, combinedHeight))]
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
		return [NSString stringWithFormat:AILocalizedString(@"%@ on the account %@", nil),
				[[requests objectAtIndex:rowIndex] objectForKey:@"Remote Name"],
				((AIAccount *)[[requests objectAtIndex:rowIndex] objectForKey:@"Account"]).explicitFormattedUID];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = tableColumn.identifier;
	
	if ([identifier isEqualToString:@"request"]) {
		[(AIImageTextCell *)cell setSubString:[[requests objectAtIndex:rowIndex] objectForKey:@"Reason"]];
	}
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSNumber *cachedHeight = [requiredHeightDict objectForKey:[NSNumber numberWithInteger:row]];
	if (cachedHeight) {
		return [cachedHeight doubleValue];
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
	
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	
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
	
	[menu addItemWithTitle:DENY
					target:self
					action:@selector(deny:)
			 keyEquivalent:@""]; 
	
	return menu;
}

@end
