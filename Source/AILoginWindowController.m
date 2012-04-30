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


#import "AILoginWindowController.h"
#import "AILoginController.h"
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>

//Preference Keys
#define NEW_USER_NAME		@"New User"		//Default name of a new user
#define LOGIN_WINDOW_NIB	@"LoginSelect"		//Filename of the login window nib

#define	LOGIN_TIMEOUT		10.0

@interface AILoginWindowController ()
- (id)initWithOwner:(id)inOwner windowNibName:(NSString *)windowNibName;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (IBAction)login:(id)sender;
- (IBAction)editUsers:(id)sender;
- (IBAction)doneEditing:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)updateUserList;
- (IBAction)newUser:(id)sender;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (IBAction)deleteUser:(id)sender;
- (void)windowDidLoad;
- (void)disableLoginTimeout;
@end

@implementation AILoginWindowController
// return an instance of AILoginController
+ (AILoginWindowController *)loginWindowControllerWithOwner:(id)inOwner
{
	/* Release self in windowWillClose: */
    return [[self alloc] initWithOwner:inOwner windowNibName:LOGIN_WINDOW_NIB];
}


// Internal --------------------------------------------------------------------------------
// init the login controller
- (id)initWithOwner:(id)inOwner windowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		//Retain our owner
		owner = inOwner;

		//Get the user list
		[self updateUserList];
	}
	return self;
}

// TableView Delegate methods - Return the number of items in the table
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == tableView_userList) {
        return [userArray count];
    } else if (tableView == tableView_editableUserList) {
        return [userArray count];
    } else {
        return 0;
    }
}

// TableView Delegate methods - Return the requested item in the table
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == tableView_userList) {
        return [userArray objectAtIndex:row];
    } else if (tableView == tableView_editableUserList) {
        return [userArray objectAtIndex:row];
    } else {
        return nil;
    }

}

// Log in with the selected user
- (IBAction)login:(id)sender
{
    NSMutableDictionary	*loginDict;
    NSString 		*selectedUserName = [userArray objectAtIndex:[tableView_userList selectedRow]];

    //Open the login preferences
    loginDict = [NSMutableDictionary dictionaryAtPath:[adium applicationSupportDirectory]
                                         withName:LOGIN_PREFERENCES_FILE_NAME
                                           create:YES];

    //Save the 'display on launch' checkbox state
    [loginDict setObject:[NSNumber numberWithBool:[checkbox_displayOnStartup state]] forKey:LOGIN_SHOW_WINDOW];

    //Save the login they used
#if defined (DEBUG_BUILD) && ! defined (RELEASE_BUILD)
    [loginDict setObject:selectedUserName forKey:LOGIN_LAST_USER_DEBUG];
#else
    [loginDict setObject:selectedUserName forKey:LOGIN_LAST_USER];
#endif

#ifndef DEBUG_BUILD
	// If we're not in a debug build, activate debug logging if checked.
	if (checkBox_debugMode.state == NSOnState) {
		AIEnableDebugLogging();
	}
#endif
	
    //Save the login preferences
    [loginDict asyncWriteToPath:[adium applicationSupportDirectory]
					   withName:LOGIN_PREFERENCES_FILE_NAME];

    //Login
    [owner loginAsUser:selectedUserName];
}

// Display the user list edit sheet
- (IBAction)editUsers:(id)sender
{
	[self disableLoginTimeout];

    [NSApp beginSheet:panel_userListEditor modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// Close the user list edit sheet
- (IBAction)doneEditing:(id)sender
{
    [NSApp endSheet:panel_userListEditor];
}

// Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Update/Refresh our user list and outline views
- (void)updateUserList
{
    //Update the reference
    userArray = nil;
    userArray = [owner userArray];

	[tableView_editableUserList reloadData];
	[tableView_userList reloadData];
	
	[tableView_userList scrollRowToVisible:[tableView_userList selectedRow]];
}

// Add a new user
- (IBAction)newUser:(id)sender
{
    NSInteger		newRow;

    //Force the table view to end editing
    [tableView_editableUserList reloadData];

    //Add a new user
    [owner addUser:NEW_USER_NAME];

    //Refresh our user list and outline views
    [self updateUserList];

    //Select, scroll to, and 'edit' the new user
    newRow = [userArray indexOfObject:NEW_USER_NAME];
    [tableView_editableUserList selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    [tableView_editableUserList scrollRowToVisible:newRow];
    [tableView_editableUserList editColumn:0 row:newRow withEvent:nil select:YES];

	[self disableLoginTimeout];
}

// Rename a user
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == tableView_editableUserList) {
        //Rename the user
        [owner renameUser:[userArray objectAtIndex:row] to:object];

        //Refresh our user list
        [self updateUserList];

		if (loginTimer) {
			[loginTimer invalidate]; loginTimer = nil;
		}
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	[self disableLoginTimeout];
}

// Delete the selected user
- (IBAction)deleteUser:(id)sender
{
    //Force the table view to end editing
    [tableView_editableUserList reloadData];

    //Delete the user
    [owner deleteUser:[userArray objectAtIndex:[tableView_editableUserList selectedRow]]];

    //Refresh our user list
    [self updateUserList];

	[self disableLoginTimeout];
}

// set up the window before it is displayed
- (void)windowDidLoad
{
    NSDictionary	*loginDict;
    NSString		*lastLogin;

    //Open the login preferences
    loginDict = [NSDictionary dictionaryAtPath:[adium applicationSupportDirectory]
                                         withName:LOGIN_PREFERENCES_FILE_NAME
                                           create:YES];

    //Center the window
    [[self window] center];

    //Setup the 'display on launch' checkbox
    [checkbox_displayOnStartup setState:[[loginDict objectForKey:LOGIN_SHOW_WINDOW] boolValue]];
	
	//Setup the 'start in debug mode' checkbox
#ifdef DEBUG_BUILD
	//Disabled, checked for debug builds
	checkBox_debugMode.state = NSOnState;
	[checkBox_debugMode setEnabled:NO];	
#else
	checkBox_debugMode.state = NSOffState;
#endif

    //Select the login they used last
#if defined (DEBUG_BUILD) && ! defined (RELEASE_BUILD)
	lastLogin = [loginDict objectForKey:LOGIN_LAST_USER_DEBUG];
#else
    lastLogin = [loginDict objectForKey:LOGIN_LAST_USER];
#endif
	NSIndexSet *rowIndex;
    if (lastLogin != nil && [lastLogin length] != 0 && [userArray indexOfObject:lastLogin] != NSNotFound) {
        rowIndex = [NSIndexSet indexSetWithIndex:[userArray indexOfObject:lastLogin]];
    } else {
		rowIndex = [NSIndexSet indexSetWithIndex:0];
    }
	
	[tableView_userList selectRowIndexes:rowIndex byExtendingSelection:NO];

    //Set login so it's called when the user double clicks a name
    [tableView_userList setDoubleAction:@selector(login:)];

	loginTimer = [NSTimer scheduledTimerWithTimeInterval:LOGIN_TIMEOUT
												   target:self
												 selector:@selector(login:)
												 userInfo:nil
												  repeats:NO];

	[tableView_userList setDelegate:self];
	[tableView_userList setDataSource:self];
	
	[self updateUserList];

}

// called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[loginTimer invalidate]; loginTimer = nil;
}

- (void)disableLoginTimeout
{
	if (loginTimer) {
		[loginTimer invalidate]; loginTimer = nil;
	}
}

@end
