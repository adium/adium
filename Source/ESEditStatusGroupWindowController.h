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

@class AIStatusGroup;

@interface ESEditStatusGroupWindowController : AIWindowController {
	IBOutlet	NSTextField			*label_title;
	IBOutlet	NSTextField			*textField_title;

	IBOutlet	NSTextField			*label_groupWith;
	IBOutlet	NSPopUpButton		*popUp_groupWith;
	
	IBOutlet	NSButton			*button_OK;
	IBOutlet	NSButton			*button_cancel;
	
	AIStatusGroup					*statusGroup;
	id								target;
}

- (void)showOnWindow:(NSWindow *)parentWindow __attribute__((ns_consumes_self));
- (id)initWithStatusGroup:(AIStatusGroup *)inStatusGroup notifyingTarget:(id)inTarget;

- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface NSObject (ESStatusGroupWindowControllerDelegate)
- (void)finishedStatusGroupEdit:(AIStatusGroup *)inStatusGroup;
@end
