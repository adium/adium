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

#import "ESContactSortConfigurationWindowController.h"
#import <Adium/AISortController.h>

/*!
 * @class ESContactSortConfigurationWindowController
 * @brief Window controller for configuring sorting options for an <tt>AISortController</tt>
 */
@implementation ESContactSortConfigurationWindowController

static ESContactSortConfigurationWindowController   *sharedSortConfigInstance = nil;

/*!
 * @brief Show the sort configuration window for a controller
 *
 * @param controller The controller to configure
 */
+ (id)showSortConfigurationWindowForController:(AISortController *)controller
{
	if ([controller configureSortWindowTitle]) {
		if (!sharedSortConfigInstance) {
			//Load the window controller if necessary. We retain ourselves, closing when our window closes.
			sharedSortConfigInstance = [[self alloc] initWithWindowNibName:@"SortConfiguration"];
			
			//Remove those buttons we don't want.  removeFromSuperview will confuse the window, so just make them invisible.
			NSButton *standardWindowButton = [[sharedSortConfigInstance window] standardWindowButton:NSWindowMiniaturizeButton];
			[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
			standardWindowButton = [[sharedSortConfigInstance window] standardWindowButton:NSWindowZoomButton];
			[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
		}
		
		[sharedSortConfigInstance configureForController:controller];
		
		[sharedSortConfigInstance showWindow:nil];

	} else {
		//Configuring for a controller which has no configuration view...
		if (sharedSortConfigInstance) {
			[sharedSortConfigInstance closeWindow:nil];
			[sharedSortConfigInstance autorelease]; sharedSortConfigInstance = nil;
		}
	}
	
	return sharedSortConfigInstance;
}

+ (BOOL)sortConfigurationIsOpen
{
	return (sharedSortConfigInstance != nil);
}

/*!
 * @brief Configure our window and view for a passed controller
 */
- (void)configureForController:(AISortController *)controller
{
	//Configure the title
	[[self window] setTitle:[controller configureSortWindowTitle]];
	
	//Configure the view
	NSView  *configureView = [controller configureView];

	NSSize newSize = [configureView frame].size;
	
	//This will resize the view to the current window size...
	[[self window] setContentView:configureView];
	
	//...so restore the window to the size this view really wants to be
	[[self window] setContentSize:newSize];
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[[self window] setTitle:AILocalizedString(@"Configure Sorting","Configure Sort window title")];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	[sharedSortConfigInstance autorelease]; sharedSortConfigInstance = nil;
}

@end
