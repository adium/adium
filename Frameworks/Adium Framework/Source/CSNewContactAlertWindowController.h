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

@class AIImageTextCellView, AIActionDetailsPane;

@interface CSNewContactAlertWindowController : AIWindowController {
	IBOutlet NSView					*view_auxiliary;
	IBOutlet NSPopUpButton			*popUp_event;
	IBOutlet NSPopUpButton			*popUp_action;

	IBOutlet NSButton				*checkbox_oneTime;

	IBOutlet NSButton				*button_OK;
	IBOutlet NSButton				*button_cancel;
	IBOutlet NSTextField			*label_Event;
	IBOutlet NSTextField			*label_Action;

	AIActionDetailsPane				*detailsPane;
	NSView							*detailsView;
	NSMutableDictionary				*alert;

	id								target;
	id								delegate;
	NSDictionary					*oldAlert;
	
	AIListObject					*listObject;
	
	BOOL							configureForGlobal;
	
	IBOutlet	AIImageTextCellView	*headerView;
}

+ (void)editAlert:(NSDictionary *)inAlert
	forListObject:(AIListObject *)inObject
		 onWindow:(NSWindow *)parentWindow
  notifyingTarget:(id)inTarget 
		 delegate:(id)inDelegate
		 oldAlert:(id)inOldAlert
	configureForGlobal:(BOOL)inConfigureForGlobal
   defaultEventID:(NSString *)defaultEventID;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end
