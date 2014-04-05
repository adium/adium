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

#import "ESDebugController.h"
#import "ESDebugWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>

#define	KEY_DEBUG_WINDOW_FRAME	@"Debug Window Frame"
#define	DEBUG_WINDOW_NIB		@"DebugWindow"

@implementation ESDebugWindowController

static ESDebugWindowController *sharedDebugWindowInstance = nil;

//Return the shared contact info window
+ (id)showDebugWindow
{
    //Create the window
    if (!sharedDebugWindowInstance) {
        sharedDebugWindowInstance = [[self alloc] initWithWindowNibName:DEBUG_WINDOW_NIB];
    }
	
	//Configure and show window
	[sharedDebugWindowInstance showWindow:nil];
	
	return sharedDebugWindowInstance;
}

+ (BOOL)debugWindowIsOpen
{
	return sharedDebugWindowInstance != nil;
}

- (void)performFilter
{
	NSString	 *aDebugString;
	
	[mutableDebugString setString:@""];
	for (aDebugString in fullDebugLogArray) {
		if (!filter || 
			[aDebugString rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
			[mutableDebugString appendString:aDebugString];			
		}
	}
	
	
	[[textView_debug textStorage] addAttribute:NSParagraphStyleAttributeName
										 value:debugParagraphStyle
										 range:NSMakeRange(0, [mutableDebugString length])];
	
	[scrollView_debug scrollToBottom];	
}

- (void)addedDebugMessage:(NSString *)aDebugString
{
	[fullDebugLogArray addObject:aDebugString];

	if (!filter || 
		[aDebugString rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
		NSUInteger aDebugStringLength = [aDebugString length];
		
		[mutableDebugString appendString:aDebugString];
		[[textView_debug textStorage] addAttribute:NSParagraphStyleAttributeName
											 value:debugParagraphStyle
											 range:NSMakeRange([mutableDebugString length] - aDebugStringLength, aDebugStringLength)];
	}
}
+ (void)addedDebugMessage:(NSString *)aDebugString
{
	if (sharedDebugWindowInstance) [sharedDebugWindowInstance addedDebugMessage:aDebugString];
}

- (NSString *)adiumFrameAutosaveName
{
	return KEY_DEBUG_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	//We store the reference to the mutableString of the textStore for efficiency
	mutableDebugString = [[textView_debug textStorage] mutableString];
	fullDebugLogArray = [[NSMutableArray alloc] init];

	debugParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[debugParagraphStyle setHeadIndent:12];
	[debugParagraphStyle setFirstLineHeadIndent:2];
	[scrollView_debug setAutoScrollToBottom:YES];

	//Load the logs which were added before the window was loaded
	for (NSString *aDebugString in adium.debugController.debugLogArray) {
		[mutableDebugString appendString:aDebugString];
		if ((![aDebugString hasSuffix:@"\n"]) && (![aDebugString hasSuffix:@"\r"])) {
			[mutableDebugString appendString:@"\n"];
		}
		[fullDebugLogArray addObject:aDebugString];
	}


	[[self window] setTitle:AILocalizedString(@"Adium Debug Log","Debug window title")];
	[checkBox_logWriting setLocalizedString:AILocalizedString(@"Log to ~/Library/Logs/Adium Debug", "Logging checkbox in the Adium Debug Window")];
	[button_clear setLocalizedString:AILocalizedString(@"Clear", nil)];

	//On the next run loop, scroll to the bottom
	[scrollView_debug performSelector:@selector(scrollToBottom)
						   withObject:nil
						   afterDelay:0];
	
	[checkBox_logWriting setState:[[adium.preferenceController preferenceForKey:KEY_DEBUG_WRITE_LOG
																			group:GROUP_DEBUG] boolValue]];
	
	[super windowDidLoad];
}

//Close the debug window
+ (void)closeDebugWindow
{
    if (sharedDebugWindowInstance) {
        [sharedDebugWindowInstance closeWindow:nil];
    }
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	//Close down
	mutableDebugString = nil;
	fullDebugLogArray = nil;
	debugParagraphStyle = nil;
    sharedDebugWindowInstance = nil;
}

- (IBAction)toggleLogWriting:(id)sender
{
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
										 forKey:KEY_DEBUG_WRITE_LOG
										  group:GROUP_DEBUG];
}

- (IBAction)clearLog:(id)sender
{
	[mutableDebugString setString:@""];
	[fullDebugLogArray removeAllObjects];

	[adium.debugController clearDebugLogArray];
	
	[scrollView_debug scrollToTop];
}

- (void)setFilter:(NSString *)inFilter
{
	if (inFilter != filter) {
		filter = [inFilter copy];

		[self performFilter];
	}
}

@end
