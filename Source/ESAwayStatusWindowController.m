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

#import "ESAwayStatusWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIStatus.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AITableViewAdditions.h>


#define AWAY_STATUS_WINDOW_NIB					@"AwayStatusWindow"
#define	KEY_AWAY_STATUS_WINDOW_FRAME			@"Away Status Window Frame"

@interface ESAwayStatusWindowController ()
- (void)localizeButtons;
- (void)configureStatusWindow;
- (NSAttributedString *)attributedStatusTitleForStatus:(AIStatus *)statusState withIcon:(NSImage *)statusIcon;
- (NSArray *)awayAccounts;
- (void)setupMultistatusTable;
- (void)statusIconSetChanged:(NSNotification *)inNotification;
@end

/*!
 * @class ESAwayStatusWindowController
 * @brief Window controller for the status window which optionally shows when one or more accounts are away or invisible
 */
@implementation ESAwayStatusWindowController

static ESAwayStatusWindowController	*sharedInstance = nil;
static BOOL							alwaysOnTop = NO;
static BOOL							hideInBackground = NO;

/*!
 * @brief Update the visibility of the status window
 *
 * Opens or closes the window if necessary.
 *
 * If shouldBeVisibile is YES and the window is already visible, updates its contents to reflect the current status.
 * If shouldBeVisible is NO and the window is already not visibile, no action is taken.
 */
+ (void)updateStatusWindowWithVisibility:(BOOL)shouldBeVisible
{
	if (shouldBeVisible) {
		if (sharedInstance) {
			//Update the window's configuration
			[sharedInstance configureStatusWindow];
		} else {
			//Create a new shared instance, which will be configured automatically once the window loads
			sharedInstance = [[self alloc] initWithWindowNibName:AWAY_STATUS_WINDOW_NIB];
			[sharedInstance showWindow:nil];
		}
	
	} else {
		if (sharedInstance) {
			//If the window is current visible, close it
			[sharedInstance closeWindow:nil];
		}
	}
}

+ (void)setAlwaysOnTop:(BOOL)flag
{
	alwaysOnTop = flag;
	
	if (sharedInstance) {
		//Update any open window
		[[sharedInstance window] setLevel:(alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel)];
	}
}

+ (void)setHideInBackground:(BOOL)flag
{
	hideInBackground = flag;
	
	if (sharedInstance) {
		//Update any open window
		[[sharedInstance window] setHidesOnDeactivate:hideInBackground];
	}
}	

/*!
 * @brief Window size and position autosave name
 */
- (NSString *)adiumFrameAutosaveName
{
	return KEY_AWAY_STATUS_WINDOW_FRAME;
}

/*!
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	//Call super first so we get our placement before performing autosizing
	[super windowDidLoad];
	
	[[self window] setLevel:(alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel)];
	[[self window] setHidesOnDeactivate:hideInBackground];

	/* Set a more reasonable minimum size after the window is sized using our nib's specification.
	 * NSPanel behaves oddly with minimum size... it seems to increase the nib-specified minimum by 11.
	 */
	[[self window] setMinSize:NSMakeSize([[self window] minSize].width, 80)];
	
	//Setup the textviews
    [textView_singleStatus setHorizontallyResizable:NO];
    [textView_singleStatus setVerticallyResizable:YES];
    [textView_singleStatus setDrawsBackground:NO];
	[textView_singleStatus setMinSize:NSZeroSize];
    [[textView_singleStatus enclosingScrollView] setDrawsBackground:NO];

	[self localizeButtons];
	[self setupMultistatusTable];

	[self configureStatusWindow];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(statusIconSetChanged:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];	
}

/*!
 * @brief Window will close
 *
 * Release and clear the reference to our shared instance
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	/* Hack of the day.  The table view crashes when the window is released out from under it after it has reloaded data because
	 * it thinks it needs display. It thinks that because we are animating the window's resizing process.  We could do animate:NO
	 * in configureStatusWindow, but that wouldn't be as pretty.
	 */
	[tableView_multiStatus setDataSource:nil];

    //Clean up and release the shared instance
    sharedInstance = nil;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	_awayAccounts = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

/*!
 * @brief Configure status window for the current account status(es)
 */
 - (void)configureStatusWindow
{
	NSWindow		*window = [self window];
	BOOL			allOnlineAccountsAreUnvailable;
	AIStatusType	activeUnvailableStatusType;
	NSString		*activeUnvailableStatusName = nil;
	NSSet			*relevantStatuses;
	NSRect			frame = [window frame];
	NSInteger				newHeight;
	
	[window setTitle:AILocalizedString(@"Current Status",nil)];
	_awayAccounts = nil;

	relevantStatuses = [adium.statusController activeUnavailableStatusesAndType:&activeUnvailableStatusType 
																		 withName:&activeUnvailableStatusName
												   allOnlineAccountsAreUnvailable:&allOnlineAccountsAreUnvailable];
	
	if (allOnlineAccountsAreUnvailable && ([relevantStatuses count] == 1)) {
		//Show the single status tab if all online accounts are unavailable and they are all in the same status state
		NSImage				*statusIcon;
		NSAttributedString	*statusTitle;

		statusIcon = [AIStatusIcons statusIconForStatusName:activeUnvailableStatusName
												  statusType:activeUnvailableStatusType
													iconType:AIStatusIconTab
												  direction:AIIconNormal];
		statusTitle = [self attributedStatusTitleForStatus:[relevantStatuses anyObject]
												  withIcon:statusIcon];
		
		[[textView_singleStatus textStorage] setAttributedString:statusTitle];

		newHeight = [statusTitle heightWithWidth:[textView_singleStatus frame].size.width] + 65;
		frame.origin.y -= (newHeight - frame.size.height);
		frame.size.height = newHeight;
			
		//Select the right tab view item
		[tabView_configuration selectTabViewItemWithIdentifier:@"singlestatus"];
	} else {
		/* Show the multistatus tableview tab if accounts are in different states, which includes the case of only one
		 * away state being in use but not all online accounts currently making use of it.
		 */
		NSInteger				requiredHeight;

		_awayAccounts = [self awayAccounts];

		[tableView_multiStatus reloadData];

		requiredHeight = (([tableView_multiStatus rowHeight] + [tableView_multiStatus intercellSpacing].height) *
						  [_awayAccounts count]);

		newHeight = requiredHeight + 65;
		frame.origin.y -= (newHeight - frame.size.height);
		frame.size.height = newHeight;

		/* Multiple statuses */
		[tabView_configuration selectTabViewItemWithIdentifier:@"multistatus"];
	}
	
	//Perform the window resizing as needed
	[window setFrame:frame display:YES animate:YES];
}

/*!
 * @brief Return the attributed status title for a status
 *
 * This method puts statusIcon into an NSTextAttachment and prefixes statusState's status message or title with it.
 */
- (NSAttributedString *)attributedStatusTitleForStatus:(AIStatus *)statusState withIcon:(NSImage *)statusIcon
{
	NSMutableAttributedString	*statusTitle;
	NSTextAttachment			*attachment;
	NSTextAttachmentCell		*cell;
	NSAttributedString			*statusMessage;
	
	if ((statusMessage = statusState.statusMessage) &&
	   ([statusMessage length])) {
		//Use the status message if it is set
		statusTitle = [statusMessage mutableCopy];
		[[statusTitle mutableString] insertString:@" "
										  atIndex:0];

	} else {
		//If it isn't, use the title
		NSDictionary				*attributesDict;

		attributesDict = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0]
													 forKey:NSFontAttributeName];

		statusTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",[statusState title]]
															  attributes:attributesDict];
	}

	//Insert the image at the beginning
	cell = [[NSTextAttachmentCell alloc] init];
	[cell setImage:statusIcon];

	attachment = [[NSTextAttachment alloc] init];
	[attachment setAttachmentCell:cell];

	[statusTitle insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]
								atIndex:0];

	return statusTitle;
}

/*!
 * @brief Return an array of all away accounts
 */
- (NSArray *)awayAccounts
{	
	NSMutableArray	*awayAccounts = [NSMutableArray array];	

	for (AIAccount *account in adium.accountController.accounts) {
		if (account.online || [account boolValueForProperty:@"isConnecting"]) {
			AIStatus	*statusState = account.statusState;
			if (statusState.statusType != AIAvailableStatusType) {
				[awayAccounts addObject:account];
			}
		}
	}

	return awayAccounts;
}

/*!
 * @brief Return from away
 */
- (IBAction)returnFromAway:(id)sender
{
	NSTabViewItem	*selectedTabViewItem = [tabView_configuration selectedTabViewItem];
	AIStatus		*availableStatusState = [adium.statusController defaultInitialStatusState];

	if ([[selectedTabViewItem identifier] isEqualToString:@"singlestatus"]) {
		//Put all accounts in the Available status state
		//We can perform this on all accounts without fear of bringing them online;
		//Those that are offline will remain offline since -setActiveStatusState considers this.
		[adium.statusController setActiveStatusState:availableStatusState];
	} else {
		//Multistatus
		NSArray	*selectedAccounts;
		
		selectedAccounts = [[tableView_multiStatus selectedItemsFromArray:_awayAccounts] copy];
		
		if ([selectedAccounts count]) {
			//Apply the available status state to only the selected accounts
			[adium.statusController applyState:availableStatusState
									  toAccounts:selectedAccounts];
		} else {
			//No selection: Put all accounts in the Available status state
			//Like above, we can just call -setActiveStatusState and it will handle all accounts.
			[adium.statusController setActiveStatusState:availableStatusState];
		}
	}
}

/*!
 * @brief Perform initial setup for the multistatus table
 */
- (void)setupMultistatusTable
{
	[[tableView_multiStatus tableColumnWithIdentifier:@"status"] setDataCell:[[AIImageTextCell alloc] init]];
}

#pragma mark Multiservice table view datasource
/*!
* @brief Number of rows in the table
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_awayAccounts count];
}

/*!
 * @brief Table values
 *
 * Object value is the account's formatted UID
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	AIAccount	*account = [_awayAccounts objectAtIndex:row];

	return account.formattedUID;
}

/*!
 * @brief Will display a cell
 *
 * Set the image (status icon) and substring (status title) before display.  Cell is an AIImageTextCell.
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	AIAccount	*account = [_awayAccounts objectAtIndex:row];
    
	[cell setImage:[AIStatusIcons statusIconForListObject:account
													 type:AIStatusIconTab
												direction:AIIconNormal]];
	[cell setSubString:[account.statusState title]];
}

- (void)localizeButtons
{
	[button_return setLocalizedString:AILocalizedStringFromTableInBundle(@"Return", 
																		 @"Buttons",
																		 [NSBundle bundleForClass:[self class]],
																		 "Button to return from away in the away status window")];
}

- (void)statusIconSetChanged:(NSNotification *)inNotification
{
	[self configureStatusWindow];
}

@end
