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

#import "ESChatUserListController.h"
#import "AISideSplitView.h"
#import "KNShelfSplitView.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMessageEntryTextView.h>

@class AIAccount, AIListContact, AIListObject, AIAccountSelectionView, AIMessageTabSplitView;
@class AIMessageWindowController, AIMessageWindowOutgoingScrollView;
@class RBSplitView;

@interface AIMessageViewController : NSObject <AIListControllerDelegate, AIChatViewController, AIMessageEntryTextViewDelegate> {
    IBOutlet	NSView			*view_contents;
	
	//Split views
	IBOutlet	RBSplitView		*splitView_textEntryHorizontal;
	
	//Message Display
	NSView											*controllerView_messages;
	IBOutlet	AIMessageWindowOutgoingScrollView	*scrollView_messages;
	IBOutlet	NSView								*customView_messages;
	
	//User List
	IBOutlet	AIAutoScrollView		*scrollView_userList;
	BOOL								retainingScrollViewUserList;
    IBOutlet	AIListOutlineView		*userListView;
	ESChatUserListController			*userListController;

	//Text entry
	IBOutlet	NSScrollView			*scrollView_outgoing;
	IBOutlet	AIMessageEntryTextView	*textView_outgoing;

	IBOutlet	NSView					*nibrootView_messageView;
	IBOutlet	NSView					*nibrootView_shelfVew;
	IBOutlet	NSView					*nibrootView_userList;

	//
    NSObject<AIMessageDisplayController>	*messageDisplayController;
	AIAccountSelectionView					*view_accountSelection;
	AIMessageWindowController				*messageWindowController;

	//widgetstrip
	IBOutlet				KNShelfSplitView				*shelfView;
	
	//menuitem
	NSMenuItem				*showHide;

    AIChat					*chat;
	BOOL					suppressSendLaterPrompt;
	NSInteger				entryMinHeight;
	
	BOOL					userListOnRight;
	NSInteger				userListMinWidth;

	NSUndoManager			*undoManager;
	
	NSWritingDirection		initialBaseWritingDirection;
}

+ (AIMessageViewController *)messageDisplayControllerForChat:(AIChat *)inChat;
- (void)messageViewWillLeaveWindowController:(AIMessageWindowController *)inWindowController;
- (void)messageViewAddedToWindowController:(AIMessageWindowController *)inWindowController;
- (AIChat *)chat;

- (AIListContact *)listObject;
- (AIListObject *)preferredListObject;
- (NSArray *)selectedListObjects;

//Message Display
- (NSObject<AIMessageDisplayController> *)messageDisplayController;
- (NSView *)view;
- (void)adiumPrint:(id)sender;

//Message Entry
- (IBAction)sendMessage:(id)sender;
- (IBAction)didSendMessage:(id)sender;
- (IBAction)sendMessageLater:(id)sender;

//Account Selection
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification;
- (void)setAccountSelectionMenuVisibleIfNeeded:(BOOL)makeVisible;

//Text Entry
- (AIMessageEntryTextView *)textEntryView;
- (void)makeTextEntryViewFirstResponder;
- (void)clearTextEntryView;
- (void)addToTextEntryView:(NSAttributedString *)inString;
- (void)addDraggedDataToTextEntryView:(id <NSDraggingInfo>)draggingInfo;
 
- (void)tabViewDidChangeVisibility;
- (void)didSelect;
- (void)willDeselect;

@end

