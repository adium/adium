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
#ifdef DEBUG_BUILD

#import "ESDebugController.h"
#import "ESDebugWindowController.h"

#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>

#include <fcntl.h>  //open(2)
#include <unistd.h> //close(2)
#include <errno.h>  //errno
#include <string.h> //strerror(3)

#define	CACHED_DEBUG_LOGS		100		//Number of logs to keep at any given time
#define	KEY_DEBUG_WINDOW_OPEN	@"Debug Window Open"

@implementation ESDebugController

static ESDebugController	*sharedDebugController = nil;

- (id)init
{
	if (sharedDebugController)
		self = sharedDebugController;
	else {	
		if ((self = [super init])) {
			sharedDebugController = self;

			debugLogArray = [[NSMutableArray alloc] init];		
		}
	}
	return self;
}

- (void)controllerDidLoad
{
	//Contact list menu tem
	NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Debug Window",nil)
																				target:self
																				action:@selector(showDebugWindow:)
																		 keyEquivalent:@""];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Adium_About];
	[menuItem release];

	//Restore the debug window if it was open when we quit last time
	if ([[adium.preferenceController preferenceForKey:KEY_DEBUG_WINDOW_OPEN
												  group:GROUP_DEBUG] boolValue]) {
		[ESDebugWindowController showDebugWindow];
	}
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:GROUP_DEBUG];
}

- (void)controllerWillClose
{
	//Save the open state of the debug window
	[adium.preferenceController setPreference:([ESDebugWindowController debugWindowIsOpen] ?
												 [NSNumber numberWithBool:YES] :
												 nil)
										 forKey:KEY_DEBUG_WINDOW_OPEN
										  group:GROUP_DEBUG];
	[ESDebugWindowController closeDebugWindow];
}

+ (ESDebugController *)sharedDebugController
{
	return sharedDebugController;
}

- (void)dealloc
{
	[debugLogArray release];
	[debugLogFile closeFile];
	[debugLogFile release];

	sharedDebugController = nil;

	[super dealloc];
}

- (void)showDebugWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[ESDebugWindowController showDebugWindow];
}

- (void)addMessage:(NSString *)actualMessage
{
	if ((![actualMessage hasSuffix:@"\n"]) && (![actualMessage hasSuffix:@"\r"])) {
		actualMessage = [actualMessage stringByAppendingString:@"\n"];
	}

	[debugLogArray addObject:actualMessage];

	if (debugLogFile) {
		[debugLogFile writeData:[actualMessage dataUsingEncoding:NSUTF8StringEncoding]];
	}

	//Keep debugLogArray to a reasonable size
	if ([debugLogArray count] > CACHED_DEBUG_LOGS) [debugLogArray removeObjectAtIndex:0];
	
	[ESDebugWindowController addedDebugMessage:actualMessage];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || [key isEqualToString:KEY_DEBUG_WRITE_LOG]) {
		BOOL	writeLogs = [[prefDict objectForKey:KEY_DEBUG_WRITE_LOG] boolValue];
		if (writeLogs) {
			[self debugLogFile];
			
		} else {
			[debugLogFile release]; debugLogFile = nil;
		}
	}
}

- (NSArray *)debugLogArray
{
	return debugLogArray;
}
- (void)clearDebugLogArray
{
	[debugLogArray removeAllObjects]; 
}

- (NSFileHandle *)debugLogFile
{
	if (!debugLogFile) {
		NSFileManager *mgr = [NSFileManager defaultManager];
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		NSString *folder, *dateString, *filename, *pathname;
		NSUInteger counter = 0;
		NSInteger fd;
		
		//make sure the containing folder for debug logs exists.
		folder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		folder = [folder stringByAppendingPathComponent:@"Logs"];
		folder = [folder stringByAppendingPathComponent:@"Adium Debug"];
		BOOL success = [mgr createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL];
		if((!success) && (errno != EEXIST)) {
			/*raise an exception if the folder could not be created,
			*	but not if that was because it already exists.
			*/
			NSAssert2(success, @"Could not create folder %@: %s", folder, strerror(errno));
		}
		
		/*get today's date, for the filename.
			*the date is in YYYY-MM-DD format. duplicates are disambiguated with
			*' 1', ' 2', ' 3', etc. appendages.
			*/
		filename = dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%d"];
		while([mgr fileExistsAtPath:(pathname = [folder stringByAppendingPathComponent:[filename stringByAppendingPathExtension:@"log"]])]) {
			filename = [dateString stringByAppendingFormat:@" %lu", ++counter];
		}
		
		//create (if necessary) and open the file as writable, in append mode.
		fd = open([pathname fileSystemRepresentation], O_CREAT | O_WRONLY | O_APPEND, 0644);
		NSAssert2(fd > -1, @"could not create %@ nor open it for writing: %s", pathname, strerror(errno));
		
		//note: the file handle takes ownership of fd.
		/*
		 * From the docs:  "The object creating an NSFileHandle using this method owns fileDescriptor and is responsible for its disposition."
		 * which seems to indicate that the file handle does not take ownership of fd. Just for the record. -eds
		 */
		debugLogFile = [[NSFileHandle alloc] initWithFileDescriptor:fd];
		if(!debugLogFile) close(fd);
		NSAssert1(debugLogFile != nil, @"could not create file handle for %@", pathname);
		
		//write header (separates this session from previous sessions).
		[debugLogFile writeData:[[NSString stringWithFormat:@"Opened debug log at %@\n", date] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	return debugLogFile;
}

@end

#endif
