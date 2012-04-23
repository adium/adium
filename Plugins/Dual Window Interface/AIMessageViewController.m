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
#import "AIMessageWindowOutgoingScrollView.h"
#import "AIGradientView.h"

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIServiceIcons.h>

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>


#import <PSMTabBarControl/NSBezierPath_AMShading.h>

//Heights and Widths
#define MESSAGE_VIEW_MIN_HEIGHT_RATIO		0.5f					// Mininum height ratio of the message view
#define MESSAGE_VIEW_MIN_WIDTH_RATIO		0.5f					// Mininum width ratio of the message view
#define ENTRY_TEXTVIEW_MIN_HEIGHT			20						// Mininum height of the text entry view
#define USER_LIST_DEFAULT_WIDTH				120						// Default width of the user list

//Preferences and files
#define MESSAGE_VIEW_NIB					@"MessageView"				// Filename of the message view nib
#define	USERLIST_THEME						@"UserList Theme"			// File name of the user list theme
#define	USERLIST_LAYOUT						@"UserList Layout"			// File name of the user list layout
#define	KEY_ENTRY_TEXTVIEW_MIN_HEIGHT		@"Minimum Text Height"		// Preference key for text entry height
#define	KEY_ENTRY_USER_LIST_MIN_WIDTH		@"UserList Minimum Width"	// Preference key for user list width
#define KEY_USER_LIST_VISIBLE_PREFIX		@"Userlist Visible Chat:"	// Preference key prefix for user list visibility
#define KEY_USER_LIST_ON_RIGHT				@"UserList On Right"		// Preference key for user list being on the right

@interface AIMessageViewController ()
- (id)initForChat:(AIChat *)inChat;
- (void)chatStatusChanged:(NSNotification *)notification;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)_configureMessageDisplay;
- (void)_createAccountSelectionView;
- (void)_destroyAccountSelectionView;
- (void)_configureTextEntryView;
- (void)_updateTextEntryViewHeight;
- (CGFloat)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMinimum;
- (void)_showUserListView;
- (void)_hideUserListView;
- (void)_configureUserList;
- (CGFloat)_userListViewDividerPositionIgnoringUserMinimum:(BOOL)ignoreUserMinimum;
- (void)updateFramesForAccountSelectionView;
- (void)saveUserListMinimumSize;
- (BOOL)userListInitiallyVisible;
- (void)setUserListVisible:(BOOL)inVisible;
- (void)updateUserCount;

- (NSArray *)contactsMatchingBeginningString:(NSString *)partialWord;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)gotFilteredMessageToSendLater:(NSAttributedString *)filteredMessage receivingContext:(NSMutableDictionary *)alertDict;
- (void)outgoingTextViewDesiredSizeDidChange:(NSNotification *)notification;
@end

@implementation AIMessageViewController

/*!
 * @brief Create a new message view controller
 */
+ (AIMessageViewController *)messageDisplayControllerForChat:(AIChat *)inChat
{
    return [[self alloc] initForChat:inChat];
}


/*!
 * @brief Initialize
 */
- (id)initForChat:(AIChat *)inChat
{
    if ((self = [super init])) {
		AIListContact	*contact;
		//Init
		chat = inChat;
		contact = chat.listObject;
		accountSelectionVisible = NO;
		userListController = nil;
		suppressSendLaterPrompt = NO;
		
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
		[self _configureUserList];
		
		//Draw background
		[actionBarView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.98f alpha:1.0f]];
		[actionBarView setMiddleColor:[NSColor colorWithCalibratedWhite:0.91f alpha:1.0f]];

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
	AILogWithSignature(@"");
	AIListContact	*contact = chat.listObject;
	
	[adium.preferenceController unregisterPreferenceObserver:self];

	//Store our minimum height for the text entry area, and minimim width for the user list
	[adium.preferenceController setPreference:[NSNumber numberWithDouble:entryMinHeight]
										 forKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	if (userListController) {
		[self saveUserListMinimumSize];
	}
	
	//Save the base writing direction
	if (contact && initialBaseWritingDirection != [textView_outgoing baseWritingDirection])
		[contact setBaseWritingDirection:[textView_outgoing baseWritingDirection]];

	chat = nil;

	//remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    //Account selection view
	[self _destroyAccountSelectionView];
	
	[messageDisplayController messageViewIsClosing];
	
	//release menuItem
	view_contents = nil;
	undoManager = nil;
}

- (void)saveUserListMinimumSize
{
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self userListVisible]]
									   forKey:[KEY_USER_LIST_VISIBLE_PREFIX stringByAppendingFormat:@"%@.%@",
											   chat.account.internalObjectID,
											   chat.name]
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	
	[adium.preferenceController setPreference:[NSNumber numberWithDouble:userListMinWidth]
										 forKey:KEY_ENTRY_USER_LIST_MIN_WIDTH
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

- (void)updateGradientColors
{
	NSColor *darkerColor = [NSColor colorWithCalibratedWhite:0.90f alpha:1.0f];
	NSColor *lighterColor = [NSColor colorWithCalibratedWhite:0.92f alpha:1.0f];
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
	
	messageWindowController = nil;
}

- (void)messageViewAddedToWindowController:(AIMessageWindowController *)inWindowController
{
	if (inWindowController) {
		[userListController contactListWasAddedBackToWindow];
	}
	
	if (inWindowController != messageWindowController) {
		messageWindowController = inWindowController;
		
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
	if (userListView) {
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
	messageDisplayController = [adium.interfaceController messageDisplayControllerForChat:chat];

	[scrollView_messages setDocumentView:[messageDisplayController messageView]];
	[[scrollView_messages documentView] setFrame:[scrollView_messages visibleRect]];
	
	[scrollView_messages setAccessibilityChild:[scrollView_messages documentView]];
	
	[textView_outgoing setNextResponder:view_contents];
	[[scrollView_messages documentView] setNextResponder:textView_outgoing];
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
			icon = [icon copy];
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
							  modalDelegate:self /* Will release after the sheet ends */
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                contextInfo:(__bridge_retained void *)([NSNumber numberWithInteger:messageSendingAbility]) /* Will release after the sheet ends */];
		}
    }
}

/*!
 * @brief Send Later button was pressed
 */ 
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	AIChatSendingAbilityType messageSendingAbility = [(__bridge NSNumber *)contextInfo intValue];

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
		
		[adium.contentController filterAttributedString:[[textView_outgoing textStorage] copy]
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

	listContact = [alertDict objectForKey:@"TEMP-ListContact"];
	[alertDict removeObjectForKey:@"TEMP-ListContact"];
	
	[adium.contactAlertsController addAlert:alertDict 
								 toListObject:listContact
							 setAsNewDefaults:NO];
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
	if (!accountSelectionVisible) {
		//Setup the account selection view
		[view_accountSelection setChat:chat];
		[self updateGradientColors];
		
		//Insert the account selection view at the top of our view
		accountSelectionVisible = YES;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountSelectionViewFrameDidChange:)
													 name:AIViewFrameDidChangeNotification
												   object:view_accountSelection];
		
		[self updateFramesForAccountSelectionView];
	} else {
		[view_accountSelection setChat:chat];
	}
}

/*!
 * @brief Hide the account selection view
 */
- (void)_destroyAccountSelectionView
{
	if (accountSelectionVisible) {
		//Remove the observer
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AIViewFrameDidChangeNotification
													  object:view_accountSelection];

		accountSelectionVisible = NO;

		//Redisplay everything
		[self updateFramesForAccountSelectionView];
	}
}

/*!
 * @brief Position the account selection view, if it is present, and the messages/text entry splitview appropriately
 */
- (void)updateFramesForAccountSelectionView
{
	CGFloat accountSelectionHeight = (accountSelectionVisible ? NSHeight(view_accountSelection.frame) : 0.0f);
	
	NSRect verticalFrame = splitView_verticalSplit.frame;
	verticalFrame.size.height = NSHeight(view_contents.frame) - accountSelectionHeight - NSMinY(verticalFrame) - 2;
	verticalFrame.size.width = NSWidth(view_contents.frame);
	[splitView_verticalSplit setFrame:verticalFrame];
	
	[view_accountSelection setFrameOrigin:NSMakePoint(NSMinX(splitView_verticalSplit.frame), NSMaxY(splitView_verticalSplit.frame))];
	
	[view_accountSelection setHidden:!accountSelectionVisible];
	
	[self _updateTextEntryViewHeight];
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
		
		if (firstTime || [key isEqualToString:KEY_USER_LIST_ON_RIGHT]) {
			userListOnRight = [[prefDict objectForKey:KEY_USER_LIST_ON_RIGHT] boolValue];

			NSRect userListFrame = view_userList.frame;
			//Rearrange the splitviews
			if (userListOnRight) {
				[view_userList removeFromSuperviewWithoutNeedingDisplay];
				[splitView_verticalSplit addSubview:view_userList];
				userListFrame.origin.x = splitView_textEntryHorizontal.frame.size.width;
			} else {
				[[splitView_textEntryHorizontal superview] removeFromSuperviewWithoutNeedingDisplay];
				[splitView_verticalSplit addSubview:[splitView_textEntryHorizontal superview]];
				userListFrame.origin.x = 0.0f;
			}
			[view_userList setFrame:userListFrame];
			[splitView_verticalSplit adjustSubviews];
		}
		
		if (firstTime || [key isEqualToString:KEY_ENTRY_USER_LIST_MIN_WIDTH]) {
			userListMinWidth = [[prefDict objectForKey:KEY_ENTRY_USER_LIST_MIN_WIDTH] doubleValue];
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
															 group:PREF_GROUP_DUAL_WINDOW_INTERFACE] doubleValue];
	if (entryMinHeight <= 0)
		entryMinHeight = ENTRY_TEXTVIEW_MIN_HEIGHT;
	
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
	
	// Disable elastic scroll
	// Remove the check on 10.7+
	// Not sure why it won't work in AIMessageEntryTextView
	if ([[textView_outgoing enclosingScrollView] respondsToSelector:@selector(setVerticalScrollElasticity:)]) {
		[[textView_outgoing enclosingScrollView] setVerticalScrollElasticity:1]; // Swap 1 with NSScrollElasticityNone on 10.7+
	}
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
	[self _updateTextEntryViewHeight];
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
 */
- (void)_updateTextEntryViewHeight
{
	//Store the user's height so that autoresizing isn't messed up
	CGFloat oldeHeight = entryMinHeight;
	[splitView_textEntryHorizontal setPosition:[self _textEntryViewProperHeightIgnoringUserMininum:NO]
							  ofDividerAtIndex:0];
	entryMinHeight = oldeHeight;
}

/*!
 * @brief Returns the height our text entry view should be
 *
 * This method takes into account user preference, the amount of entered text, and the current window size to return
 * a height which is most ideal for the text entry view.
 *
 * @param ignoreUserMininum If YES, the user's preference for mininum height will be ignored
 */
- (CGFloat)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMinimum
{
	//Our primary goal is to display all of the entered text
	CGFloat desiredHeight = [textView_outgoing desiredSize].height;
	
	//But we must never fall below the user's prefered minimum
	if (!ignoreUserMinimum && (desiredHeight < entryMinHeight))
		desiredHeight = entryMinHeight;
	
	if (desiredHeight < ENTRY_TEXTVIEW_MIN_HEIGHT)
		desiredHeight = ENTRY_TEXTVIEW_MIN_HEIGHT;
	
	//Or above the allowed height
	if (desiredHeight >= (splitView_textEntryHorizontal.frame.size.height * MESSAGE_VIEW_MIN_HEIGHT_RATIO))
		return (splitView_textEntryHorizontal.frame.size.height * MESSAGE_VIEW_MIN_HEIGHT_RATIO);
	
	CGFloat splitViewHeight = NSHeight(splitView_textEntryHorizontal.frame);
	CGFloat dividerThickness = [splitView_textEntryHorizontal dividerThickness];
	
	return splitViewHeight - desiredHeight - dividerThickness;
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
		// Add to the list if it matches: (1) The display name for the chat (alias fallback to default display name), 
		// (2) The UID, or (3) the display name
		if ([[self.chat displayNameForContact:listContact] rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound
			|| [listContact.UID rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound
			|| [listContact.displayName rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound) {
			[contacts addObject:listContact];
			AILogWithSignature(@"Added match %@ with nick %@; UID: %@; formattedUID: %@; displayName: %@", listContact, [self.chat aliasForContact:listContact], listContact.UID, listContact.formattedUID, listContact.displayName);
		}
	}
	
	return contacts;
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)idx
{
	NSMutableArray	*completions = nil;
	
	if (self.chat.isGroupChat) {
		NSString *suffix = [self.chat.account suffixForAutocomplete:self.chat forPartialWordRange:charRange];
		NSString *prefix = [self.chat.account prefixForAutocomplete:self.chat forPartialWordRange:charRange];
		NSString *partialWord = [textView.textStorage.string substringWithRange:charRange];
		BOOL autoCompleteUID = [self.chat.account chatShouldAutocompleteUID:self.chat];
		
		// Check to see if the prefix is already present
		if (charRange.location != 0 && charRange.location >= prefix.length) {
			prefix = [[textView.textStorage.string substringWithRange:
					   NSMakeRange(charRange.location-prefix.length, prefix.length)] isEqualToString:prefix] ? nil : prefix;
		}
		
		// If we need to add a prefix, insert it into the text, then call [textView complete:] again; return early with no completions.
		if (prefix.length > 0) {
			[textView.textStorage insertAttributedString:[[NSAttributedString alloc] initWithString:prefix] atIndex:charRange.location];
			[textView complete:nil];
			return nil;
		}
		
		// Check to see if the suffix is already present
		if (charRange.location + charRange.length + suffix.length <= textView.textStorage.string.length ) {
			suffix = [[textView.textStorage.string substringWithRange:
					   NSMakeRange(charRange.location + charRange.length, suffix.length)] isEqualToString:suffix] ? nil : suffix;
		}
		
		completions = [NSMutableArray array];
		
		// For each matching contact:
		for (AIListContact *listContact in [self contactsMatchingBeginningString:partialWord]) {
			// Complete the chat alias.
			NSString *completion = [self.chat aliasForContact:listContact];
			
			// Otherwise, complete the UID (if we're completing UIDs for this chat) or the display name.
			if (!completion)
				completion = autoCompleteUID ? listContact.formattedUID : listContact.displayName;
			
			[completions addObject:(suffix ? [completion stringByAppendingString:suffix] : completion)];
		}
		
		// Add the name of this chat to the completions if it matches.
		if ([self.chat.displayName rangeOfString:partialWord options:(NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound) {
			[completions addObject:self.chat.displayName];
		}
		
		// Select the first completion by default.
		if ([completions count]) {			
			*idx = 0;
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
	return ![view_userList isHidden];
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
	if (chat.isGroupChat && view_userList.superview == nil) {
		[splitView_verticalSplit addSubview:view_userList];
	}
	[self updateUserCount];
	[userListController reloadData];

	[view_userList setHidden:NO];
	//Manually set the divider's position otherwise view_userList will shrink
	[splitView_verticalSplit setPosition:[self _userListViewDividerPositionIgnoringUserMinimum:NO]
						ofDividerAtIndex:0];
	[splitView_verticalSplit adjustSubviews];
}

/*!
 * @brief Hide the user list.
 */
- (void)_hideUserListView
{
	if (!chat.isGroupChat) {
		NSRect frame = view_userList.frame;
		frame.size.width = 0;
		view_userList.frame = frame;
		[view_userList removeFromSuperview];
	}
	[view_userList setHidden:YES];
	[splitView_verticalSplit adjustSubviews];
}

/*!
 * @brief Configure the user list
 *
 * Configures the user list view and prepares it for display.  If the user list is not being shown, this configuration
 * should be avoided for performance.
 */
- (void)_configureUserList
{
	if (chat.isGroupChat) {
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
	[chat resortParticipants];

	/* Even if we're not viewing the user list, we can't risk it keeping stale information about potentially released objects */
	[userListController reloadData];

    if ([self userListVisible]) {
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
	
	[label_userCount setStringValue:[NSString stringWithFormat:userCount, self.chat.containedObjects.count]];
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
		// We should default to this contact's account
		[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:(AIListContact *)listObject
																		onPreferredAccount:NO]];
	}
}

/*!
 * @brief Capture all text input
 *
 * Capture all text input in our user list and forward it to the text entry view.
 * This prevents the user list from becoming a black hole if it's clicked on.
 */
- (BOOL)forwardKeyEventToFindPanel:(NSEvent *)theEvent
{
	[self makeTextEntryViewFirstResponder];
	
	[self.textEntryView keyDown:theEvent];
	
	return YES;
}

/*!
 * @brief Returns the width our user list view should be
 *
 * This method takes into account user preference and the current window size to return a width which is most
 * ideal for the user list view.
 */
- (CGFloat)_userListViewDividerPositionIgnoringUserMinimum:(BOOL)ignoreUserMinimum
{
	CGFloat splitViewWidth = splitView_verticalSplit.frame.size.width;
	CGFloat allowedWidth = AIfloor(splitViewWidth / 2) - [splitView_verticalSplit dividerThickness];
	CGFloat width = ignoreUserMinimum ? USER_LIST_DEFAULT_WIDTH : userListMinWidth;
	
	if (width < USER_LIST_DEFAULT_WIDTH)
		width = USER_LIST_DEFAULT_WIDTH;
	if (width > allowedWidth)
		width = allowedWidth;
	
	if (userListOnRight)
		return splitViewWidth - width;
	else
		return width;
}

- (IBAction)showActionMenu:(id)sender {
	[chat.actionMenu popUpMenuPositioningItem:nil atLocation:performAction.frame.origin inView:actionBarView];
}

//Split Views --------------------------------------------------------------------------------------------------
#pragma mark Split Views
/* 
 * @brief Update the sizes of our user splitviews
 */
- (void)splitViewWillResizeSubviews:(NSNotification *)aNotification
{
	if ([aNotification object] == splitView_verticalSplit) {
		if (NSWidth(view_userList.frame) > 0) {
			userListMinWidth = NSWidth(view_userList.frame);
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveUserListMinimumSize) object:nil];
			[self performSelector:@selector(saveUserListMinimumSize) withObject:nil afterDelay:0.5];
		}
	} else if ([aNotification object] == splitView_textEntryHorizontal && [splitView_textEntryHorizontal inLiveResize]) {
		entryMinHeight = NSHeight(textView_outgoing.frame);
	}
}

/* 
 * @brief Set the appropriate preference when the user list is dragged open or closed and update user count.
 */
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	if ([aNotification object] == splitView_verticalSplit) {
		NSRect userListFrame = view_userList.frame;
		if (NSWidth(userListFrame) > 0) {
			[self updateUserCount];
		}
	}
}

/* 
 * @brief Keep the userlist and text entry view the same size when the window is resized.
 */
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if ([splitView inLiveResize] || adium.interfaceController.activeChat != chat) {
		// division between user list and message view
		if (splitView == splitView_verticalSplit) {
			NSRect currentFrame = splitView.frame;
			NSRect msgFrame = [splitView_textEntryHorizontal superview].frame;
			NSRect userFrame = view_userList.frame;
			CGFloat dividerThickness = [splitView dividerThickness];
			BOOL userListVisible = [self userListVisible];
			BOOL userListAttached = view_userList.superview != nil;
			
			msgFrame.size.height = currentFrame.size.height;
			userFrame.size.height = currentFrame.size.height;
			
			if (userListVisible) {
				if (userListOnRight) {
					userFrame.size.width = currentFrame.size.width - [self _userListViewDividerPositionIgnoringUserMinimum:NO];
				} else
					userFrame.size.width = [self _userListViewDividerPositionIgnoringUserMinimum:NO];
			} else {
				userFrame.size.width = 0;
				if([view_userList isHidden]) {
					msgFrame.size.width += 1 - dividerThickness;
				}
			}
			
			if (userListOnRight && userListAttached){
				msgFrame.size.width = currentFrame.size.width - userFrame.size.width - dividerThickness;
				userFrame.origin.x = msgFrame.size.width + dividerThickness;
			} else if (userListAttached) {
				msgFrame.origin.x = NSMaxX(userFrame) + dividerThickness;
				msgFrame.size.width = currentFrame.size.width - userFrame.size.width - dividerThickness;
			} else {
				msgFrame.size.width = currentFrame.size.width;
				userFrame.origin.x = userListOnRight? currentFrame.size.width + dividerThickness : -1;
			}
			
			[view_userList setFrame:userFrame];
			[[splitView_textEntryHorizontal superview] setFrame:msgFrame];
		
		// divition between text entry and message view
		} else if (splitView == splitView_textEntryHorizontal) {
			NSRect currentFrame = splitView.frame;
			NSRect msgFrame = view_messages.frame;
			NSRect textFrame = [scrollView_textEntry superview].frame;
			CGFloat dividerThickness = [splitView dividerThickness];
			
			textFrame.size.width = currentFrame.size.width;
			msgFrame.size.width = currentFrame.size.width;
			msgFrame.size.height = currentFrame.size.height - textFrame.size.height - dividerThickness;
			
			textFrame.origin.y = msgFrame.size.height + dividerThickness;
			
			[view_messages setFrame:msgFrame];
			[[scrollView_textEntry superview] setFrame:textFrame];
		} else {
			[splitView adjustSubviews];
		}
	} else {
		[splitView adjustSubviews];
	}
}

/* 
 * @brief Don't allow the text entry or message view to be collapsed
 */
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	if (subview == view_messages || subview == [splitView_textEntryHorizontal superview])
		return NO;
	else if (subview == [scrollView_textEntry superview])
		return NO;
	
	return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	if (splitView == splitView_verticalSplit) {
		if (subview == view_userList)
			return YES;
	}
	
	return NO;
}

/* 
 * @brief Set the min size of the text entry view and the userlist
 */
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == splitView_textEntryHorizontal) {
		//Min size of text entry view
		return [self _textEntryViewProperHeightIgnoringUserMininum:YES];
	} else if (splitView == splitView_verticalSplit) {
		//On the right: min size of user list
		//On the left: max size of user list
		if (chat.isGroupChat) {
			if (userListOnRight)
				return AIfloor([self _userListViewDividerPositionIgnoringUserMinimum:YES] + 0.5f);
			else
				return AIfloor((splitView_verticalSplit.frame.size.width / 2) + 0.5f);
		} else {
			if (userListOnRight)
				return AIfloor(splitView_verticalSplit.frame.size.width + 0.5f);
			else
				return 0;
		}
	}
	
	return proposedMax;
}

/* 
 * @brief Set the max size of the text entry view and userlist
 *
 * Lock the user list on non-MUCs; this is done here instead of hiding the divider so that there isn't
 * a visual change of positioning when changing tabs between an MUC and 1v1
 */
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == splitView_textEntryHorizontal) {
		//Max size of text entry view
		return AIfloor(splitView_textEntryHorizontal.frame.size.height * MESSAGE_VIEW_MIN_HEIGHT_RATIO + 0.5f);
	}  else if (splitView == splitView_verticalSplit) {
		//On the right: max size of user list
		//On the left: min size of the user list
		if (chat.isGroupChat) {
			if (userListOnRight)
				return AIfloor(splitView_verticalSplit.frame.size.width / 2);
			else
				return [self _userListViewDividerPositionIgnoringUserMinimum:YES];
		} else {
			if (userListOnRight)
				return splitView_verticalSplit.frame.size.width;
			else
				return 0;
		}
	}
	
	return proposedMin;
}

#pragma mark Undo
- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView
{
	if (!undoManager)
		undoManager = [[NSUndoManager alloc] init];

	return undoManager;
}


@end
