#import "AINewBookmarkWindowController.h"
#import "AINewGroupWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIChat.h>
#import <Adium/AIServiceMenu.h>

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>

#define		ADD_BOOKMARK_NIB		@"AddBookmark"
#define		DEFAULT_GROUP_NAME		AILocalizedString(@"Contacts",nil)

@interface AINewBookmarkWindowController ()
- (id)initWithWindowNibName:(NSString *)nibName forChat:(AIChat *)inChat notifyingTarget:(id)inTarget;
- (void)buildGroupMenu;
- (void)newGroup:(id)sender;
- (void)newGroupDidEnd:(NSNotification *)inNotification;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation AINewBookmarkWindowController
/*!
 * @brief Prompt for a new bookmark.
 *
 * @param inChat The chat to bookmark
 * @param parentWindow Window on which to show as a sheet. Pass nil for a panel prompt.
 * @param inTarget The target to send createBookmarkForChat:withName:inGroup: upon success
 *
 * @result An AINewBookmarkWindowController which will manage its own memory
 */
+ (AINewBookmarkWindowController *)promptForNewBookmarkForChat:(AIChat *)inChat onWindow:(NSWindow*)parentWindow notifyingTarget:(id)inTarget
{
	AINewBookmarkWindowController *newBookmarkWindowController = [[self alloc] initWithWindowNibName:ADD_BOOKMARK_NIB
																							 forChat:inChat
																					 notifyingTarget:inTarget];

	if(parentWindow) {
	   [NSApp beginSheet:[newBookmarkWindowController window]
		  modalForWindow:parentWindow
	   	   modalDelegate:newBookmarkWindowController
		  didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			 contextInfo:nil];
	} else {
		[newBookmarkWindowController showWindow:nil];
		[[newBookmarkWindowController window] makeKeyAndOrderFront:nil];
	}
	
	return newBookmarkWindowController;
}

- (id)initWithWindowNibName:(NSString *)nibName forChat:(AIChat *)inChat notifyingTarget:(id)inTarget
{
	if ((self = [super initWithWindowNibName:nibName])) {
		chat = [inChat retain];
		target = [inTarget retain];
	}
	
	return self;
}

- (void)dealloc
{
	[chat release];
	[target release];
	
	[super dealloc];
}

/*!
 *	@brief didEnd selector for the sheet created above, dismisses the sheet
 */
-(void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:nil];
}

/*!
 * @name windowDidLoad
 * @brief the sheet finished loading, populate the group menu with contactlist's groups
 */
-(void)windowDidLoad
{
	[self buildGroupMenu];
	
	if (chat) {
		[textField_name setStringValue:chat.name];
	}
	
	[label_name setLocalizedString:AILocalizedString(@"Name:", nil)];
	[label_group setLocalizedString:AILocalizedString(@"Group:", nil)];
	[button_add setLocalizedString:AILocalizedStringFromTable(@"Add", @"Buttons", nil)];
	[button_cancel setLocalizedString:AILocalizedStringFromTable(@"Cancel", @"Buttons", nil)];
}

/*!
 * @name add
 * @brief User pressed ok on sheet - Calls createBookmarkWithInfo: on the delegate class AIBookmarkController, which creates 
 * a new bookmark with the entered name & moves it to the entered group.
 */
- (IBAction)add:(id)sender
{
	[target createBookmarkForChat:chat
						 withName:[textField_name stringValue]
						  inGroup:[[popUp_group selectedItem] representedObject]];

	[self closeWindow:nil];
}

/*!
 *@brief user pressed cancel on panel -dismisses the sheet
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

//Add to Group ---------------------------------------------------------------------------------------------------------
#pragma mark Add to Group
/*!
 * @brief Build the menu of available destination groups
 */
- (void)buildGroupMenu
{
	NSMenu			*menu;
	//Rebuild the menu
	menu = [adium.contactController groupMenuWithTarget:nil];

	//Add a default group name to the menu if there are no groups listed
	if ([menu numberOfItems] == 0) {
		[menu addItemWithTitle:DEFAULT_GROUP_NAME
						target:nil
						action:nil
				 keyEquivalent:@""];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:[AILocalizedString(@"New Group",nil) stringByAppendingEllipsis]
					target:self
					action:@selector(newGroup:)
			 keyEquivalent:@""];

	[popUp_group setMenu:menu];
	[popUp_group selectItemAtIndex:0];
}

/*!
 * @brief Prompt the user to add a new group immediately
 */
- (void)newGroup:(id)sender
{
	AINewGroupWindowController	*newGroupWindowController;
	
	newGroupWindowController = [AINewGroupWindowController promptForNewGroupOnWindow:[self window]];

	//Observe for the New Group window to close
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(newGroupDidEnd:) 
									   name:@"NewGroupWindowControllerDidEnd"
									 object:[newGroupWindowController window]];	
}
/*!
 * @name newGroupDidEnd:
 * @brief the New Group sheet has ended, if a new group was created, select it, otherwise
 * select the first group.
 */

- (void)newGroupDidEnd:(NSNotification *)inNotification
{
	NSWindow	*window = [inNotification object];

	if ([[window windowController] isKindOfClass:[AINewGroupWindowController class]]) {
		AIListGroup *group = [(AINewGroupWindowController *)[window windowController] group];
		//Rebuild the group menu
		[self buildGroupMenu];
		
		/* Select the new group if it exists; otherwise select the first group (so we don't still have New Group... selected).
		 * If the user cancelled, group will be nil since the group doesn't exist.
		 */
		if (![popUp_group selectItemWithRepresentedObject:group]) {
			[popUp_group selectItemAtIndex:0];			
		}
		
		[[self window] performSelector:@selector(makeKeyAndOrderFront:)
							withObject:self
							afterDelay:0];
	}

	//Stop observing
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:@"NewGroupWindowControllerDidEnd" 
										object:window];
}

@end
