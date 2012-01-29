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

@class AIChat, AIListGroup;

@interface AINewBookmarkWindowController : AIWindowController {
    IBOutlet NSPopUpButton	*popUp_group;
    IBOutlet NSTextField	*textField_name;
	
	IBOutlet NSTextField	*label_name;
	IBOutlet NSTextField	*label_group;
	IBOutlet NSButton		*button_add;
	IBOutlet NSButton		*button_cancel;
	
	id			target;
	AIChat		*chat;
}

- (id)initWithChat:(AIChat *)inChat notifyingTarget:(id)inTarget;
- (void)showOnWindow:(id)parentWindow __attribute__((ns_consumes_self));
- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface NSObject (AINewBookmarkWindowControllerTarget)
- (void)createBookmarkForChat:(AIChat *)chat withName:(NSString *)name inGroup:(AIListGroup *)group;
@end
