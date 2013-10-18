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

#import <Adium/AIAbstractListController.h>
#import <Adium/AIInterfaceControllerProtocol.h>

#define PREF_DETACHED_GROUPS			@"Detached Groups"

#define KEY_LIST_LAYOUT_NAME			@"List Layout Name"
#define KEY_LIST_THEME_NAME				@"List Theme Name"
#define KEY_LIST_DETACHABLE				@"List Detachable"

#define DetachedContactListIsEmpty		@"DetachedContactListIsEmpty"

@class AIListWindowController, AICLPreferences, AIListContact, ESContactListAdvancedPreferences;

@protocol AIMultiContactListComponent;

@interface AISCLViewPlugin : AIPlugin <AIMultiContactListComponent, NSMenuDelegate> {	
	NSMutableArray							*contactLists;

	ESContactListAdvancedPreferences		*advancedPreferences;

	AIContactListWindowStyle				windowStyle;
	
	AIListWindowController					*defaultController;
	BOOL									hasLoaded;
	
	NSMenuItem								*menuItem_nextDetached;
	NSMenuItem								*menuItem_previousDetached;
	NSMenuItem								*menuItem_consolidate;
	
	NSMenuItem								*detachMenuItem;
	NSMenuItem								*attachMenuItem;
	NSMenu									*attachSubmenu;

	NSUInteger								detachedCycle;
}

//Manage multiple windows
- (void)closeContactList:(AIListWindowController *)window;

//Contact List Controller
- (AIListWindowController *)contactListWindowController;
- (void)contactListDidClose:(NSNotification *)notification;
- (void)showContactListAndBringToFront:(BOOL)bringToFront;
- (BOOL)contactListIsVisibleAndMain;
- (BOOL)contactListIsVisible;
- (void)closeContactList;
- (void)closeDetachedContactLists;

@end
