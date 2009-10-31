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

#import "AIMessageViewController.h"
#import "AIAccountSelectionView.h"
#import "AIMessageWindowController.h"
#import "ESGeneralPreferencesPlugin.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIContactInfoWindowController.h"
#import "AIMessageTabSplitView.h"
#import "AIMessageWindowOutgoingScrollView.h"
#import "KNShelfSplitView.h"
#import "ESChatUserListController.h"

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIServiceIcons.h>

#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISplitView.h>

#import <PSMTabBarControl/NSBezierPath_AMShading.h>

#import "RBSplitView.h"

//Heights and Widths
#define MESSAGE_VIEW_MIN_HEIGHT_RATIO		.50						//Mininum height ratio of the message view
#define MESSAGE_VIEW_MIN_WIDTH_RATIO		.50						//Mininum width ratio of the message view
#define ENTRY_TEXTVIEW_MIN_HEIGHT			20						//Mininum height of the text entry view
#define USER_LIST_DEFAULT_WIDTH				120						//Default width of the user list

//Preferences and files
#define MESSAGE_VIEW_NIB					@"MessageView"			//Filename of the message view nib
#define	USERLIST_THEME						@"UserList Theme"		//File name of the user list theme
#define	USERLIST_LAYOUT						@"UserList Layout"		//File name of the user list layout
#define	KEY_ENTRY_TEXTVIEW_MIN_HEIGHT		@"Minimum Text Height"	//Preference key for text entry height
#define	KEY_ENTRY_USER_LIST_MIN_WIDTH		@"UserList Minimum Width"	//Preference key for user list width
#define KEY_USER_LIST_VISIBLE_PREFIX		@"Userlist Visible Chat:" //Preference key prefix for user list visibility
#define KEY_USER_LIST_ON_RIGHT				@"UserList On Right"	// Preference key for user list being on the right

#define TEXTVIEW_HEIGHT_DEBUG

@interface AIMessageViewController ()
- (id)initForChat:(AIChat *)inChat;
- (void)chatStatusChanged:(NSNotification *)notification;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)_configureMessageDisplay;
- (void)_createAccountSelectionView;
- (void)_destroyAccountSelectionView;
- (void)_configureTextEntryView;
- (void)_updateTextEntryViewHeight;
- (NSInteger)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMininum;
- (void)_showUserListView;
- (void)_hideUserListView;
- (void)_configureUserList;
- (void)_updateUserListViewWidth;
- (NSInteger)_userListViewProperWidth;
- (void)updateFramesForAccountSelectionView;
- (void)saveUserListMinimumSize;
- (BOOL)userListInitiallyVisible;
- (void)setUserListVisible:(BOOL)inVisible;
- (void)setupShelfView;
- (void)updateUserCount;

- (NSArray *)contactsMatchingBeginningString:(NSString *)partialWord;
@end

@implementation AIMessageViewController

/*!
 * @brief Create a new message view controller
 */
+ (AIMessageViewController *)messageDisplayControllerForChat:(AIChat *)inChat
{
    return [[[self alloc] initForChat:inChat] autorelease];
}


/*!
 * @brief Initialize
 */
- (id)initForChat:(AIChat *)inChat
{
    if ((self = [super init])) {
		AIListContact	*contact;
		//Init
		chat = [inChat retain];
		contact = chat.listObject;
		view_accountSelection = nil;
		userListController = nil;
		suppressSendLaterPrompt = NO;
		retainingScrollViewUserList = NO;
		
		//Load the view containing our controls
		[NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];
		
		//Register for the various notification we need
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(sendMessage:) 
										   name:Interface_SendEnteredMessage
										 object:chat];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(didSendMessage:)
										   name:Interface_DidSendEnteredMessage 
										 object:chat];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(chatStatusChanged:) 
										   name:Chat_StatusChanged
										 object:chat];
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(chatParticipatingListObjectsChanged:)
										   name:Chat_ParticipatingListObjectsChanged
										 object:chat];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(redisplaySourceAndDestinationSelector:) 
										   name:Chat_SourceChanged
										 object:chat];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(redisplaySourceAndDestinationSelector:) 
										   name:Chat_DestinationChanged
										 object:chat];

		//Observe general preferences for sending keys
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

		/* Update chat status and participating list objects to configure the user list if necessary
		 * Call chatParticipatingListObjectsChanged first, which will set up the user list. This allows other sizing to match.
		 */
		[self setUserListVisible:(chat.isGroupChat && [self userListInitiallyVisible])];
		
		[self chatParticipatingListObjectsChanged:nil];
		[self chatStatusChanged:nil];
		
		//Configure our views
		[self _configureMessageDisplay];
		[self _configureTextEntryView];

		//Set our base writing direction
		if (contact) {
			initialBaseWritingDirection = [contact baseWritingDirection];
			[textView_outgoing setBaseWritingDirection:initialBaseWritingDirection];
		}
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{   
	AIListContact	*contact = chat.listObject;
	
	[adium.preferenceController unregisterPreferenceObserver:self];

	//Store our minimum height for the text entry area, and minimim width for the user list
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:entryMinHeight]
										 forKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	if (userListController) {
		[self saveUserListMinimumSize];
	}
	
	//Save the base writing direction
	if (contact && initialBaseWritingDirection != [textView_outgoing baseWritingDirection])
		[contact setBaseWritingDirection:[textView_outgoing baseWritingDirection]];

	[chat release]; chat = nil;

	//remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    //Account selection view
	[self _destroyAccountSelectionView];
	
	[messageDisplayController messageViewIsClosing];
    [messageDisplayController release];
	[userListController release];

	[controllerView_messages release];
	
	//Release the views for which we are responsible (because we loaded them via -[NSBundle loadNibNamed:owner])
	[nibrootView_messageView release];
	[nibrootView_shelfVew release];
	[nibrootView_userList release];

	//Release the hidden user list view
	if (retainingScrollViewUserList) {
		[scrollView_userList release];
	}
	//release menuItem
	[showHide release];
	
	[undoManager release]; undoManager = nil;

    [super dealloc];
}

- (void)saveUserListMinimumSize
{
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:userListMinWidth]
										 forKey:KEY_ENTRY_USER_LIST_MIN_WIDTH
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

- (void)updateGradientColors
{
	NSColor *darkerColor = [NSColor colorWithCalibratedWhite:0.90 alpha:1.0];
	NSColor *lighterColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
	NSColor *leftColor = nil, *rightColor = nil;

	switch ([messageWindowController tabPosition]) {
		case AdiumTabPositionBottom:
		case AdiumTabPositionTop:
		case AdiumTabPositionLeft:
			leftColor = lighterColor;
			rightColor = darkerColor;
			break;
		case AdiumTabPositionRight:
			leftColor = darkerColor;
			rightColor = lighterColor;
			break;
	}

	[view_accountSelection setLeftColor:leftColor rightColor:rightColor];
	//XXX
//	[splitView_textEntryHorizontal setLeftColor:leftColor rightColor:rightColor];
}

/*!
 * @brief Invoked before the message view closes
 *
 * This method is invoked before our message view controller's message view leaves a window.
 * We need to clean up our user list to invalidate cursor tracking before the view closes.
 */
- (void)messageViewWillLeaveWindowController:(AIMessageWindowController *)inWindowController
{
	if (inWindowController) {
		[userListController contactListWillBeRemovedFromWindow];
	}
	
	[messageWindowController release]; messageWindowController = nil;
}

- (void)messageViewAddedToWindowController:(AIMessageWindowController *)inWindowController
{
	if (inWindowController) {
		[userListController contactListWasAddedBackToWindow];
	}
	
	if (inWindowController != messageWindowController) {
		[messageWindowController release];
		messageWindowController = [inWindowController retain];
		
		[self updateGradientColors];
	}
}

/*!
 * @brief Retrieve the chat represented by this message view
 */
- (AIChat *)chat
{
    return chat;
}

/*!
 * @brief Retrieve the source account associated with this chat
 */
- (AIAccount *)account
{
    return chat.account;
}

/*!
 * @brief Retrieve the destination list object associated with this chat
 */
- (AIListContact *)listObject
{
    return chat.listObject;
}

/*!
 * @brief Returns the selected list object in our participants list
 */
- (AIListObject *)preferredListObject
{
	if (userListView) { //[[shelfView subviews] containsObject:scrollView_userList] && ([userListView selectedRow] != -1)
		return [userListView itemAtRow:[userListView selectedRow]];
	}
	
	return nil;
}

/*!
 * @brief Invoked when the status of our chat changes
 *
 * The only chat status change we're interested in is one to the disallow account switching flag.  When this flag 
 * changes we update the visibility of our account status menus accordingly.
 */
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];
	
    if (notification == nil || [modifiedKeys containsObject:@"DisallowAccountSwitching"]) {
		[self setAccountSelectionMenuVisibleIfNeeded:YES];
    }
}


//Message Display ------------------------------------------------------------------------------------------------------
#pragma mark Message Display
/*!
 * @brief Configure the message display view
 */
- (void)_configureMessageDisplay
{
	//Create the message view
	messageDisplayController = [[adium.interfaceController messageDisplayControllerForChat:chat] retain];
	//Get the messageView from the controller
	controllerView_messages = [[messageDisplayController messageView] retain];

	/* customView_messages is really just a placeholder.  It's a subview of scrollView_messages, which exists just
	 * to draw a box around itself to give the desired border. NSBox could be used for the same purpose.
	 * We replace customView_messages with the actual message view we want to use, controllerView_messages.
	 *
	 * Note that this does -not- change the documentView of scrollView_messages, which remains NULL.
	 * This is because the controllerView_messages supplies its own scroll view (within the WebView).
	 * We therefore use -[AIMessageWindowOutgoingScrollView setAccessibilityChild:] to manage the accessibility
	 * heirarchy.
	 */
	[controllerView_messages setFrame:[scrollView_messages documentVisibleRect]];
	[scrollView_messages setAccessibilityChild:controllerView_messages];
	[[customView_messages superview] replaceSubview:customView_messages with:controllerView_messages];

	//This is what draws our transparent background
	//Technically, it could be set in MessageView.nib, too
	[scrollView_messages setBackgroundColor:[NSColor clearColor]];

	[textView_outgoing setNextResponder:view_contents];
	
	[controllerView_messages setNextResponder:textView_outgoing];
}

/*!
 * @brief The message display controller
 */
- (NSObject<AIMessageDisplayController> *)messageDisplayController
{
	return messageDisplayController;
}

/*!
 * @brief Access to our view
 */
- (NSView *)view
{
    return view_contents;
}

- (NSScrollView *)messagesScrollView
{
	return scrollView_messages;
}

/*!
 * @brief Support for printing.  Forward the print command to our message display view
 */
- (void)adiumPrint:(id)sender
{
	if ([messageDisplayController respondsToSelector:@selector(adiumPrint:)]) {
		[messageDisplayController adiumPrint:sender];
	}
}


//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
/*!
 * @brief Send the entered message
 */
- (IBAction)sendMessage:(id)sender
{
	NSAttributedString	*attributedString = [textView_outgoing textStorage];
	
	//Only send if we have a non-zero-length string
    if ([attributedString length] != 0) { 
		AIListObject				*listObject = chat.listObject;

		//If user typed command /clear, reset the content of the view
		if ([[attributedString string] caseInsensitiveCompare:AILocalizedString(@"/clear", "Command which will clear the message area of a chat. Please include the '/' at the front of your translation.")] == NSOrderedSame) {
			//Reset the content of the view
			[messageDisplayController clearView];

			//Reset the content of the text field, removing the command as it has been executed
			[self clearTextEntryView];

			//Commands are not messages, so they don't have to be sent
			return;
		}
		
		if (chat.isGroupChat && !chat.account.online) {
			//Refuse to do anything with a group chat for an offline account.
			NSBeep();
			return;
		}

		AIChatSendingAbilityType messageSendingAbility = chat.messageSendingAbility;
		if (suppressSendLaterPrompt || (messageSendingAbility == AIChatCanSendMessageNow) ||
			((messageSendingAbility == AIChatCanSendViaServersideOfflineMessage) && chat.account.sendOfflineMessagesWithoutPrompting)) {
			AIContentMessage		*message;
			NSAttributedString		*outgoingAttributedString;
			AIAccount				*account = chat.account;
			//Send the message
			[[NSNotificationCenter defaultCenter] postNotificationName:Interface_WillSendEnteredMessage
													  object:chat
													userInfo:nil];
			
			outgoingAttributedString = [attributedString copy];
			message = [AIContentMessage messageInChat:chat
										   withSource:account
										  destination:chat.listObject
												 date:nil //created for us by AIContentMessage
											  message:outgoingAttributedString
											autoreply:NO];
			[outgoingAttributedString release];
			
			if ([adium.contentController sendContentObject:message]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:Interface_DidSendEnteredMessage 
														  object:chat
														userInfo:nil];
			}
			/* If we sent with AIChatCanSendViaServersideOfflineMessage, we should probably show a status message to
			 * the effect AILocalizedString(@"Your message has been sent. %@ will receive it when online.", nil)
			 */
		} else {
			NSString							*formattedUID = listObject.formattedUID;
			
			NSAlert *alert = [[NSAlert alloc] init];
			NSImage *icon = ([listObject userIcon] ? [listObject userIcon] : [AIServiceIcons serviceIconForObject:listObject
																											 type:AIServiceIconLarge
																										direction:AIIconNormal]);
			icon = [[icon copy] autorelease];
			[icon setScalesWhenResized:NO];
			[alert setIcon:icon];
			[alert setAlertStyle:NSInformationalAlertStyle];
			
			[alert setMessageText:[NSString stringWithFormat:AILocalizedString(@"%@ appears to be offline. How do you want to send this message?", nil),
								   formattedUID]];

			switch (messageSendingAbility) {
				case AIChatCanSendViaServersideOfflineMessage:
				{
					[alert setInformativeText:[NSString stringWithFormat:
											   AILocalizedString(@"Send Now will deliver your message to the server immediately. %@ will receive the message the next time he or she signs on, even if you are no longer online.\n\nSend When Both Online will send the message the next time both you and %@ are known to be online and you are connected using Adium on this computer.", "Send Later dialogue explanation text for accounts supporting offline messaging support."),
											   formattedUID, formattedUID]];
					[alert addButtonWithTitle:AILocalizedString(@"Send Now", nil)];
					
					[alert addButtonWithTitle:AILocalizedString(@"Send When Both Online", nil)];
					[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"b"];
					[[[alert buttons] objectAtIndex:1] setKeyEquivalentModifierMask:0];

					break;
				}
				case AIChatMayNotBeAbleToSendMessage:
				{
					[alert setInformativeText:[NSString stringWithFormat:
											   AILocalizedString(@"Send Later will send the message the next time both you and %@ are online. Send Now may work if %@ is invisible or is not on your contact list and so only appears to be offline.", "Send Later dialogue explanation text"),
											   formattedUID, formattedUID, formattedUID]];
					[alert addButtonWithTitle:AILocalizedString(@"Send Now", nil)];
					
					[alert addButtonWithTitle:AILocalizedString(@"Send Later", nil)];
					[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"l"];
					[[[alert buttons] objectAtIndex:1] setKeyEquivalentModifierMask:0];
					
					break;
				}
				case AIChatCanNotSendMessage:
				{
					[alert setInformativeText:[NSString stringWithFormat:
											   AILocalizedString(@"Send Later will send the message the next time both you and %@ are online.", "Send Later dialogue explanation text"),
											   formattedUID, formattedUID, formattedUID]];					
					[alert addButtonWithTitle:AILocalizedString(@"Send Later", nil)];
					[[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"l"];
					[[[alert buttons] objectAtIndex:0] setKeyEquivalentModifierMask:0];
					
					break;
				}
				case AIChatCanSendMessageNow:
				{
					//We will never get here.
					break;
				}
			}

			[alert addButtonWithTitle:AILocalizedString(@"Don't Send", nil)];

			NSButton *dontSendButton = ((messageSendingAbility == AIChatCanNotSendMessage) ?
										[[alert buttons] objectAtIndex:1] :
										[[alert buttons] objectAtIndex:2]);
			[dontSendButton setKeyEquivalent:@"\E"];
			[dontSendButton setKeyEquivalentModifierMask:0];
			
			[alert beginSheetModalForWindow:[view_contents window]
							  modalDelegate:[self retain] /* Will release after the sheet ends */
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:[[NSNumber numberWithInteger:messageSendingAbility] retain] /* Will release after the sheet ends */];
			[alert release];
		}
    }
}

/*!
 * @brief Send Later button was pressed
 */ 
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	AIChatSendingAbilityType messageSendingAbility = [(NSNumber *)contextInfo integerValue];

	switch (returnCode) {
		case NSAlertFirstButtonReturn:
			/* The AIChatCanNotSendMessage dalogue has Send Later as the first choice;
			 * all others have Send Now as the first choice.
			 */
			if (messageSendingAbility == AIChatCanNotSendMessage) {
				 /* Send Later */
				[self sendMessageLater:nil];

			} else {
				 /* Send Now */
				suppressSendLaterPrompt = YES;
				[self sendMessage:nil];
			}
			break;
			
		case NSAlertSecondButtonReturn:
			/* The AIChatCanNotSendMessage dalogue has Cancel as the second choice;
			 * all others have Send Later as the first choice.
			 */
			if (messageSendingAbility != AIChatCanNotSendMessage) {
				/* Send Later */
				[self sendMessageLater:nil];
			}			
			break;

		case NSAlertThirdButtonReturn: /* Don't Send */
			break;		
	}
	
	//Retained when the alert was created to guard against a crash if the chat tab being closed while we are open
	[self release];
	[(NSNumber *)contextInfo release];
}

/*!
 * @brief Invoked after our entered message sends
 *
 * This method hides the account selection view and clears the entered message after our message sends
 */
- (IBAction)didSendMessage:(id)sender
{
    [self setAccountSelectionMenuVisibleIfNeeded:NO];
    [self clearTextEntryView];
}

/*!
 * @brief Offline messaging
 */
- (IBAction)sendMessageLater:(id)sender
{
	//If the chat can _now_ send a message, send it immediately instead of waiting for "later".
	if ([chat messageSendingAbility] == AIChatCanSendMessageNow) {
		[self sendMessage:sender];
		return;
	}

	//Put the alert on the metaContact containing this listContact if applicable
	AIMetaContact *listContact = chat.listObject.metaContact;

	if (listContact) {
		NSMutableDictionary *detailsDict, *alertDict;
		
		detailsDict = [NSMutableDictionary dictionary];
		[detailsDict setObject:chat.account.internalObjectID forKey:@"Account ID"];
		[detailsDict setObject:[NSNumber numberWithBool:YES] forKey:@"Allow Other"];
		[detailsDict setObject:listContact.internalObjectID forKey:@"Destination ID"];

		alertDict = [NSMutableDictionary dictionary];
		[alertDict setObject:detailsDict forKey:@"ActionDetails"];
		[alertDict setObject:CONTACT_SEEN_ONLINE_YES forKey:@"EventID"];
		[alertDict setObject:@"SendMessage" forKey:@"ActionID"];
		[alertDict setObject:[NSNumber numberWithBool:YES] forKey:@"OneTime"]; 
		
		[alertDict setObject:listContact forKey:@"TEMP-ListContact"];
		
		[adium.contentController filterAttributedString:[[[textView_outgoing textStorage] copy] autorelease]
										  usingFilterType:AIFilterContent
												direction:AIFilterOutgoing
											filterContext:listContact
										  notifyingTarget:self
												 selector:@selector(gotFilteredMessageToSendLater:receivingContext:)
												  context:alertDict];

		[self didSendMessage:nil];
	}
}

/*!
 * @brief Offline messaging
 */
//XXX - Offline messaging code SHOULD NOT BE IN HERE! -ai
- (void)gotFilteredMessageToSendLater:(NSAttributedString *)filteredMessage receivingContext:(NSMutableDictionary *)alertDict
{
	NSMutableDictionary	*detailsDict;
	AIListContact		*listContact;
	
	detailsDict = [alertDict objectForKey:@"ActionDetails"];
	[detailsDict setObject:[filteredMessage dataRepresentation] forKey:@"Message"];

	listContact = [[alertDict objectForKey:@"TEMP-ListContact"] retain];
	[alertDict removeObjectForKey:@"TEMP-ListContact"];
	
	[adium.contactAlertsController addAlert:alertDict 
								 toListObject:listContact
							 setAsNewDefaults:NO];
	[listContact release];
}

//Account Selection ----------------------------------------------------------------------------------------------------
#pragma mark Account Selection
/*!
 * @brief
 */
- (void)accountSelectionViewFrameDidChange:(NSNotification *)notification
{
	[self updateFramesForAccountSelectionView];
}

/*!
 * @brief Redisplay the source/destination account selector
 */
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification
{
	// Update the textView's chat source, in case any attributes it monitors changed.
	[textView_outgoing setChat:chat];
	[self setAccountSelectionMenuVisibleIfNeeded:YES];
}

/*!
 * @brief Toggle visibility of the account selection menus
 *
 * Invoking this method with NO will hide the account selection menus.  Invoking it with YES will show the account
 * selection menus if they are needed.
 */
- (void)setAccountSelectionMenuVisibleIfNeeded:(BOOL)makeVisible
{
	//Hide or show the account selection view as requested
	if (makeVisible) {
		[self _createAccountSelectionView];
	} else {
		[self _destroyAccountSelectionView];
	}
}

/*!
 * @brief Show the account selection view
 */
- (void)_createAccountSelectionView
{
	if (!view_accountSelection) {
		NSRect	contentFrame = [splitView_textEntryHorizontal frame];

		//Create the account selection view and insert it into our window
		view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:contentFrame];

		[view_accountSelection setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
		
		[self updateGradientColors];
		
		//Insert the account selection view at the top of our view
		[[shelfView contentView] addSubview:view_accountSelection];
		[view_accountSelection setChat:chat];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountSelectionViewFrameDidChange:)
													 name:AIViewFrameDidChangeNotification
												   object:view_accountSelection];
		
		[self updateFramesForAccountSelectionView];
			
		//Redisplay everything
		[[shelfView contentView] setNeedsDisplay:YES];
	} else {
		[view_accountSelection setChat:chat];
	}
}

/*!
 * @brief Hide the account selection view
 */
- (void)_destroyAccountSelectionView
{
	if (view_accountSelection) {
		//Remove the observer
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AIViewFrameDidChangeNotification
													  object:view_accountSelection];

		//Remove the account selection view from our window, clean it up
		[view_accountSelection removeFromSuperview];
		[view_accountSelection release]; view_accountSelection = nil;

		//Redisplay everything
		[self updateFramesForAccountSelectionView];
	}
}

/*!
 * @brief Position the account selection view, if it is present, and the messages/text entry splitview appropriately
 */
- (void)updateFramesForAccountSelectionView
{
	NSInteger 	accountSelectionHeight = (view_accountSelection ? [view_accountSelection frame].size.height : 0);

	if (view_accountSelection) {
		[view_accountSelection setFrameOrigin:NSMakePoint(NSMinX([view_accountSelection frame]), NSHeight([[view_accountSelection superview] frame]) - accountSelectionHeight)];
		[view_accountSelection setNeedsDisplay:YES];
	}

	NSRect splitView_textEntryHorizontalFrame = [splitView_textEntryHorizontal frame];
	splitView_textEntryHorizontalFrame.size.height = NSHeight([[splitView_textEntryHorizontal superview] frame]) - accountSelectionHeight - NSMinY(splitView_textEntryHorizontalFrame);
	[splitView_textEntryHorizontal setFrame:splitView_textEntryHorizontalFrame];

	[splitView_textEntryHorizontal setNeedsDisplay:YES];
}	


//Text Entry -----------------------------------------------------------------------------------------------------------
#pragma mark Text Entry
/*!
 * @brief Preferences changed, update sending keys
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_GENERAL]) {
		[textView_outgoing setSendOnReturn:[[prefDict objectForKey:SEND_ON_RETURN] boolValue]];
		[textView_outgoing setSendOnEnter:[[prefDict objectForKey:SEND_ON_ENTER] boolValue]];
	} else if ([group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
		
		if (firstTime || [key isEqualToString:KEY_ENTRY_USER_LIST_MIN_WIDTH]) {
			NSInteger oldWidth = userListMinWidth;
			
			userListMinWidth = [[prefDict objectForKey:KEY_ENTRY_USER_LIST_MIN_WIDTH] integerValue];
			
			if (oldWidth != userListMinWidth) {
				[shelfView setShelfWidth:userListMinWidth];
			}
		}
		
		if (firstTime || [key isEqualToString:KEY_USER_LIST_ON_RIGHT]) {
			userListOnRight = [[prefDict objectForKey:KEY_USER_LIST_ON_RIGHT] boolValue];

			[shelfView setShelfOnRight:userListOnRight];
		}
	}
}

/*!
 * @brief Configure the text entry view
 */
- (void)_configureTextEntryView
{	
	//Configure the text entry view
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];

	//This is necessary for tab completion.
	[textView_outgoing setDelegate:self];
    
	[textView_outgoing setTextContainerInset:NSMakeSize(0,2)];
    if ([textView_outgoing respondsToSelector:@selector(setUsesFindPanel:)]) {
		[textView_outgoing setUsesFindPanel:YES];
    }
	[textView_outgoing setClearOnEscape:YES];
	[textView_outgoing setTypingAttributes:[adium.contentController defaultFormattingAttributes]];
	
	//User's choice of mininum height for their text entry view
	entryMinHeight = [[adium.preferenceController preferenceForKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
															   group:PREF_GROUP_DUAL_WINDOW_INTERFACE] integerValue];
	if (entryMinHeight <= 0) entryMinHeight = [self _textEntryViewProperHeightIgnoringUserMininum:YES];
	
	//Associate the view with our message view so it knows which view to scroll in response to page up/down
	//and other special key-presses.
	[textView_outgoing setAssociatedView:[messageDisplayController messageScrollView]];
	
	//Associate the text entry view with our chat and inform Adium that it exists.
	//This is necessary for text entry filters to work correctly.
	[textView_outgoing setChat:chat];
	
    //Observe text entry view size changes so we can dynamically resize as the user enters text
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outgoingTextViewDesiredSizeDidChange:)
												 name:AIViewDesiredSizeDidChangeNotification 
											   object:textView_outgoing];

	[self _updateTextEntryViewHeight];
}

/*!
 * @brief Sets our text entry view as the first responder
 */
- (void)makeTextEntryViewFirstResponder
{
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
}

- (void)didSelect
{
	[self makeTextEntryViewFirstResponder];
	
	/* When we're selected, it's as if the user list controller is back in the window */
	[userListController contactListWasAddedBackToWindow];
}

- (void)willDeselect
{
	/* When we're deselected (backgrounded), the user list controller is effectively out of the window */
	[userListController contactListWillBeRemovedFromWindow];
	// Mark the current location in the message display for this change, if it's not an inactive-switch.
	if (messageWindowController.window.isKeyWindow) {
		[messageDisplayController markForFocusChange];
	}
}

/*!
 * @brief Returns the Text Entry View
 *
 * Make sure you need to use this. If you just need to enter text, see -addToTextEntryView:
 */
- (AIMessageEntryTextView *)textEntryView
{
	return textView_outgoing;
}

/*!
 * @brief Clear the message entry text view
 */
- (void)clearTextEntryView
{
	NSWritingDirection	writingDirection;

	writingDirection = [textView_outgoing baseWritingDirection];
	
	[textView_outgoing setString:@""];
	[textView_outgoing setTypingAttributes:[adium.contentController defaultFormattingAttributes]];
	
	[textView_outgoing setBaseWritingDirection:writingDirection];	//Preserve the writing diraction

    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
														object:textView_outgoing];
}

/*!
 * @brief Add text to the message entry text view 
 *
 * Adds the passed string to the entry text view at the insertion point.  If there is selected text in the view, it
 * will be replaced.
 */
- (void)addToTextEntryView:(NSAttributedString *)inString
{
    [textView_outgoing insertText:inString];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}

/*!
 * @brief Add data to the message entry text view 
 *
 * Adds the passed pasteboard data to the entry text view at the insertion point.  If there is selected text in the
 * view, it will be replaced.
 */
- (void)addDraggedDataToTextEntryView:(id <NSDraggingInfo>)draggingInfo
{
    [textView_outgoing performDragOperation:draggingInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}

/*!
 * @brief Update the text entry view's height when its desired size changes
 */
- (void)outgoingTextViewDesiredSizeDidChange:(NSNotification *)notification
{
	[self _updateTextEntryViewHeight];
}

- (void)tabViewDidChangeVisibility
{
	[self _updateTextEntryViewHeight];
}

/* 
 * @brief Update the height of our text entry view
 *
 * This method sets the height of the text entry view to the most ideal value, and adjusts the other views in our
 * window to fill the remaining space.
 */
- (void)_updateTextEntryViewHeight
{
	NSInteger		height = [self _textEntryViewProperHeightIgnoringUserMininum:NO];
	//Display the vertical scroller if our view is not tall enough to display all the entered text
	[scrollView_outgoing setHasVerticalScroller:(height < [textView_outgoing desiredSize].height)];
	
	//First, set the text entry subview to the exact height we want
	[[splitView_textEntryHorizontal subviewAtPosition:1] setMinDimension:height andMaxDimension:height];
	[splitView_textEntryHorizontal adjustSubviews];
	
	//Now, allow it to be resized again between the text view's minimum size and the max size which is based on the splitview's height
	[[splitView_textEntryHorizontal subviewAtPosition:1] setMinDimension:[self _textEntryViewProperHeightIgnoringUserMininum:YES] andMaxDimension:([splitView_textEntryHorizontal frame].size.height * MESSAGE_VIEW_MIN_HEIGHT_RATIO)];
}

/*!
 * @brief Returns the height our text entry view should be
 *
 * This method takes into account user preference, the amount of entered text, and the current window size to return
 * a height which is most ideal for the text entry view.
 *
 * @param ignoreUserMininum If YES, the user's preference for mininum height will be ignored
 */
- (NSInteger)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMininum
{
	NSInteger dividerThickness = [splitView_textEntryHorizontal dividerThickness];
	NSInteger allowedHeight = ([splitView_textEntryHorizontal frame].size.height / 2.0) - dividerThickness;
	NSInteger	height;
	
	//Our primary goal is to display all the entered text
	height = [textView_outgoing desiredSize].height;

	//But we must never fall below the user's prefered mininum or above the allowed height
	if (!ignoreUserMininum && height < entryMinHeight) {
		height = entryMinHeight;
	}
	if (height > allowedHeight) height = allowedHeight;
	
	return height;
}

#pragma mark Autocompletion
- (BOOL)canTabCompleteForPartialWord:(NSString *)partialWord
{
	return ([self contactsMatchingBeginningString:partialWord].count > 0 ||
			[self.chat.displayName rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound);
}

/*!
 * @brief Should the tab key cause an autocompletion if possible?
 *
 * We only tab to autocomplete for a group chat
 */
- (BOOL)textViewShouldTabComplete:(NSTextView *)inTextView
{
	if (self.chat.isGroupChat) {
		NSRange completionRange = inTextView.rangeForUserCompletion;
		NSString *partialWord = [inTextView.textStorage.string substringWithRange:completionRange];
		return [self canTabCompleteForPartialWord:partialWord]; 
	}
	
	return NO;
}

- (NSRange)textView:(NSTextView *)inTextView rangeForCompletion:(NSRange)charRange
{
	if (self.chat.isGroupChat && charRange.location > 0) {
		NSString *partialWord = nil;
		NSString *allText = [inTextView.textStorage.string substringWithRange:NSMakeRange(0, NSMaxRange(charRange))];
		NSRange whitespacePosition = [allText rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch];
		
		if (whitespacePosition.location == NSNotFound) {
			// We went back to the beginning of the string and still didn't find a whitespace; use the whole thing.
			partialWord = allText;
			whitespacePosition = NSMakeRange(0, 0);
		} else {
			// We found a whitespace, use from it until our current position.
			partialWord = [allText substringWithRange:NSMakeRange(NSMaxRange(whitespacePosition), allText.length - NSMaxRange(whitespacePosition))];
		}
		
		// If this matches any contacts or the room name, use this new range for autocompletion.
		if ([self canTabCompleteForPartialWord:partialWord]) {
			charRange = NSMakeRange(NSMaxRange(whitespacePosition), allText.length - NSMaxRange(whitespacePosition));
		}
	}
	
	return charRange;
}

- (NSArray *)contactsMatchingBeginningString:(NSString *)partialWord
{
	NSMutableArray *contacts = [NSMutableArray array];
	
	for (AIListContact *listContact in self.chat) {
		if ([listContact.UID rangeOfString:partialWord
								   options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound ||
			[listContact.formattedUID rangeOfString:partialWord
											options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound ||
			[listContact.displayName rangeOfString:partialWord
										   options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound) {
				[contacts addObject:listContact];
		}
	}
	
	return contacts;
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	NSMutableArray	*completions = nil;
	
	if (self.chat.isGroupChat) {
		NSString *suffix = nil;
		NSString *partialWord = [textView.textStorage.string substringWithRange:charRange];
		BOOL autoCompleteUID = [self.chat.account chatShouldAutocompleteUID:self.chat];
		
		//At the start of a line, append ": "
		if (charRange.location == 0) {
			suffix = @": ";
		}
		
		completions = [NSMutableArray array];
		
		for (AIListContact *listContact in [self contactsMatchingBeginningString:partialWord]) {
			NSString *displayName = [self.chat aliasForContact:listContact];
			
			if (!displayName)
				displayName = autoCompleteUID ? listContact.formattedUID : listContact.displayName;
			
			[completions addObject:(suffix ? [displayName stringByAppendingString:suffix] : displayName)];
		}
		
		if ([self.chat.displayName rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound) {
			[completions addObject:self.chat.displayName];
		}

		if ([completions count]) {			
			*index = 0;
		}
	}

	return [completions count] ? completions : words;
}

//User List ------------------------------------------------------------------------------------------------------------
#pragma mark User List
/*!
 * @brief Selected list objects
 *
 * An array of the list objects selected in the user list.
 */
- (NSArray *)selectedListObjects
{
	return [userListView arrayOfListObjects];
}

/*!
 * @brief Is the user list initially visible?
 */
- (BOOL)userListInitiallyVisible
{
	NSNumber *visibility = [adium.preferenceController preferenceForKey:[KEY_USER_LIST_VISIBLE_PREFIX stringByAppendingFormat:@"%@.%@",
																		 chat.account.internalObjectID,
																		 chat.name]
																  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	
	return visibility ? [visibility boolValue] : YES;
}

/*!
 * @brief Set visibility of the user list
 */
- (void)setUserListVisible:(BOOL)inVisible
{
	if (inVisible) {
		[self _showUserListView];
	} else {
		[self _hideUserListView];
	}
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:inVisible]
									   forKey:[KEY_USER_LIST_VISIBLE_PREFIX stringByAppendingFormat:@"%@.%@",
											   chat.account.internalObjectID,
											   chat.name]
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Returns YES if the user list is currently visible
 */
- (BOOL)userListVisible
{
	return [shelfView isShelfVisible];
}

/* @name	toggleUserlist
 * @brief	toggles the state of the userlist shelf
 */
- (void)toggleUserList
{
	if (chat.isGroupChat)
		[self setUserListVisible:![self userListVisible]];
}

- (void)toggleUserListSide
{
	if(chat.isGroupChat) {
		userListOnRight = !userListOnRight;
		
		// We'll update the actual side when this preference change is told to us.
		[adium.preferenceController setPreference:[NSNumber numberWithInteger:userListOnRight]
										   forKey:KEY_USER_LIST_ON_RIGHT
											group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
}

/*!
 * @brief Show the user list
 */
- (void)_showUserListView
{	
	[self setupShelfView];
	
	[shelfView setDrawShelfLine:NO];

	//Configure the user list
	[self _configureUserList];
	[self updateUserCount];

	//Add the user list back to our window if it's missing
	if (![self userListVisible]) {
		[self _updateUserListViewWidth];
		
		if (retainingScrollViewUserList) {
			[scrollView_userList release];
			retainingScrollViewUserList = NO;
		}
	}
}

/*!
 * @brief Hide the user list.
 *
 * We gain responsibility for releasing scrollView_userList after we hide it
 */
- (void)_hideUserListView
{
	if ([self userListVisible]) {
		[scrollView_userList retain];
		[scrollView_userList removeFromSuperview];
		retainingScrollViewUserList = YES;
		
		[userListController release];
		userListController = nil;
	
		//need to collapse the splitview
		[shelfView setShelfIsVisible:NO];
	}
}

/*!
 * @brief Configure the user list
 *
 * Configures the user list view and prepares it for display.  If the user list is not being shown, this configuration
 * should be avoided for performance.
 */
- (void)_configureUserList
{
	if (!userListController) {
		NSDictionary	*themeDict = [NSDictionary dictionaryNamed:USERLIST_THEME forClass:[self class]];
		NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:USERLIST_LAYOUT forClass:[self class]];
		
		//Create and configure a controller to manage the user list
		userListController = [[ESChatUserListController alloc] initWithContactListView:userListView
																		  inScrollView:scrollView_userList 
																			  delegate:self];
		[userListController setContactListRoot:chat];
		[userListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
		[userListController setHideRoot:YES];
	}
}

/*!
 * @brief Update the user list in response to changes
 *
 * This method is invoked when the chat's participating contacts change.  In resopnse, it sets correct visibility of
 * the user list, and updates the displayed users.
 */
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    //Update the user list
	AILogWithSignature(@"%i, so %@ %@",[self userListVisible], ([self userListVisible] ? @"reloading" : @"not reloading"),
					   userListController);
	
	[chat resortParticipants];
	
    if ([self userListVisible]) {
        [userListController reloadData];
		
		[self updateUserCount];
    }
}

- (void)updateUserCount
{
	NSString *userCount = nil;
	
	if (self.chat.containedObjects.count == 1) {
		userCount = AILocalizedString(@"1 user", nil);
	} else {
		userCount = AILocalizedString(@"%u users", nil);
	}
	
	[shelfView setResizeThumbStringValue:[NSString stringWithFormat:userCount, self.chat.containedObjects.count]];
}

/*!
 * @brief The selection in the user list changed
 *
 * When the user list selection changes, we update the chat's "preferred list object", which is used
 * elsewhere to identify the currently 'selected' contact for Get Info, Messaging, etc.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == userListView) {
		[chat setPreferredListObject:(AIListContact *)[userListView listObject]];
	}
}

/*!
 * @brief Perform default action on the selected user list object
 *
 * Here we could open a private message or display info for the user, however we perform no action
 * at the moment.
 */
- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(NSOutlineView *)sender
{
	if ([listObject isKindOfClass:[AIListContact class]]) {
		[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:(AIListContact *)listObject
												  onPreferredAccount:YES]];
	}
}

/* 
 * @brief Update the width of our user list view
 *
 * This method sets the width of the user list view to the most ideal value, and adjusts the other views in our
 * window to fill the remaining space.
 */
- (void)_updateUserListViewWidth
{
	NSInteger		width = [self _userListViewProperWidth];
	NSInteger		widthWithDivider = 1 + width;	//resize bar effective width  
	NSRect	tempFrame;

	//Size the user list view to the desired width
	tempFrame = [scrollView_userList frame];
	[scrollView_userList setFrame:NSMakeRect([shelfView frame].size.width - width,
											 tempFrame.origin.y,
											 width,
											 tempFrame.size.height)];
	
	//Size the message view to fill the remaining space
	tempFrame = [scrollView_messages frame];
	[scrollView_messages setFrame:NSMakeRect(tempFrame.origin.x,
											 tempFrame.origin.y,
											 [shelfView frame].size.width - widthWithDivider,
											 tempFrame.size.height)];

	//Redisplay both views and the divider
	[shelfView setNeedsDisplay:YES];
}

/*!
 * @brief Returns the width our user list view should be
 *
 * This method takes into account user preference and the current window size to return a width which is most
 * ideal for the user list view.
 */
- (NSInteger)_userListViewProperWidth
{
	NSInteger dividerThickness = 1;
	NSInteger allowedWidth = ([shelfView frame].size.width / 2.0) - dividerThickness;
	NSInteger width = userListMinWidth;
	
	//We must never fall below the user's prefered mininum or above the allowed width
	if (width > allowedWidth) width = allowedWidth;

	return width;
}

-(CGFloat)shelfSplitView:(KNShelfSplitView *)shelfSplitView validateWidth:(CGFloat)proposedWidth
{
	if (userListMinWidth != proposedWidth) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveUserListMinimumSize) object:nil];
		[self performSelector:@selector(saveUserListMinimumSize) withObject:nil afterDelay:0.5];
	}
	
	userListMinWidth = proposedWidth;
	
	return userListMinWidth;
}

//Split Views --------------------------------------------------------------------------------------------------
#pragma mark Split Views

// This method will be called after a RBSplitView is resized with setFrameSize: but before
// adjustSubviews is called on it.
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(CGFloat)oldDimension to:(CGFloat)newDimension
{
	[[sender subviewAtPosition:0] setDimension:[[sender subviewAtPosition:0] dimension] + (newDimension - oldDimension)];
}

// This method will be called whenever a subview's frame is changed, usually from inside adjustSubviews' final loop.
// You'd normally use this to move some auxiliary view to keep it aligned with the subview.
- (void)splitView:(RBSplitView*)sender changedFrameOfSubview:(RBSplitSubview*)subview from:(NSRect)fromRect to:(NSRect)toRect
{
	if ([sender subviewAtPosition:1] == subview) {
		if ([sender isDragging])
			entryMinHeight = NSHeight(toRect);
	}
}

- (void)splitViewDidHaveResizeDoubleClick:(KNShelfSplitView *)sender
{
	[self toggleUserList];
}

#pragma mark Shelfview
/* @name	setupShelfView
 * @brief	sets up shelfsplitview containing userlist & contentviews
 */
 -(void)setupShelfView
{
	[shelfView setShelfWidth:userListMinWidth];
	
	AILogWithSignature(@"ShelfView %@ (content view is %@) --> superview %@, in window %@; frame %@; content view %@ shelf view %@ in window %@",
					   shelfView, [shelfView contentView], [shelfView superview], [shelfView window], NSStringFromRect([[shelfView superview] frame]),
					   splitView_textEntryHorizontal,
					   scrollView_userList, [scrollView_userList window]);
	[shelfView setContextButtonImage:[NSImage imageNamed:@"sidebarActionWidget"]];
	
	[shelfView setShelfIsVisible:YES];
}

-(NSMenu *)contextMenuForShelfSplitView:(KNShelfSplitView *)shelfSplitView
{
	return chat.actionMenu;
}

#pragma mark Undo
- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView
{
	if (!undoManager)
		undoManager = [[NSUndoManager alloc] init];

	return undoManager;
}


@end
