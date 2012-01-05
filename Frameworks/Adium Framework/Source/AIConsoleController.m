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

#import "AIConsoleController.h"
#import <AIUtilities/AIAutoScrollView.h>

@implementation AIConsoleController

- (IBAction)send:(id)sender {
    // remove from text field
    [injectView setString:@""];
}

- (IBAction)clearLog:(id)sender {
    [logView setString:@""];
}

- (IBAction)showWindow:(id)sender {
	if (!consoleWindow) {
		//Load the window if it's not already loaded
		[[NSBundle bundleForClass:[AIConsoleController class]] loadNibFile:@"AIConsole"
														 externalNameTable:[NSDictionary dictionaryWithObject:self forKey:NSNibOwner]
																  withZone:NULL];
		if (!consoleWindow) AILogWithSignature(@"Unable to load AIConsole!");
	}
	
    [consoleWindow makeKeyAndOrderFront:sender];
	[(AIAutoScrollView *)[logView enclosingScrollView] setAutoScrollToBottom:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
	consoleWindow = nil;
}

- (void)close
{
	[consoleWindow close];
}


- (void)appendToLog:(NSAttributedString*)astr {
	[[logView textStorage] appendAttributedString:astr];
}

@end
