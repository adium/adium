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

// $Id$

#import "AILoginController.h"
#import "AILoginWindowController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIEventAdditions.h>

//Paths & Filenames
#define PATH_USERS 			@"/Users"		//Path of the users folder

//Other
#define DEFAULT_USER_NAME		@"Default"		//The default user name

@implementation AILoginController

// Init this controller
- (id)init
{
	if ((self = [super init])) { 
		userDirectory = nil;
	}
	
	return self;
}

- (void)controllerDidLoad
{
}

// Close this controller
- (void)controllerWillClose
{

}

// Dealloc
- (void)dealloc
{
    [userDirectory release];
    [currentUser release];

    [super dealloc];
}

// Prompts for a user, or automatically selects one
- (void)requestUserNotifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSMutableDictionary	*loginDict;
	NSArray				*arguments;
	unsigned			argumentIndex;
	NSString			*userName = nil;
	
    //Retain the target and selector
    target = inTarget;
    selector = inSelector;

    //Open the login preferences
    loginDict = [NSMutableDictionary dictionaryAtPath:[adium applicationSupportDirectory] withName:LOGIN_PREFERENCES_FILE_NAME create:YES];

    //Make sure that atleast 1 login name is available.  If not, create the name 'default'
    if ([[self userArray] count] == 0) {
        //Create a 'default' user
        [self addUser:DEFAULT_USER_NAME];

        //Set 'default' as the login of choice
        [loginDict setObject:DEFAULT_USER_NAME forKey:LOGIN_LAST_USER];
		[loginDict writeToPath:[adium applicationSupportDirectory] withName:LOGIN_PREFERENCES_FILE_NAME];
    }
	
	//Retrieve the desired user from the command line if possible
	arguments = [[NSProcessInfo processInfo] arguments];
	if (arguments && ([arguments count] > 1)) {
		
		argumentIndex = [arguments indexOfObject:@"--user"];
		if ((argumentIndex != NSNotFound) && ([arguments count] > argumentIndex + 1)) {
			userName = [[[arguments objectAtIndex:argumentIndex+1] copy] autorelease];
		}
	}

    /*
	 If we don't have a userName yet, show the login select window if:
		- Option is held down
		- We should always show it
			or
		- LOGIN_LAST_USER does not indicate a valid user
	 */
	if (!userName) {
		BOOL userRequestedShowWindow = NO;
		
		if (([NSEvent optionKey]) ||
		   (userRequestedShowWindow = [[loginDict objectForKey:LOGIN_SHOW_WINDOW] boolValue]) || 
		   (!(userName = [loginDict objectForKey:LOGIN_LAST_USER]))) {

			//Prompt for the user
			loginWindowController = [[AILoginWindowController loginWindowControllerWithOwner:self] retain];
			[loginWindowController showWindow:nil];
			
			//If the user always wants to see the window, disable the login timeout
			if (userRequestedShowWindow) [loginWindowController disableLoginTimeout];
		}
    }

	
	if (userName) {
		[self loginAsUser:userName];
	}
}

// Returns the current user's Adium home directory
- (NSString *)userDirectory
{
    return userDirectory;
}

//
- (NSString *)currentUser
{
    return currentUser;
}

// Sets the correct user directory and sends out a login message
- (void)loginAsUser:(NSString *)userName
{
    NSParameterAssert(userName != nil);
    
    //Close the login panel
    if (loginWindowController) {
        [loginWindowController closeWindow:nil];
        [loginWindowController release]; loginWindowController = nil;
    }

    //Save the user directory
    currentUser = [userName retain];
    userDirectory = [[[[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:userName] retain];
    
    //Tell Adium to complete login
    [target performSelector:selector];
}

// Creates and returns a mutable array of the login users
- (NSArray *)userArray
{
    NSString		*userPath;
    NSArray			*directoryContents;
    NSMutableArray	*userArray;
    int				loop;
	unsigned		count;
    BOOL			isDirectory;

    //Get the users path
    userPath = [[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS];

    //Build the user array
    userArray = [[NSMutableArray alloc] init];

    directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:userPath];
	count = [directoryContents count];
    for (loop = 0;loop < count;loop++) {
        NSString	*path = [directoryContents objectAtIndex:loop];

        //Fetch the names of all directories
        if ([[NSFileManager defaultManager] fileExistsAtPath:[userPath stringByAppendingPathComponent:path] isDirectory:&isDirectory]) {
            if (isDirectory) {
                [userArray addObject:[path lastPathComponent]];
            }
        }
    }

    return [userArray autorelease];
}

// Delete a user
- (void)deleteUser:(NSString *)inUserName
{
    NSString	*sourcePath;

    NSParameterAssert(inUserName != nil);

    //Create the source and dest paths	
    sourcePath = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
	[[NSFileManager defaultManager] trashFileAtPath:sourcePath];
}

// Add a user with the specified name
- (void)addUser:(NSString *)inUserName
{
    NSString	*userPath;
    
    NSParameterAssert(inUserName != nil);

    //Create the user path
    userPath = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
    
    //Create a folder for the new user
    [[NSFileManager defaultManager] createDirectoriesForPath:userPath];
}

// Rename an existing user
- (void)renameUser:(NSString *)oldName to:(NSString *)newName
{
    NSString	*sourcePath, *destPath;

    NSParameterAssert(oldName != nil);
    NSParameterAssert(newName != nil);

    //Create the source and dest paths
    sourcePath = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:oldName];
    destPath = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:newName];

    //Rename the user's folder (by moving it to a path with a different name)
    [[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil];
}

@end

