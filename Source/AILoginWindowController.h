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

#import <Adium/AIWindowController.h>

@class AILoginController;

@interface AILoginWindowController : AIWindowController <NSTableViewDelegate, NSTableViewDataSource> {

    IBOutlet		NSTableView	*tableView_userList;
    IBOutlet		NSTableView	*tableView_editableUserList;
    IBOutlet		NSPanel		*panel_userListEditor;
    IBOutlet		NSButton	*checkbox_displayOnStartup;
	
	IBOutlet		NSButton	*checkBox_debugMode;

    AILoginController	 		*owner;
    NSArray                     *userArray;
	
	NSTimer						*loginTimer;
}

+ (AILoginWindowController *)loginWindowControllerWithOwner:(id)inOwner __attribute__((objc_method_family(new)));
- (void)disableLoginTimeout;

@end
