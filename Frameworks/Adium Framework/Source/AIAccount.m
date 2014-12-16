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

#import <Adium/AIAbstractAccount.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/ESFileTransfer.h>
#import "AIStatusItem.h"
#import "AIStatus.h"
#import "AdiumAccounts.h"
#import "AILoggerPlugin.h"

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>

#import "DCJoinChatViewController.h"
#import "AIChatControllerProtocol.h"
#import "AIMessageWindowController.h"
#import "AIMessageWindow.h"
#import "AIInterfaceControllerProtocol.h"
#import "AIStatusControllerProtocol.h"

#define NEW_ACCOUNT_DISPLAY_TEXT			AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

@interface AIAccountDeletionDialog : NSObject <AIAccountControllerRemoveConfirmationDialog> {
	AIAccount *account;
	NSAlert *alert;
	id userData;
}

- (id)initWithAccount:(AIAccount*)ac alert:(NSAlert*)al;

@property (readwrite, retain, nonatomic) id userData;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation AIAccountDeletionDialog

- (id)initWithAccount:(AIAccount*)ac alert:(NSAlert*)al {
	if((self = [super init])) {
		account = ac;
		alert = [al retain];
	}
	return self;
}

- (void)dealloc {
	[alert release];
	[userData release];
	[super dealloc];
}

@synthesize userData;

- (void)runModal {
	[self alertDidEnd:alert returnCode:[alert runModal] contextInfo:NULL];
}

- (void)beginSheetModalForWindow:(NSWindow*)window {
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[account alertForAccountDeletion:self didReturn:returnCode];
}

@end

//Proxy types for applescript
typedef enum
{
	Adium_Proxy_HTTP_AS = 'HTTP',
	Adium_Proxy_SOCKS4_AS = 'SCK4',
	Adium_Proxy_SOCKS5_AS = 'SCK5',
	Adium_Proxy_Default_HTTP_AS = 'DHTP',
	Adium_Proxy_Default_SOCKS4_AS = 'DSK4',
	Adium_Proxy_Default_SOCKS5_AS = 'DSK5',
    Adium_Proxy_Tor_AS = 'TOS5',
	Adium_Proxy_None_AS = 'NONE'
} AdiumProxyTypeApplescript;

@interface AIAccount(AppleScriptPRIVATE)
- (AdiumProxyType)proxyTypeFromApplescript:(AdiumProxyTypeApplescript)proxyTypeAS;
- (AdiumProxyTypeApplescript)applescriptProxyType:(AdiumProxyType)proxyType;
@end

/*!
 * @class AIAccount
 * @brief An account
 *
 * This abstract class represents an account the user has setup in Adium.  Subclass this for every service.
 */
@implementation AIAccount

/*!
 * @brief Init Account
 *
 * Init this account instance
 */
- (void)initAccount
{
}

- (void)dealloc
{
	[formattedUID release]; formattedUID = nil;
	[accountStatus release]; accountStatus = nil;
	[waitingToReconnect release]; waitingToReconnect = nil;
	[connectionProgressString release]; connectionProgressString = nil;
	[currentDisplayName release]; currentDisplayName = nil;

    [lastDisconnectionError release];
    [delayedUpdateStatusTargets release];
    [delayedUpdateStatusTimer invalidate]; [delayedUpdateStatusTimer release];

    /* Our superclass releases internalObjectID in its dealloc, so we should set it to nil when do.
     * We could just depend upon its implementation, but this is more robust.
     */
    [internalObjectID release]; internalObjectID = nil; 

    [self _stopAttributedRefreshTimer];
    [autoRefreshingKeys release]; autoRefreshingKeys = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [adium.preferenceController unregisterPreferenceObserver:self];

	[super dealloc];
}

/*!
 * @brief Connect
 *
 * Connect the account, transitioning it into an online state.
 */
- (void)connect
{
	//We are connecting
	[self setValue:[NSNumber numberWithBool:YES] forProperty:@"isConnecting" notify:NotifyNow];
}

/*!
 * @brief rejoinChat
 * 
 * Rejoin the open group chats after disconnect
 */
-(BOOL)rejoinChat:(AIChat*)chat
{
	return NO;
}	

/*!
 * @brief Do group chats support topics?
 */
- (BOOL)groupChatsSupportTopic
{
	return NO;
}

/*!
 * @brief Set a chat's topic
 *
 * This only has an effect on group chats.
 */
- (void)setTopic:(NSString *)topic forChat:(AIChat *)chat
{
}

/*!
 * @brief Disconnect
 *
 * Disconnect the account, transitioning it into an offline state.
 */
- (void)disconnect
{
	[self cancelAutoReconnect];
	[self setValue:nil forProperty:@"isConnecting" notify:NotifyLater];

	[self notifyOfChangedPropertiesSilently:NO];
}

/*!
 * @brief Disconnect as a result of the network connection dropping out
 *
 * The default implementation is identical to [self disconect], but subclasses may want to act differently
 * if the network connection is gone than if the user chose to disconnect.
 *
 * Subclasses should call super's implementation.
 */
- (void)disconnectFromDroppedNetworkConnection
{
	[self disconnect];
}

/*!
 * @brief Register an account
 *
 * Register an account on this service using the currently entered information.  This is for services which support
 * in-client registration such as jabber.
 */
- (void)performRegisterWithPassword:(NSString *)inPassword
{

}

/*!
 * @brief The UID will be changed. The account has a chance to perform modifications
 *
 * For example, MSN adds \@hotmail.com to the proposedUID and returns the new value
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	return proposedUID;
}

/*!
 * @brief The account's UID changed
 */
- (void)didChangeUID
{

}

/*!
 * @brief The account will be deleted
 *
 * The default implementation disconnects the account.  Subclasses should call super's implementation.
 * If asynchronous behavior is required, the next three methods should be overridden instead.
 */
- (void)willBeDeleted
{
	[self setShouldBeOnline:NO];

	//Remove our contacts immediately.
	[self removeAllContacts];
}

/*!
 * @brief Perform the deletion of this account
 *
 * This should be called only after proper confirmation has been made by the user.
 */
- (void)performDelete
{
	[adium.accountController deleteAccount:self];
}

- (id<AIAccountControllerRemoveConfirmationDialog>)confirmationDialogForAccountDeletion
{
	//Will be released in alertForAccountDeletion:didReturn:
	return [[AIAccountDeletionDialog alloc] initWithAccount:self alert:[self alertForAccountDeletion]];
}

/*!
 * @brief The alert used for confirming the account deletion
 *
 * Meant for subclassers. By default, returns the dialog that asks the user if the account should really be deleted (and how).
 */
- (NSAlert*)alertForAccountDeletion
{
	return [NSAlert alertWithMessageText:AILocalizedString(@"Delete Account",nil)
						   defaultButton:AILocalizedString(@"Delete",nil)
						 alternateButton:AILocalizedString(@"Cancel",nil)
							 otherButton:nil
			   informativeTextWithFormat:AILocalizedString(@"Delete the account %@?",nil), ([self.formattedUID length] ? self.formattedUID : NEW_ACCOUNT_DISPLAY_TEXT)];
}

/*!
 * @brief The dialog asking for confirmation for deleting the account did return.
 *
 * @param dialog The dialog that has completed
 * @param returnCode One of the regular NSAlert return codes
 *
 * This method should be overridden when alertForAccountDeletion: was overridden, and/or asynchronous behavior is required.
 * This implementation disconnects and deletes the account from the accounts list when returnCode == NSAlertDefaultReturn.
 *
 * If this implementation is not called, dialog should be released by the subclass.
 */
- (void)alertForAccountDeletion:(id<AIAccountControllerRemoveConfirmationDialog>)dialog didReturn:(NSInteger)returnCode
{
	if(returnCode == NSAlertDefaultReturn) {
		[self performDelete];
	}

	[(AIAccountDeletionDialog*)dialog release];
}

/*!
 * @brief A formatted UID which may include additional necessary identifying information.
 *
 * For example, an AIM account (tekjew) and a .Mac account (tekjew@mac.com, entered only as tekjew) may appear identical
 * without service information (tekjew). The explicit formatted UID is therefore tekjew@mac.com
 */
- (NSString *)explicitFormattedUID
{
	return self.formattedUID;
}

/*!
 * @brief Use our host for the servername when storing password
 *
 * This should be YES for services which depend upon server information. For example, a password for an IRC account
 * is uniqued by what server it is on.
 */
- (BOOL)useHostForPasswordServerName
{
	return NO;
}

/*!
 * @brief Use our internal object ID for the username when storing password
 *
 * For accounts whose signup process may not be contingent upon the UID. For example, a Twitter account using OAuth might
 * not know its UID when it wants to save itself.
 */
- (BOOL)useInternalObjectIDForPasswordName
{
	return NO;
}

//Properties -----------------------------------------------------------------------------------------------------------
#pragma mark Properties
/*!
 * @brief Send Autoresponses while away
 *
 * Subclass to alter the behavior of this account with regards to autoresponses.  Certain services expect the client to
 * auto-respond with away messages.  Adium will provide this behavior automatically if desired.
 */
- (BOOL)supportsAutoReplies
{
	return NO;
}

/*!
 * @brief Disconnect on fast user switch
 *
 * It may be required for a service to disconnect when logged in users change.  If this is the case, subclass this
 * method to return YES and Adium will automatically disconnect and reconnect on FUS events.
 */
- (BOOL)disconnectOnFastUserSwitch
{
	return NO;
}

/*!
 * @brief Connectivity based on network reachability
 *
 * By default, accounts are automatically disconnected and reconnected when network reachability changes.  Accounts
 * that do not require persistent network connections can choose to disable this by returning NO from this method.
 */
- (BOOL)connectivityBasedOnNetworkReachability
{
	return YES;
}

/*!
 * @brief Suppress typing notifications after send
 *
 * Some protocols require a 'Stopped typing' notification to be sent along with an instant message.  Other protocols
 * implicitly assume that typing has stopped with an incoming message and the extraneous typing notification may cause
 * strange behavior.  Return YES from this method to suppress the sending of a stopped typing notification along with
 * messages.
 */
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return NO;
}

/*!
 * @brief Support server-side storing of messages to offline users?
 *
 * Some protocols store messages to offline contacts on the server. Subclasses may return YES if their service supports 
 * this. Adium will not store the message as an Event, and will just send it along to the server. This may cause a Gaim
 * error on Jabber if the Jabber server they are using is down.
 */
- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return NO;
}

/*!
 * @brief Support messaging invisible contacts?
 *
 * This will only be called if the protocol returns NO to -[self canSendOfflineMessageToContact:] 
 * If invisible contacts exist and can be messaged, return YES.
 * If the protocol has no concept of invisible contacts, or invisible contacts can't be messaged, return NO.
 */
- (BOOL)maySendMessageToInvisibleContact:(AIListContact *)inContact
{
	return YES;
}

/*!
 * @brief Should offline messages be sent without prompting the user?
 *
 * If -[self canSendOfflineMessageToContact:] returns YES, Adium typically asks the user whether or not to send a message
 * to be stored on the server. If sendOfflineMessagesWithoutPrompting returns YES, this prompt is always suppressed.
 *
 * This should only be true if offline messaging is a well-established expectation for the service. We assume that
 * this is the case by default.
 */
- (BOOL)sendOfflineMessagesWithoutPrompting
{
	return YES;
}

/*!
 * @brief Does the account itself display file transfer messages in chat windows?
 *
 * If YES, Adium won't attempt to display messages in chat windows regarding file transfers.
 * If NO, Adium automatically displays appropriate messages in open chats.
 */
- (BOOL)accountDisplaysFileTransferMessages
{
	return NO;
}

/*!
 * @brief Does the account manage its own cache of serverside contact icons?
 */
- (BOOL)managesOwnContactIconCache
{
	return NO;
}

/*!
 * @brief Called once the display name has been properly filtered
 *
 * Subclasses may override to pass this name on to the server if appropriate.
 * Super's implementation should then be called.
 */
- (void)gotFilteredDisplayName:(NSAttributedString *)attributedDisplayName
{
	[self updateLocalDisplayNameTo:attributedDisplayName];
}

- (NSImage *)userIcon
{
	NSData	*iconData = [self userIconData];
	return (iconData ? [[[NSImage alloc] initWithData:iconData] autorelease] : nil);
}

@synthesize isTemporary;

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
/*!
 * @brief Supported properties
 *
 * Returns an array of properties supported by this account.  This account will not be informed of changes to keys
 * it does not support.  Available keys are:
 *   @"Display Name", @"isOnline", @"Offline", @"idleSince", @"IdleManuallySet", @"User Icon"
 *   @"textProfile", @"DefaultUserIconFilename", @"accountStatus"
 * @return NSSet of supported keys
 */
- (NSSet *)supportedPropertyKeys
{
	static	NSSet	*supportedPropertyKeys = nil;
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSSet alloc] initWithObjects:
			@"isOnline",
			KEY_FORMATTED_UID,
			KEY_ACCOUNT_DISPLAY_NAME,
			@"Display Name",
			@"accountStatus",
			KEY_USE_USER_ICON, KEY_USER_ICON, KEY_DEFAULT_USER_ICON,
			@"Enabled",
			nil];
	}

	return supportedPropertyKeys;
}

/*!
 * @brief Status for key
 *
 * Returns the status this account should be for a specific key
 * @param key Property
 * @return id Status value
 */
- (id)statusForKey:(NSString *)key
{
	return [self preferenceForKey:key group:GROUP_ACCOUNT_STATUS];
}

/*!
 * @brief Update account status
 *
 * Update account status for the changed key.  This is called when account status changes Adium-side and the account
 * code should update status account/server side in response.  The new value for the key can be accessed using
 * the statusForKey method.
 * @param key The updated property
 */
- (void)updateStatusForKey:(NSString *)key
{
	[self updateCommonStatusForKey:key];
}

/*!
 * @brief Update contact status
 *
 * Adium is requesting that the account update a contact's status.  This method is primarily called by the get info
 * window.  Since this is called sparsely, accounts may choose to look up additional information such as profiles
 * in response to this.  Adium guards this method to prevent it from being called too rapidly, so expensive lookups
 * are not a problem if the delayedUpdateStatusInterval is set correctly.
 */
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	
}

/*!
 * @brief Update contact interval
 *
 * Specifies the mininum interval at which delayedUpdateContactStatus will be called.  If the account code is performing
 * expensive operations (such as profile or web lookups) in response to updateContactStatus, it can guard against
 * the lookups being performed too frequently by returning an interval here.
 */
- (float)delayedUpdateStatusInterval
{
	return 0.5f;
}

/*!
 * @brief Perform the setting of a status state
 *
 * Sets the account to a passed status state.  The account should set itself to best possible status given the return
 * values of statusState's accessors.  The passed statusMessage has been filtered; it should be used rather than
 * statusState.statusMessage, which returns an unfiltered statusMessage.
 *
 * @param statusState The state to enter
 * @param statusMessage The filtered status message to use.
 */
- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	
}

/*!
 * @brief Set the social networking status message for this account
 *
 * This will only be called if [self.service isSocialNetworkingService] returns TRUE.
 *
 * @param statusMessage The status message, which has already been filtered.
 */
- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)statusMessage
{
	
}
/*!
 * @brief Should the autorefreshing attributed string associated with a key be updated at the moment?
 *
 * The default implementation causes all dynamic strings which need updating to be updated if the account is
 * online.  Subclasses may choose to implement more complex logic; for example, a nickname seen only in a chat
 * might be updated only if a chat is open.
 */
- (BOOL)shouldUpdateAutorefreshingAttributedStringForKey:(NSString *)inKey
{
	return self.online;
}

//Messaging, Chatting, Strings -----------------------------------------------------------------------------------------
#pragma mark Messaging, Chatting, Strings
/*!
 * @brief Available for sending content
 *
 * Returns YES if the contact is available for receiving content of the specified type.  If contact is nil, instead
 * check for the availiability to send any content of the given type.
 *
 * The default implementation indicates the account, if online, can send messages to any online contact.
 * It can also send files to any online contact if the account subclass conforms to the AIAccount_Files protocol.
 *
 * @param inType A string content type
 * @param inContact The destination contact, or nil to check global availability
 */
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
	if ([inType isEqualToString:CONTENT_MESSAGE_TYPE] ||
		[inType isEqualToString:CONTENT_NOTIFICATION_TYPE]) {
		return (self.online &&
				(!inContact || inContact.online || inContact.isStranger || [self canSendOfflineMessageToContact:inContact]));
				
	} else if ([inType isEqualToString:CONTENT_FILE_TRANSFER_TYPE]) {
		return (self.online && [self conformsToProtocol:@protocol(AIAccount_Files)] &&
				(!inContact || inContact.online || inContact.isStranger));
	}

	return NO;
}

/*!
 * @brief Open a chat
 *
 * Open the passed chat account-side.  Depending on the protocol, account code may need to establish a connection in
 * response to this method or perhaps make no actions at all.  This method is used by both one-on-one chats and
 * multi-user chats.
 * @param chat The chat to open
 * @return YES on success
 */
- (BOOL)openChat:(AIChat *)chat
{
	return NO;
}

/*!
 * @brief Close a chat
 *
 * Close the passed chat account-side.  Depending on the protocol, account code may need to close a connection in
 * response to this method or perhaps make no actions at all.  This method is used by both one-on-one chats and
 * multi-user chats.
 *
 * This method should *only* be called by a core controller.  Call [adium.interfaceController closeChat:chat] to perform a close from other code.
 *
 * @param chat The chat to close
 * @return YES on success
 */
- (BOOL)closeChat:(AIChat *)chat
{
	return NO;
}

/*!
 * @brief Invite a contact to an open chat
 *
 * Invite a contact to the passed chat, if supported by the protocol and the specific chat instance.  An invite
 * message is provided as a convenience to protocols that require or support one.
 * @param contact AIListObject to invite
 * @param chat AIChat they are being invited to
 * @param inviteMessage NSString invite message for the invited contact
 * @return YES on success
 */
- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	NSLog(@"invite contact to chat with message");
	return NO;
}

/*!
 * @brief Send a typing object
 *
 * The content object contains all the necessary information for sending,
 * including the destination contact.
 */
- (void)sendTypingObject:(AIContentTyping *)inTypingObject
{

}

/*!
 * @brief Send a message
 *
 * The content object contains all the necessary information for sending,
 * including the destination contact. [inMessageObject encodedMessage] contains the NSString which should be sent.
 */
- (BOOL)sendMessageObject:(AIContentMessage *)inMessageObject
{
	return NO;
}

/*!
 * @brief Does the account support sending notifications?
 */
- (BOOL)supportsSendingNotifications
{
	return NO;
}

/*!
 * @brief Send a notification
 */
- (BOOL)sendNotificationObject:(AIContentNotification *)inContentNotification
{
	return NO;
}

/*!
 * @brief Encode attributed string (generic)
 *
 * Encode an NSAttributedString into a NSString for this account.  Accounts that support formatted text or require
 * special encoding on strings should do that work here.  For example, HTML based accounts should convert the 
 * NSAttributedString to HTML appropriate for their protocol (Adium can help with this).
 * @param inAttributedString String to encode
 * @param inListObject List object associated with the string; nil if the string is not associated with a particular list object, which is the case if encoding for a status message or a group chat message.
 * @return NSString result from encoding
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return [inAttributedString string];
}

/*!
 * @brief Encode attributed string to send as a message
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
    return [self encodedAttributedString:inContentMessage.message forListObject:[inContentMessage destination]];
}

/*!
 * @brief Should an autoreply be sent to this message?
 *
 * This will only be called if the generic algorithm determines that an autoreply is appropriate. The account
 * gets an opportunity to suppress sending the autoreply, e.g. on the basis of the message's content or source.
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return YES;
}

/*!
 * @brief Hide outgoing messages (ex: because the server will echo them back to us)
 */
- (BOOL)shouldDisplayOutgoingMUCMessages
{
	return YES;
}

//Presence Tracking ----------------------------------------------------------------------------------------------------
#pragma mark Presence Tracking
/*!
 * @brief Contact list editable?
 *
 * Editable means contacts can be added or removed.  Contacts should always be able to be moved between groups.
 * The account may have to implement its own grouping store if a serverside store does not exist.
 *
 * @return YES if the contact list is currently editable
 */
- (BOOL)contactListEditable
{
	return NO;
}

/*!
 * @brief Add contacts
 *
 * Add contacts to a group on this account.  Create the group if it doesn't already exist.
 * @param objects NSArray of AIListContact objects to add
 * @param group AIListGroup destination for contacts
 */
- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
	//XXX - Our behavior for duplicate contacts isn't specified here.  Should we handle that adium-side automatically? -ai
}

/*!
 * @brief Remove contacts
 *
 * Remove contacts from this account.
 * @param objects NSArray of AIListContact objects to remove
 * @param groups NSArray of AIListGroup objects to remove from.
 */
- (void)removeContacts:(NSArray *)objects fromGroups:(NSArray *)groups
{
	
}

/*!
 * @brief Remove a group
 *
 * Remove a group from this account.
 * @param group AIListGroup to remove
 */
- (void)deleteGroup:(AIListGroup *)group
{
	//XXX - Adium's current behavior is to delete all the contacts within a group, and then delete the group.  This is innefficient on protocols which support deleting groups. -ai
}

/*!
 * @brief Move contacts
 *
 * Move existing contacts to a specific group on this account.  The passed contacts should already exist somewhere on
 * this account.
 * @param objects NSArray of AIListContact objects to remove
 * @param oldGroups NSSet of AIListGroup source for contacts
 * @param group NSSet of AIListGroup destination for contacts
 */
- (void)moveListObjects:(NSArray *)objects fromGroups:(NSSet *)oldGroups toGroups:(NSSet *)groups
{
	NSAssert(NO, @"Should not be reached");
}

/*!
 * @brief Rename a group
 *
 * Rename a group on this account.
 * @param group AIListGroup to rename
 * @param newName NSString name for the group
 */
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName
{
	NSAssert(NO, @"Should not be reached");
}

/*!
 * @brief Menu items for contact
 *
 * Returns an array of menu items for a contact on this account.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.
 * @param inContact AIListContact for menu items
 * @return NSArray of NSMenuItem instances for the passed contact
 */
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	return nil;
}

/*!
 * @brief Menu items for chat
 *
 * Returns an array of menu items for a chat on this account.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.
 * @param inChat AIChat for menu items
 * @return NSArray of NSMenuItem instances for the passed contact
 */
- (NSArray *)menuItemsForChat:(AIChat *)inChat
{
	return nil;
}

/*!
 * @brief Menu items for the account's actions
 *
 * Returns an array of menu items for account-specific actions.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.  It will only be queried if the account is online.
 * @return NSArray of NSMenuItem instances for this account
 */
- (NSArray *)accountActionMenuItems
{
	return nil;
}

/*!
 * @brief The account menu item was updated
 *
 * This method allows the opportunity to update the account menu item, e.g. to add information to it
 */
- (void)accountMenuDidUpdate:(NSMenuItem*)menuItem
{

}

/*!
 * @brief Is a contact on the contact list intentionally listed?
 *
 * By default, it is assumed that any contact on the list is intended be there.
 * This is used by AIListContact to determine if the prescence of itself on the list is indicative of a degree
 * of trust, for preferences such as "automatically accept files from contacts on my contact list".
 */
- (BOOL)isContactIntentionallyListed:(AIListContact *)contact
{
	return YES;
}

/*!
 * @brief Return the data for the serverside icon for a contact
 */
- (NSData *)serversideIconDataForContact:(AIListContact *)contact
{
	return nil;
}

#pragma mark Secure messsaging

/*!
 * @brief Allow secure messaging toggling on a chat?
 *
 * Returns YES if secure (encrypted) messaging's status for this chat should be able to be changed.
 * This allows the account to determine on a per-chat basis whether the chat's initial security setting should be permanently
 * maintained.  If it returns NO, the user can not request for the chat to become encrypted or unencrypted.
 * This is currently implemented by Gaim accounts to return YES for one-on-one chats and NO for group chats to indicate
 * the functionality provided by Off-the-Record Messaging (OTR).
 *
 * @param inChat The query chat 
 * @result Should the state of secure messaging be allowed to change?
 */
- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	//Allow secure messaging via OTR for one-on-one chats
	return !inChat.isGroupChat;
}

/*!
 * @brief Provide a localized description of the encryption this account provides
 *
 * Returns a localized string which describes the encryption this account supports.
 *
 * @result An <tt>NSString</tt> describing the encryption offerred by this account, if any.
 */
- (NSString *)aboutEncryption
{
	return [NSString stringWithFormat:
		AILocalizedStringFromTableInBundle(@"Adium provides encryption, authentication, deniability, and perfect forward secrecy over %@ via Off-the-Record Messaging (OTR). If your contact is not using an OTR-compatible messaging system, your contact will be sent a link to the OTR web site when you attempt to connect. For more information on OTR, visit https://otr.cypherpunks.ca/.", nil, [NSBundle bundleForClass:[AIAccount class]], nil),
		[self.service shortDescription]];
}

/*!
 * @brief Start or stop secure messaging in a chat
 *
 * @param inSecureMessaging The desired state of the chat in terms of encryption
 * @param inChat The chat to change
 */
- (void)requestSecureMessaging:(BOOL)inSecureMessaging
						inChat:(AIChat *)inChat
{
	[adium.contentController requestSecureOTRMessaging:inSecureMessaging
												  inChat:inChat];
}

#pragma mark Image sending
/*!
 * @brief Can the account send images inline within a chat?
 */
- (BOOL)canSendImagesForChat:(AIChat *)inChat
{
	return NO;
}

#pragma mark Authorization
/*!
 * @brief An authorization prompt closed, granting or denying a contact's request for authorization
 *
 * @param inDict A dictionary of authorization information created by the account originally and unmodified
 * @param authorizationResponse An AIAuthorizationResponse indicating if authorization was granted or denied or if there was no response
 */
- (void)authorizationWithDict:(NSDictionary *)infoDict response:(AIAuthorizationResponse)authorizationResponse;
{}

#pragma mark Group Chats
/*!
 * @brief Should the chat autocomplete the UID instead of the Display Name?
 */
- (BOOL)chatShouldAutocompleteUID:(AIChat *)inChat
{
	return NO;
}

/*!
 * @brief Suffix for autocompleted contacts
 */
- (NSString *)suffixForAutocomplete:(AIChat *)inChat forPartialWordRange:(NSRange)charRange
{
	NSString *suffix = nil;
	if (charRange.location == 0)
	{
		suffix = @": ";
	}
	return suffix;
}

/*!
 * @brief Prefix for autocompleted contacts
 */
- (NSString *)prefixForAutocomplete:(AIChat *)inChat forPartialWordRange:(NSRange)charRange
{
	return nil;
}


-(NSMenu*)actionMenuForChat:(AIChat*)chat
{
	return nil;
}

/*!
 * @brief Does the account manage group chat ignoring?
 *
 * If it doesn't, the AIChat will handle ignoring itself.
 */
- (BOOL)accountManagesGroupChatIgnore
{
	return NO;
}

/*!
 * @brief Return if a contact is ignored
 *
 * @param inContact The AIListContact
 * @param chat The AIChat the inContact is a member of.
 *
 * @return YES if ignored, NO otherwise.
 */
- (BOOL)contact:(AIListContact *)inContact isIgnoredInChat:(AIChat *)chat
{
	return NO;
}

/*!
 * @brief Ignore a contact
 *
 * @param inContact The AIListContact
 * @param inIgnored YES if the contact should be ignored, NO otherwise.
 * @param chat The AIChat the inContact is a member of.
 */
- (void)setContact:(AIListContact *)inContact ignored:(BOOL)inIgnored inChat:(AIChat *)chat
{
	
}

#pragma mark Logging
- (BOOL)shouldLogChat:(AIChat *)chat
{
	BOOL shouldLog = ![self isTemporary];
	
	if (shouldLog) {
		shouldLog = [[adium.preferenceController preferenceForKey:KEY_LOGGER_ENABLE group:PREF_GROUP_LOGGING] boolValue];
	}
	
	if(shouldLog && [[adium.preferenceController preferenceForKey:KEY_LOGGER_CERTAIN_ACCOUNTS group:PREF_GROUP_LOGGING] boolValue]) {
		shouldLog = ![[self preferenceForKey:KEY_LOGGER_OBJECT_DISABLE
									   group:PREF_GROUP_LOGGING] boolValue];
	}
	
	return shouldLog;
}

#pragma mark AppleScript
- (NSNumber *)scriptingInternalObjectID
{
	return [NSNumber numberWithInt:[self.internalObjectID intValue]];
}

/**
 * @brief The standard objectSpecifier for this model object.
 *
 * AIAccount is contained by AIService, using the 'accounts' key.
 * Each instance has a unique integer identifier.
 */
- (NSScriptObjectSpecifier *)objectSpecifier
{
	//get my service
	AIService *theService = self.service;
	NSScriptObjectSpecifier *containerRef = [theService objectSpecifier];

	return [[[NSUniqueIDSpecifier alloc]
			 initWithContainerClassDescription:[containerRef keyClassDescription]
			 containerSpecifier:containerRef key:@"accounts"
			 uniqueID:[self scriptingInternalObjectID]] autorelease];
}

/**
 * @brief Returns the UID of this account.
 */
- (NSString *)scriptingUID
{
	return self.UID;
}

/**
 * @brief Ensures that it's impossible to set the UID of an account.
 *
 * This makes sense for the services I'm familiar with, like AIM and GTalk. It may not make sense for other protocols.
 * However, it still doesn't seem necessary to do from code.
 */
- (void)setScriptingUID:(NSString *)n
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't dynamically change the UID of this account."];
}

/**
 * @brief Make a contact, according to the passed dictionary of AppleScript properties
 * 
 * @param properties A dictionary of the following keys:
 *		@"KeyDictionary" is the list of the properties in the "with properties" clause of the AS make command.
 *			@"UID" key of KeyDictionary is the required "name" property of contacts
 *			@"parentGroup" key of keyDictionary is the optional "contact group" property of contacts.
 *						   If the parentGroup is not specified, the contact will not be added to the contact list.
 */
- (id)makeContactWithProperties:(NSDictionary *)properties
{
	NSDictionary *keyDictionary = [properties objectForKey:@"KeyDictionary"];
	if (!keyDictionary) {
		[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
		[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a contact without specifying contact properties."];
		return nil;
	}
	NSString *contactUID = [keyDictionary objectForKey:@"UID"];
	if (!contactUID) {
		[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
		[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a contact without specifying the contact name."];
		return nil;
	}
	AIListContact *newContact = [adium.contactController contactWithService:self.service account:self UID:contactUID];
	NSScriptObjectSpecifier *groupSpecifier = [keyDictionary objectForKey:@"parentGroup"];
	AIListGroup *group = [groupSpecifier objectsByEvaluatingSpecifier];
	//If we have a group, we add this contact to the contact list.
	if (groupSpecifier && group) {
		[self addContact:newContact toGroup:group];
	}
	
	return newContact;
}
- (void)insertObject:(AIListObject *)contact inContactsAtIndex:(int)idx
{
	//Intentially unimplemented. This should never be called (contacts are created a different way), but is required for KVC-compliance.
}
- (void)removeObjectFromContactsAtIndex:(NSInteger)idx
{
	AIListObject *object = [self.contacts objectAtIndex:idx];
	
	for (AIListGroup *group in object.groups) {
		[object removeFromGroup:group];
	}
}

/**
 * @brief Creates a chat according to the given properties.
 * @param resolvedKeyDictionary The dictionary of arguments to the 'make' command.
 *
 * This uses my own custom make<Key>WithProperties KVC method. :)
 * The idea is that be default Cocoa-AS will try to make an object using the standard alloc/init routines
 * However, you may not want that to be the case. If an AS model object implements this method, then when its the 
 * target of a 'make' command, it will be called. The method should return a new object, already assigned to a
 * container, as AICreateCommand will not do that for you.
 */
- (id)makeChatWithProperties:(NSDictionary *)resolvedKeyDictionary
{
	AILogWithSignature(@"%@", resolvedKeyDictionary);
	NSArray *participants = [resolvedKeyDictionary objectForKey:@"withContacts"];
	if (!participants) {
		[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
		[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a chat without a contact!"];
		return nil;
	}
	if (![resolvedKeyDictionary objectForKey:@"newChatWindow"] && ![resolvedKeyDictionary objectForKey:@"Location"] 
	    && ![resolvedKeyDictionary objectForKey:@"inWindow"]) {
		[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
		[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a chat without specifying its containing window."];
		return nil;
	}
	
	if ([participants count] == 1) {
		AIListContact *contact = [[participants objectAtIndex:0] objectsByEvaluatingSpecifier];
		if (!contact) {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't find that contact!"];
			return nil;
		}
		AIMessageWindowController *chatWindowController = nil;
		NSInteger index = -1; //at end by default
		if ([resolvedKeyDictionary objectForKey:@"newChatWindow"]) {
			//I need to put this in a new chat window
			chatWindowController = [adium.interfaceController openContainerWithID:nil name:nil];
		} else if ([resolvedKeyDictionary objectForKey:@"inWindow"]) {
			AIMessageWindow *chatWindow = [resolvedKeyDictionary objectForKey:@"inWindow"];
            index = [[chatWindow chats] count];
			chatWindowController = (AIMessageWindowController *)[chatWindow windowController];
		} else {
			//I need to figure out to which chat window the location specifier is referring.			
			NSPositionalSpecifier *location = [resolvedKeyDictionary objectForKey:@"Location"];
			AIMessageWindow *chatWindow = [location insertionContainer];
            index = [location insertionIndex];
			chatWindowController = (AIMessageWindowController *)[chatWindow windowController];
		}
		
		if (!chatWindowController) {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create chat in that chat window."];
			return nil;
		}
		
		AIChat *newChat = [adium.chatController chatWithContact:contact];
		[adium.interfaceController openChat:newChat inContainerWithID:[chatWindowController containerID] atIndex:index];
		return newChat;
	} else {
		if (![self.service canCreateGroupChats]) {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a group chat with this service!"];
			return nil;
		}
		NSString *name = [resolvedKeyDictionary objectForKey:@"name"];
		if (!name) {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create a group chat without a name!"];
			return nil;
		}
		//this can take a while...
		NSMutableArray *newParticipants = [[[NSMutableArray alloc] init] autorelease];
		for (int i=0;i<[participants count];i++) {
			[newParticipants addObject:[[participants objectAtIndex:i] objectsByEvaluatingSpecifier]];
		}
		
		DCJoinChatViewController *chatController = [DCJoinChatViewController joinChatView];
		[chatController doJoinChatWithName:name onAccount:self chatCreationInfo:nil invitingContacts:newParticipants withInvitationMessage:@"Hey, wanna join my chat?"];
		return [adium.chatController existingChatWithName:name onAccount:self];
	}
}

/**
 * @brief Returns the current status type of this account.
 */
- (AIStatusTypeApplescript)scriptingStatusType
{
	return [self.statusState statusTypeApplescript];
}

/**
 * @brief Sets the type of the current status.
 *
 * If the current status is a temporary status, then we simply set it.
 * Otherwise, we create a temporary copy of it, and set that.
 */
- (void)setScriptingStatusType:(AIStatusTypeApplescript)scriptingType
{
	AIStatusType type;
	switch (scriptingType) {
		case AIAvailableStatusTypeAS:
			type = AIAvailableStatusType;
			break;
		case AIAwayStatusTypeAS:
			type = AIAwayStatusType;
			break;
		case AIInvisibleStatusTypeAS:
			type = AIInvisibleStatusType;
			break;
		case AIOfflineStatusTypeAS:
		default:
			type = AIOfflineStatusType;
			break;
	}
	
	AIStatus *currentStatus = self.statusState;
	if ([currentStatus mutabilityType] == AILockedStatusState || [currentStatus mutabilityType] == AISecondaryLockedStatusState) {
		switch (type) {
			case AIAvailableStatusType:
				currentStatus = [adium.statusController availableStatus];
				break;
			case AIAwayStatusType:
				currentStatus = [adium.statusController awayStatus];
				break;
			case AIInvisibleStatusType:
				currentStatus = [adium.statusController invisibleStatus];
				break;
			case AIOfflineStatusType:
				currentStatus = [adium.statusController offlineStatus];
				break;
		}
	} else {
		if ([currentStatus mutabilityType] != AITemporaryEditableStatusState) {
			currentStatus = [[currentStatus mutableCopy] autorelease];
			[currentStatus setMutabilityType:AITemporaryEditableStatusState];
		}
		[currentStatus setStatusType:type];
		[currentStatus setStatusName:[adium.statusController defaultStatusNameForType:type]];
	}
	[adium.statusController setActiveStatusState:currentStatus forAccount:self];
}

/**
 * @brief Returns a mutable status
 *
 * If the current status is built in, we create a temporary copy of the current status and set that.
 *
 * @return An AIStatus fit for being modified.
 */
- (AIStatus *)modifiableCurrentStatus
{
	AIStatus *currentStatus = self.statusState;
	
	if ([currentStatus mutabilityType] != AITemporaryEditableStatusState) {
		currentStatus = [[currentStatus mutableCopy] autorelease];
		[currentStatus setMutabilityType:AITemporaryEditableStatusState];
	}	
	
	return currentStatus;
}

/**
 * @brief Sets the status message
 *
 * @param message, which may be an NSAttributedString or NSString
 */
- (void)setScriptingStatusMessageWithAttributedString:(id)message
{
	AIStatus *currentStatus = [self modifiableCurrentStatus];
	
	if ([message isKindOfClass:[NSAttributedString class]])
		[currentStatus setStatusMessage:(NSAttributedString *)message];
	else
		[currentStatus setStatusMessageString:message];
	
	[adium.statusController setActiveStatusState:currentStatus forAccount:self];
}

- (void)setScriptingStatusMessage:(NSString *)message
{
  [self setScriptingStatusMessageWithAttributedString:message];
}

/**
 * @brief Sets the status message to a NSAttributedString extracted of a NSScriptCommand
 */
- (void)setScriptingStatusMessageFromScriptCommand:(NSScriptCommand *)c
{
	//messageString could also be an NSTextStorage, due to WithMessage being able to also accept rich text
	NSString *messageString = [[c evaluatedArguments] objectForKey:@"WithMessage"];
	if (messageString)
		[self setScriptingStatusMessageWithAttributedString:messageString];	
}

/**
 * @brief Tells this account to be available, with an optional temporary status message.
 */
- (void)scriptingGoAvailable:(NSScriptCommand *)c
{
	[adium.statusController setActiveStatusState:[adium.statusController availableStatus] forAccount:self];
	
	[self setScriptingStatusMessageFromScriptCommand:c];
}

/**
 * @brief Tells this account to be online, with an optional temporary status message.
 */
- (void)scriptingGoOnline:(NSScriptCommand *)c
{
	if (self.statusType == AIInvisibleStatusType) {
		[self scriptingGoAvailable:c];

	} else {		
		[self setShouldBeOnline:YES];
		
		[self setScriptingStatusMessageFromScriptCommand:c];
	}
}

/**
 * @brief Tells this account to be offline, with an optional temporary status message.
 */
- (void)scriptingGoOffline:(NSScriptCommand *)c
{
	[self setShouldBeOnline:NO];

	[self setScriptingStatusMessageFromScriptCommand:c];
}

/**
 * @brief Tells this account to be away, with an optional temporary status message.
 */
- (void)scriptingGoAway:(NSScriptCommand *)c
{
	[adium.statusController setActiveStatusState:[adium.statusController awayStatus] forAccount:self];

	[self setScriptingStatusMessageFromScriptCommand:c];
}

/**
 * @brief Tells this account to be invisible.
 */
- (void)scriptingGoInvisible:(NSScriptCommand *)c
{
	[adium.statusController setActiveStatusState:[adium.statusController invisibleStatus] forAccount:self];
	
	[self setScriptingStatusMessageFromScriptCommand:c];
}

/**
 * @brief True, if a proxy is enabled
 */
- (BOOL)proxyEnabled
{
	return [[self preferenceForKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS] boolValue];
}
/**
 * @brief Sets whether or not the proxy is enabled for this account.
 * This does not change the proxy setting immediately, a disconnect and reconnect is still required.
 */
- (void)setProxyEnabled:(BOOL)proxyEnabled
{
	[self setPreference:[NSNumber numberWithBool:proxyEnabled] forKey:KEY_ACCOUNT_PROXY_ENABLED group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Gets the type of the proxy (one of the defined AdiumProxyTypes)
 */
- (AdiumProxyType)proxyType
{
	return [[self preferenceForKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS] intValue];
}
/**
 * @brief Sets the proxy type (one of the defined AdiumProxyTypes)
 */
- (void)setProxyType:(AdiumProxyType)type
{
	[self setPreference:[NSNumber numberWithInt:type] forKey:KEY_ACCOUNT_PROXY_TYPE group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Gets the proxy host as a string
 */
- (NSString *)proxyHost
{
	return [self preferenceForKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Sets the proxy host
 */
- (void)setProxyHost:(NSString *)host
{
	[self setPreference:host forKey:KEY_ACCOUNT_PROXY_HOST group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Gets the proxy's port
 */
- (NSNumber *)proxyPort
{
	NSString *proxyPort = [self preferenceForKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
	return [NSNumber numberWithUnsignedShort:[proxyPort integerValue]];
}
/**
 * @brief Set the port to which we should connect when connecting to the proxy
 */
- (void)setProxyPort:(NSNumber *)port
{
	[self setPreference:[port stringValue] forKey:KEY_ACCOUNT_PROXY_PORT group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Gets the username we use when connecting to the proxy
 */
- (NSString *)proxyUsername
{
	return [self preferenceForKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Sets the username we should use when connecting to the proxy
 */
- (void)setProxyUsername:(NSString *)username
{
	[self setPreference:username forKey:KEY_ACCOUNT_PROXY_USERNAME group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Gets the password we use when connecting to the proxy
 */
- (NSString *)proxyPassword
{
	return [self preferenceForKey:KEY_ACCOUNT_PROXY_PASSWORD group:GROUP_ACCOUNT_STATUS];
}
/**
 * @brief Sets the password we should use when connecting to the proxy
 */
- (void)setProxyPassword:(NSString *)proxyPassword
{
	[self setPreference:proxyPassword forKey:KEY_ACCOUNT_PROXY_PASSWORD group:GROUP_ACCOUNT_STATUS];
}

/**
 * @brief Gets the proxy type for applescript (using the nice four-letter codes defined by AdiumProxyTypeApplescript)
 */
- (AdiumProxyTypeApplescript)scriptingProxyType
{
	return [self applescriptProxyType:[self proxyType]];
}
/**
 * @brief Sets the proxy type to one of the defined AdiumProxyTypeApplescripts
 */
- (void)setScriptingProxyType:(AdiumProxyTypeApplescript)type
{
	[self setProxyType:[self proxyTypeFromApplescript:type]];
}

@end

@implementation AIAccount(AppleScriptPRIVATE)
- (AdiumProxyType)proxyTypeFromApplescript:(AdiumProxyTypeApplescript)proxyTypeAS
{
	switch(proxyTypeAS)
	{
		case Adium_Proxy_HTTP_AS:
			return Adium_Proxy_HTTP;
		case Adium_Proxy_SOCKS4_AS:
			return Adium_Proxy_SOCKS4;
		case Adium_Proxy_SOCKS5_AS:
			return Adium_Proxy_SOCKS5;
		case Adium_Proxy_Default_HTTP_AS:
			return Adium_Proxy_Default_HTTP;
		case Adium_Proxy_Default_SOCKS4_AS:
			return Adium_Proxy_Default_SOCKS4;
		case Adium_Proxy_Default_SOCKS5_AS:
			return Adium_Proxy_Default_SOCKS5;
        case Adium_Proxy_Tor_AS:
            return Adium_Proxy_Tor;
		default:
			return Adium_Proxy_None;
	}
}
- (AdiumProxyTypeApplescript)applescriptProxyType:(AdiumProxyType)proxyType
{
	switch(proxyType)
	{
		case Adium_Proxy_HTTP:
			return Adium_Proxy_HTTP_AS;
		case Adium_Proxy_SOCKS4:
			return Adium_Proxy_SOCKS4_AS;
		case Adium_Proxy_SOCKS5:
			return Adium_Proxy_SOCKS5_AS;
		case Adium_Proxy_Default_HTTP:
			return Adium_Proxy_Default_HTTP_AS;
		case Adium_Proxy_Default_SOCKS4:
			return Adium_Proxy_Default_SOCKS4_AS;
		case Adium_Proxy_Default_SOCKS5:
			return Adium_Proxy_Default_SOCKS5_AS;
        case Adium_Proxy_Tor:
            return Adium_Proxy_Tor_AS;
		default:
			return Adium_Proxy_None_AS;
	}
}

@end
