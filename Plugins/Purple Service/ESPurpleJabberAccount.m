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

#import "ESPurpleJabberAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#include <libpurple/presence.h>
#include <libpurple/si.h>
#include <SystemConfiguration/SystemConfiguration.h>
#import "AMXMLConsoleController.h"
#import "AMPurpleJabberServiceDiscoveryBrowsing.h"
#import "ESPurpleJabberAccountViewController.h"
#import "AMPurpleJabberAdHocServer.h"
#import "AMPurpleJabberAdHocPing.h"

#ifdef HAVE_CDSA
#import "AIPurpleCertificateViewer.h"
#endif

#define DEFAULT_JABBER_HOST @"@jabber.org"

@interface ESPurpleJabberAccount ()
- (BOOL)enableXMLConsole;
@end

@implementation ESPurpleJabberAccount

/*!
 * @brief The UID will be changed. The account has a chance to perform modifications
 *
 * Upgrade old Jabber accounts stored with the host in a separate key to have the right UID, in the form
 * name@server.org
 *
 * Append @jabber.org to a proposed UID which has no domain name and does not need to be updated.
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	proposedUID = [proposedUID lowercaseString];
	NSString	*correctUID;
	
	if ((proposedUID && ([proposedUID length] > 0)) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)) {
		
		NSString	*host;
		//Upgrade code: grab a previously specified Jabber host
		if ((host = [self preferenceForKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS ignoreInheritedValues:YES])) {
			//Determine our new, full UID
			correctUID = [NSString stringWithFormat:@"%@@%@",proposedUID, host];

			//Clear the preference and then set the UID so we don't perform this upgrade again
			[self setPreference:nil forKey:@"Jabber:Host" group:GROUP_ACCOUNT_STATUS];
			[self setPreference:correctUID forKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];

		} else {
			//Append [self serverSuffix] (e.g. @jabber.org) to a Jabber account with no server
			correctUID = [proposedUID stringByAppendingString:[self serverSuffix]];
		}
	} else {
		correctUID = proposedUID;
	}

	return correctUID;
}

- (const char*)protocolPlugin
{
   return "prpl-jabber";
}

- (void)dealloc
{
	[xmlConsoleController close];
	[xmlConsoleController release];

	[super dealloc];
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	NSString	*connectServer;
	BOOL		forceOldSSL, allowPlaintext, requireTLS;

	purple_account_set_username(account, self.purpleAccountName);

	//'Connect via' server (nil by default)
	connectServer = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	//XXX - As of libpurple 2.0.0, 'localhost' doesn't work properly by 127.0.0.1 does. Hack!
	if (connectServer && [connectServer isEqualToString:@"localhost"])
		connectServer = @"127.0.0.1";
	
	purple_account_set_string(account, "connect_server", (connectServer ?
														[connectServer UTF8String] :
														""));
	
	//Force old SSL usage? (off by default)
	forceOldSSL = [[self preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "old_ssl", forceOldSSL);

	//Require SSL or TLS? (off by default)
	requireTLS = [[self preferenceForKey:KEY_JABBER_REQUIRE_TLS group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "require_tls", requireTLS);

	//Allow plaintext authorization over an unencrypted connection? Purple will prompt if this is NO and is needed.
	allowPlaintext = [[self preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "auth_plain_in_clear", allowPlaintext);
	
	/* Mac OS X 10.4's cyrus-sasl's PLAIN mech gives us problems.  Is it a bug in the installed library, a bug in its compilation, or a bug
	 * in our linkage against it? I don't know. The result is that the username gets included twice before the base64 encoding is performed.
	 *
	 * Furthermore, on any version, using the cyrus-sasl PLAIN mech prevents us from following Google Talk best practices for handling of domain names.
	 * This is because we can't add to the <auth> response's attributes:
	 *		xmlns:ga='http://www.google.com/talk/protocol/auth' ga:client-uses-full-bind-result='true'
	 * as per http://code.google.com/apis/talk/jep_extensions/jid_domain_change.html and therefore we won't automatically resolve changing an
	 * "@gmail.com" to "@googlemail.com" or some other domain name.
	 *
	 * We therefore use the PLAIN implementation in libpurple itself. Libpurple's own DIGEST-MD5 is always used for compatibility with old OpenFire
	 * servers.
	 *
	 * This preference and the changes for it are added via the "libpurple_jabber_avoid_sasl_option_hack.diff" patch we apply during the build process.
	 */
	purple_prefs_set_bool("/plugins/prpl/jabber/avoid_sasl_for_plain_auth", YES);
}

- (NSString *)serverSuffix
{
	NSString *host = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	
	return (host ? host : DEFAULT_JABBER_HOST);
}

/*!	@brief	Obtain the resource name for this Jabber account.
 *
 *	This could be extended in the future to perform keyword substitution (e.g. s/%computerName%/CSCopyMachineName()/).
 *
 *	@return	The resource name for the account.
 */
- (NSString *)resourceName
{
    NSString *resource = [self preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
    
    if(resource == nil || [resource length] == 0)
        resource = [(NSString*)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
    
	return resource;
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	/*
	 * Purple stores the username in the format username@server/resource.  We need to pass it a username in this format
	 *
	 * The user should put the username in username@server format, which is common for Jabber. If the user does
	 * not specify the server, use jabber.org.
	 */
	
	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self serverSuffix]];
	}

	completeUserName = [NSString stringWithFormat:@"%@/%@" ,userNameWithHost, [self resourceName]];

	return [completeUserName UTF8String];
}

/*!
 * @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Rather than having a separate server field, Jabber uses the servername after the user name.
 * username@server.org
 *
 * The connect server, stored in KEY_JABBER_CONNECT_SERVER, overrides this to provide the connect host. It will
 * not be set in most cases.
 */
- (NSString *)host
{
	NSString	*host;
	
	if (!(host = [self preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS])) {
		NSUInteger location = [UID rangeOfString:@"@"].location;

		if ((location != NSNotFound) && (location + 1 < [UID length])) {
			host = [UID substringFromIndex:(location + 1)];

		} else {
			host = [self serverSuffix];
		}
	}
	
	return host;
}

/*!
 * @brief Should set aliases serverside?
 *
 * Jabber supports serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}

- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	contact = [adium.contactController existingContactWithService:service
															account:self
																UID:sourceUID];
	if (!contact) {		
		contact = [adium.contactController contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return contact;
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;

	if ([contactUID hasSuffix:@"@gmail.com"] ||
		[contactUID hasSuffix:@"@googlemail.com"]) {
		contactServiceID = @"libpurple-jabber-gtalk";

	} else if([contactUID hasSuffix:@"@livejournal.com"]){
		contactServiceID = @"libpurple-jabber-livejournal";
		
	} else {
		contactServiceID = @"libpurple-Jabber";
	}

	contactService = [adium.accountController serviceWithUniqueID:contactServiceID];
	
	return contactService;
}

- (id)authorizationRequestWithDict:(NSDictionary*)dict {
	switch ([[self preferenceForKey:KEY_JABBER_SUBSCRIPTION_BEHAVIOR group:GROUP_ACCOUNT_STATUS] intValue]) {
		case 2: // always accept + add
			// add
			{
				NSString *groupname = [self preferenceForKey:KEY_JABBER_SUBSCRIPTION_GROUP group:GROUP_ACCOUNT_STATUS];
				if ([groupname length] > 0) {
					AIListContact *contact = [adium.contactController contactWithService:self.service account:self UID:[dict objectForKey:@"Remote Name"]];
					AIListGroup *group = [adium.contactController groupWithUID:groupname];
					[contact.account addContact:contact toGroup:group];
				}
			}
			// fallthrough
		case 1: // always accept
			[[self purpleAdapter] doAuthRequestCbValue:[[[dict objectForKey:@"authorizeCB"] retain] autorelease] withUserDataValue:[[[dict objectForKey:@"userData"] retain] autorelease]];
			break;
		case 3: // always deny
			[[self purpleAdapter] doAuthRequestCbValue:[[[dict objectForKey:@"denyCB"] retain] autorelease] withUserDataValue:[[[dict objectForKey:@"userData"] retain] autorelease]];
			break;
		default: // ask (should be 0)
			return [super authorizationRequestWithDict:dict];
	}

	return NULL;
}

- (void)purpleAccountRegistered:(BOOL)success
{
	if(success && [self.service accountViewController]) {
		const char *usernamestr = purple_account_get_username(account);
		NSString *username;
		if (usernamestr) {
			NSString *userWithResource = [NSString stringWithUTF8String:usernamestr];
			NSRange slashrange = [userWithResource rangeOfString:@"/"];
			if(slashrange.location != NSNotFound)
				username = [userWithResource substringToIndex:slashrange.location];
			else
				username = userWithResource;
		} else
			username = (id)[NSNull null];

		NSString *pw = (purple_account_get_password(account) ? [NSString stringWithUTF8String:purple_account_get_password(account)] : [NSNull null]);
		
		[adium.notificationCenter postNotificationName:AIAccountUsernameAndPasswordRegisteredNotification
												  object:self
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													username, @"username",
													pw, @"password",
													nil]];
	}
}

#pragma mark Contacts
- (void)updateSignon:(AIListContact *)theContact withData:(void *)data
{
	[super updateSignon:theContact withData:data];
	
	//We only get user icons in Jabber when we request info. Do that now!
	[self delayedUpdateContactStatus:theContact];
}

#pragma mark Status

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	static AIHTMLDecoder *jabberHtmlEncoder = nil;
	if (!jabberHtmlEncoder) {
		jabberHtmlEncoder = [[AIHTMLDecoder alloc] init];
		[jabberHtmlEncoder setIncludesHeaders:NO];
		[jabberHtmlEncoder setIncludesFontTags:YES];
		[jabberHtmlEncoder setClosesFontTags:YES];
		[jabberHtmlEncoder setIncludesStyleTags:YES];
		[jabberHtmlEncoder setIncludesColorTags:YES];
		[jabberHtmlEncoder setEncodesNonASCII:NO];
		[jabberHtmlEncoder setPreservesAllSpaces:NO];
		[jabberHtmlEncoder setUsesAttachmentTextEquivalents:YES];
	}
	
	return [jabberHtmlEncoder encodeHTML:inAttributedString imagesPath:nil];
}

- (NSString *)_UIDForAddingObject:(AIListContact *)object
{
	NSString	*objectUID = [object UID];
	NSString	*properUID;
	
	if ([objectUID rangeOfString:@"@"].location != NSNotFound) {
		properUID = objectUID;
	} else {
		properUID = [NSString stringWithFormat:@"%@@%@",objectUID,self.host];
	}
	
	return [properUID lowercaseString];
}

- (NSString *)unknownGroupName {
    return (AILocalizedString(@"Roster","Roster - the Jabber default group"));
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step) {
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data",nil);
			break;			
		case 3:
			return AILocalizedString(@"Authenticating",nil);
			break;
		case 5:
			return AILocalizedString(@"Initializing Stream",nil);
			break;
		case 6:
			return AILocalizedString(@"Authenticating",nil);
			break;
	}
	return nil;
}

- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError
{
	AIReconnectDelayType shouldAttemptReconnect = [super shouldAttemptReconnectAfterDisconnectionError:disconnectionError];

	if (([self lastDisconnectionReason] == PURPLE_CONNECTION_ERROR_CERT_OTHER_ERROR) &&
		([self shouldVerifyCertificates])) {
		shouldAttemptReconnect = AIReconnectNever;
	} else if (!finishedConnectProcess && ![password length] &&
			   (disconnectionError &&
			   ([*disconnectionError isEqualToString:[NSString stringWithUTF8String:_("Read Error")]] ||
				[*disconnectionError isEqualToString:[NSString stringWithUTF8String:_("Service Unavailable")]] ||
				[*disconnectionError isEqualToString:[NSString stringWithUTF8String:_("Forbidden")]]))) {
		//No password specified + above error while we're connecting = behavior of various broken servers. Prompt for a password.
		[self serverReportedInvalidPassword];
		shouldAttemptReconnect = AIReconnectImmediately;
	}
 
	return shouldAttemptReconnect;
}

- (void)disconnectFromDroppedNetworkConnection
{
	/* Before we disconnect from a dropped network connection, set gc->disconnect_timeout to a non-0 value.
	 * This will let the prpl know that we are disconnecting with no backing ssl connection and that therefore
	 * the ssl connection is has should not be messaged in the process of disconnecting.
	 */
	PurpleConnection *gc = purple_account_get_connection(account);
	if (PURPLE_CONNECTION_IS_VALID(gc) &&
		!gc->disconnect_timeout) {
		gc->disconnect_timeout = -1;
		AILog(@"%@: Disconnecting from a dropped network connection", self);
	}

	[super disconnectFromDroppedNetworkConnection];
}

#pragma mark File transfer
- (BOOL)canSendFolders
{
	return NO;
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#pragma mark Status Messages
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)b
{
	NSAttributedString  *statusMessage = nil;

	if (purple_account_is_connected(account)) {		
		char	*normalized = g_strdup(purple_normalize(purple_buddy_get_account(b), purple_buddy_get_name(b)));
		JabberBuddy	*jb;
		
		if ((jb = jabber_buddy_find(purple_account_get_connection(account)->proto_data, normalized, FALSE))) {
			NSString	*statusMessageString = nil;
			const char	*msg = jabber_buddy_get_status_msg(jb);
			
			if (msg) {
				//Get the custom jabber status message if one is set
				statusMessageString = [NSString stringWithUTF8String:msg];
			}
			
			if (statusMessageString && [statusMessageString length]) {
				statusMessage = [AIHTMLDecoder decodeHTML:statusMessageString];
			}
		}
		
		g_free(normalized);
	}
	
	return statusMessage;
}

- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	NSString		*statusName = nil;
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = purple_presence_get_active_status(presence);
	const char		*purpleStatusID = purple_status_get_id(status);
	
	if (!purpleStatusID) return nil;

	if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT))) {
		statusName = STATUS_NAME_FREE_FOR_CHAT;
		
	} else if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA))) {
		statusName = STATUS_NAME_EXTENDED_AWAY;
		
	} else if (!strcmp(purpleStatusID, jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND))) {
		statusName = STATUS_NAME_DND;
		
	}
	
	return statusName;
}

#pragma mark Menu items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Un-hide From") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Un-hide From %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Temporarily Hide From") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Temporarily Hide From %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "Unsubscribe") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Unsubscribe %@",nil),[inContact formattedUID]];

	} else if (strcmp(label, "(Re-)Request authorization") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]];

	} else if (strcmp(label,  "Cancel Presence Notification") == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Cancel Presence Notification to %@",nil),[inContact formattedUID]];	
	}
	
	return [super titleForContactMenuLabel:label forContact:inContact];
}

- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{	
	if (strcmp(label, "Set User Info...") == 0) {
		return [AILocalizedString(@"Set User Info", nil) stringByAppendingEllipsis];
		
	} else 	if (strcmp(label, "Search for Users...") == 0) {
		return [AILocalizedString(@"Search for Users", nil) stringByAppendingEllipsis];
		
	} else 	if (strcmp(label, "Set Mood...") == 0) {
		return [AILocalizedString(@"Set Mood", nil) stringByAppendingEllipsis];
		
	} else 	if (strcmp(label, "Set Nickname...") == 0) {
		return [AILocalizedString(@"Set Nickname", nil) stringByAppendingEllipsis];
	} 
	
	return [super titleForAccountActionMenuLabel:label];
}

#pragma mark Multiuser chat

//Multiuser chats come in with just the contact's name as contactName, but we want to actually do it right.
- (NSString *)uidForContactWithUID:(NSString *)inUID inChat:(AIChat *)chat
{
	return [NSString stringWithFormat:@"%@/%@",[chat name],inUID];
}

/*!
 * @brief A chat will be joined
 *
 * This gives the account a chance to update any information in the chat's creation dictionary if desired.
 *
 * @result The final chat creation dictionary to use.
 */
- (NSDictionary *)willJoinChatUsingDictionary:(NSDictionary *)chatCreationDictionary
{
	if (![[chatCreationDictionary objectForKey:@"handle"] length]) {
		NSMutableDictionary *dict = [[chatCreationDictionary mutableCopy] autorelease];
		
		[dict setObject:[self displayName]
				 forKey:@"handle"];

		chatCreationDictionary = dict;
	}
	
	return chatCreationDictionary;
}

- (BOOL)chatCreationDictionary:(NSDictionary *)chatCreationDict isEqualToDictionary:(NSDictionary *)baseDict
{
	/* If the chat isn't keeping track of a handle, it's because we added it in
	 * willJoinChatUsingDictionary: above. Remove it from baseDict so the comparison is accurate.
	 */
	if (![chatCreationDict objectForKey:@"handle"])
		baseDict = [baseDict dictionaryWithDifferenceWithSetOfKeys:[NSSet setWithObject:@"handle"]];

	return [chatCreationDict isEqualToDictionary:baseDict];
}

#pragma mark Status
/*!
 * @brief Return the purple status type to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the purple status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The purple status ID
 */
- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments
{
	const char		*statusID = NULL;
	NSString		*statusName = [statusState statusName];
	NSString		*statusMessageString = [statusState statusMessageString];
	NSNumber		*priority = nil;
	
	if (!statusMessageString) statusMessageString = @"";

	switch ([statusState statusType]) {
		case AIAvailableStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) ||
			   ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]] == NSOrderedSame) ||
				[statusName isEqualToString:STATUS_NAME_BUSY]) {
				//Note that Jabber doesn't actually support a 'busy' status; if we have it set because some other service supports it, treat it as DND
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND);

			} else if (([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIInvisibleStatusType:
			AILog(@"Warning: Invisibility is not yet supported in libpurple 2.0.0 jabber");
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_AWAY);
//			statusID = "Invisible";
			break;
			
		case AIOfflineStatusType:
			break;
	}

	//Set our priority, which is actually set along with the status...Default is 0.
	[arguments setObject:(priority ? priority : [NSNumber numberWithInt:0])
				  forKey:@"priority"];
	
	//We could potentially set buzz on a per-status basis. We have no UI for this, however.
	[arguments setObject:[NSNumber numberWithBool:YES] forKey:@"buzz"];

	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Gateway Tracking

- (void)addContact:(AIListContact *)theContact toGroupName:(NSString *)groupName contactName:(NSString *)contactName {
	NSRange atsign = [[theContact UID] rangeOfString:@"@"];
	if(atsign.location != NSNotFound)
		[super addContact:theContact toGroupName:groupName contactName:contactName];
	else {
		NSEnumerator *e = [gateways objectEnumerator];
		NSDictionary *gatewaydict;
		// avoid duplicates!
		while((gatewaydict = [e nextObject])) {
			if([[[gatewaydict objectForKey:@"contact"] UID] isEqualToString:[theContact UID]]) {
				[gateways removeObjectIdenticalTo:gatewaydict];
				break;
			}
		}

		[gateways addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 theContact, @"contact",
							 groupName, @"remoteGroup",
							 nil]];
	}
}

- (void)removeContact:(AIListContact *)theContact {
	NSRange atsign = [[theContact UID] rangeOfString:@"@"];
	if(atsign.location != NSNotFound)
		[super removeContact:theContact];
	else {
		for (NSDictionary *gatewaydict in [[gateways copy] autorelease]) {
			if([[[gatewaydict objectForKey:@"contact"] UID] isEqualToString:[theContact UID]]) {
				[[self purpleAdapter] removeUID:[theContact UID] onAccount:self fromGroup:[gatewaydict objectForKey:@"remoteGroup"]];
				
				[gateways removeObjectIdenticalTo:gatewaydict];
				break;
			}
		}
	}
}

#pragma mark XML Console, Tooltip, AdHoc Server Integration and Gateway Integration

/*!
* @brief Returns whether or not this account is connected via an encrypted connection.
 */
- (BOOL)encrypted
{
	return ([self online] && [self secureConnection]);
}

- (void)didConnect {
	[gateways release];
	gateways = [[NSMutableArray alloc] init];

	[adhocServer release];
	adhocServer = [[AMPurpleJabberAdHocServer alloc] initWithAccount:self];
	[adhocServer addCommand:@"ping" delegate:[AMPurpleJabberAdHocPing class] name:@"Ping"];
	
    [super didConnect];
	
	if ([self enableXMLConsole]) {
		if (!xmlConsoleController) xmlConsoleController = [[AMXMLConsoleController alloc] init];
		[xmlConsoleController setPurpleConnection:purple_account_get_connection(account)];
	}

	discoveryBrowserController = [[AMPurpleJabberServiceDiscoveryBrowsing alloc] initWithAccount:self
																				purpleConnection:purple_account_get_connection(account)];
}

- (void)didDisconnect {
	[xmlConsoleController setPurpleConnection:NULL];
	
	[discoveryBrowserController release]; discoveryBrowserController = nil;
	[adhocServer release]; adhocServer = nil;

	[super didDisconnect];

	[gateways release]; gateways = nil;
}

- (IBAction)showXMLConsole:(id)sender {
    if(xmlConsoleController)
        [xmlConsoleController showWindow:sender];
    else
        NSBeep();
}

- (BOOL)enableXMLConsole
{
	BOOL enableConsole;
#ifdef DEBUG_BUILD
	//Always enable the XML console for debug builds
	enableConsole = YES;
#else
	//For non-debug builds, only enable it if the preference is set
	enableConsole = [[NSUserDefaults standardUserDefaults] boolForKey:@"AMXMPPShowAdvanced"];
#endif
	
	return enableConsole;
}

- (IBAction)showDiscoveryBrowser:(id)sender {
	[discoveryBrowserController browse:sender];
}

- (PurpleSslConnection *)secureConnection {
	// this is really ugly
	PurpleConnection *gc = purple_account_get_connection(self.purpleAccount);

	return ((gc && gc->proto_data) ? ((JabberStream*)purple_account_get_connection(self.purpleAccount)->proto_data)->gsc : NULL);
}

- (void)setShouldVerifyCertificates:(BOOL)yesOrNo {
	[self setPreference:[NSNumber numberWithBool:yesOrNo] forKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS];
}

- (BOOL)shouldVerifyCertificates {
	return [[self preferenceForKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS] boolValue];
}

#ifdef HAVE_CDSA
- (IBAction)showServerCertificate:(id)sender {
	CFArrayRef certificates = [[self purpleAdapter] copyServerCertificates:[self secureConnection]];
	
	[AIPurpleCertificateViewer displayCertificateChain:certificates forAccount:self];
	CFRelease(certificates);
}
#endif

- (NSArray *)accountActionMenuItems {
	AILog(@"Getting accountActionMenuItems for %@",self);
	NSMutableArray *menu = [[NSMutableArray alloc] init];
	
	if([gateways count] > 0) {
		NSDictionary *gatewaydict;
		for(gatewaydict in gateways) {
			AIListContact *gateway = [gatewaydict objectForKey:@"contact"];
			NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:[gateway UID] action:@selector(registerGateway:) keyEquivalent:@""];
			NSMenu *submenu = [[NSMenu alloc] initWithTitle:[gateway UID]];
			
			NSArray *menuitemarray = [self menuItemsForContact:gateway];
			NSEnumerator *e2 = [menuitemarray objectEnumerator];
			NSMenuItem *m2item;
			while((m2item = [e2 nextObject]))
				[submenu addItem:m2item];
			
			if([submenu numberOfItems] > 0)
				[submenu addItem:[NSMenuItem separatorItem]];

			NSMenuItem *removeItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Remove gateway","gateway menu item") action:@selector(removeGateway:) keyEquivalent:@""];
			[removeItem setTarget:self];
			[removeItem setRepresentedObject:gateway];
			[submenu addItem:removeItem];
			[removeItem release];
			
			[mitem setSubmenu:submenu];
			[submenu release];
			[mitem setRepresentedObject:gateway];
			[mitem setImage:[AIStatusIcons statusIconForListObject:gateway
															  type:AIStatusIconTab
														 direction:AIIconNormal]];
			[mitem setTarget:self];
			[menu addObject:mitem];
			[mitem release];
		}
        [menu addObject:[NSMenuItem separatorItem]];
	}
	
    NSArray *supermenu = [super accountActionMenuItems];
    if(supermenu) {
		[menu addObjectsFromArray:supermenu];
        [menu addObject:[NSMenuItem separatorItem]];
	}

	if ([self enableXMLConsole]) {
		NSMenuItem *xmlConsoleMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"XML Console",nil)
																	action:@selector(showXMLConsole:) 
															 keyEquivalent:@""];
		[xmlConsoleMenuItem setTarget:self];
		[menu addObject:xmlConsoleMenuItem];
		[xmlConsoleMenuItem release];
	}

	NSMenuItem *discoveryBrowserMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Discovery Browser",nil)
																	  action:@selector(showDiscoveryBrowser:) 
															   keyEquivalent:@""];
    [discoveryBrowserMenuItem setTarget:self];
    [menu addObject:discoveryBrowserMenuItem];
    [discoveryBrowserMenuItem release];
	
#ifdef HAVE_CDSA
	if([self encrypted]) {
		NSMenuItem *showCertificateMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Show Server Certificate",nil)
																		  action:@selector(showServerCertificate:) 
																   keyEquivalent:@""];
		[showCertificateMenuItem setTarget:self];
		[menu addObject:showCertificateMenuItem];
		[showCertificateMenuItem release];
	}
#endif
	
    return [menu autorelease];
}

- (void)registerGateway:(NSMenuItem*)mitem {
	if(mitem && [mitem representedObject])
		jabber_register_gateway((JabberStream*)purple_account_get_connection(self.purpleAccount)->proto_data, [[[mitem representedObject] UID] UTF8String]);
	else
		NSBeep();
}

- (void)removeGateway:(NSMenuItem*)mitem {
	AIListContact *gateway = [mitem representedObject];
	if(![gateway isKindOfClass:[AIListContact class]])
		return;
	// since this is a potentially dangerous operation, get a confirmation from the user first
	if([[NSAlert alertWithMessageText:AILocalizedString(@"Really remove gateway?",nil)
					 defaultButton:AILocalizedString(@"Remove","alert default button")
				   alternateButton:AILocalizedString(@"Cancel",nil)
					   otherButton:nil
					 informativeTextWithFormat:AILocalizedString(@"This operation would remove the gateway %@ itself and all contacts belonging to the gateway on your contact list. It cannot be undone.",nil), [gateway UID]] runModal] == NSAlertDefaultReturn) {
		// first, locate all contacts on the roster that belong to this gateway
		NSString *jid = [gateway UID];
		NSString *pattern = [@"@" stringByAppendingString:jid];
		NSMutableArray *gatewayContacts = [[NSMutableArray alloc] init];
		NSEnumerator *e = [[self contacts] objectEnumerator];
		AIListContact *contact;
		while((contact = [e nextObject])) {
			if([[contact UID] hasSuffix:pattern])
				[gatewayContacts addObject:contact];
		}
		// now, remove them from the roster
		[self removeContacts:gatewayContacts];
		[gatewayContacts release];
		
		// finally, remove the gateway itself
		[self removeContact:gateway];
	}
}

- (AMPurpleJabberAdHocServer*)adhocServer {
	return adhocServer;
}

@end
