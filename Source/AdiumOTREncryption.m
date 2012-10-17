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

#import "AdiumOTREncryption.h"
#import <Adium/AIContentMessage.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import "AIHTMLDecoder.h"

#import <AIUtilities/AIStringAdditions.h>

#import "ESOTRPrivateKeyGenerationWindowController.h"
#import "ESOTRPreferences.h"
#import "ESOTRUnknownFingerprintController.h"
#import "OTRCommon.h"

#import <stdlib.h>

#define PRIVKEY_PATH [[[adium.loginController userDirectory] stringByAppendingPathComponent:@"otr.private_key"] UTF8String]
#define STORE_PATH	 [[[adium.loginController userDirectory] stringByAppendingPathComponent:@"otr.fingerprints"] UTF8String]
#define INSTAG_PATH [[[adium.loginController userDirectory] stringByAppendingPathComponent:@"otr.instag"] UTF8String]

#define CLOSED_CONNECTION_MESSAGE "has closed his private connection to you"

/* OTRL_POLICY_MANUAL doesn't let us respond to other users' automatic attempts at encryption.
* If either user has OTR set to Automatic, an OTR session should be begun; without this modified
* mask, both users would have to be on automatic for OTR to begin automatically, even though one user
* _manually_ attempting OTR will _automatically_ bring the other into OTR even if the setting is Manual.
*/
#define OTRL_POLICY_MANUAL_AND_RESPOND_TO_WHITESPACE	( OTRL_POLICY_MANUAL | \
													  OTRL_POLICY_WHITESPACE_START_AKE | \
													  OTRL_POLICY_ERROR_START_AKE )

@interface AdiumOTREncryption ()
- (void)prepareEncryption;

- (void)setSecurityDetails:(NSDictionary *)securityDetailsDict forChat:(AIChat *)inChat;

- (void)upgradeOTRIfNeeded;

- (void)adiumFinishedLaunching:(NSNotification *)inNotification;
- (void)adiumWillTerminate:(NSNotification *)inNotification;
- (void)updateSecurityDetails:(NSNotification *)inNotification;
- (void)verifyUnknownFingerprint:(NSValue *)contextValue;
@end

@implementation AdiumOTREncryption

/* We'll only use the one OtrlUserState. */
static OtrlUserState otrg_plugin_userstate = NULL;
static AdiumOTREncryption	*adiumOTREncryption = nil;

void otrg_ui_update_fingerprint(void);
void update_security_details_for_chat(AIChat *chat);
void send_default_query_to_chat(AIChat *inChat);
void disconnect_from_chat(AIChat *inChat);
void disconnect_from_context(ConnContext *context);
static OtrlMessageAppOps ui_ops;
TrustLevel otrg_plugin_context_to_trust(ConnContext *context);

- (id)init
{
	//Singleton
	if (adiumOTREncryption) {
		[self release];
		
		return [adiumOTREncryption retain];
	}

	if ((self = [super init])) {
		adiumOTREncryption = self;

		//Wait for Adium to finish launching to prepare encryption so that accounts will be loaded
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(adiumFinishedLaunching:)
										   name:AIApplicationDidFinishLoadingNotification
										 object:nil];
		/*
		gaim_signal_connect(conn_handle, "signed-on", otrg_plugin_handle,
							GAIM_CALLBACK(process_connection_change), NULL);
		gaim_signal_connect(conn_handle, "signed-off", otrg_plugin_handle,
							GAIM_CALLBACK(process_connection_change), NULL);		
		 */
	}
	
	return self;
}

- (void)adiumFinishedLaunching:(NSNotification *)inNotification
{
	[self prepareEncryption];
}

- (void)prepareEncryption
{
	/* Initialize the OTR library */
	OTRL_INIT;

	[self upgradeOTRIfNeeded];

	/* Make our OtrlUserState; we'll only use the one. */
	otrg_plugin_userstate = otrl_userstate_create();

	unsigned int err;
	
	err = otrl_privkey_read(otrg_plugin_userstate, PRIVKEY_PATH);
	if (err) {
		const char *errMsg = gpg_strerror(err);
		
		if (errMsg && strcmp(errMsg, "No such file or directory")) {
			NSLog(@"Error reading %s: %s", PRIVKEY_PATH, errMsg);
		}
	}

	otrg_ui_update_keylist();

	err = otrl_privkey_read_fingerprints(otrg_plugin_userstate, STORE_PATH,
								   NULL, NULL);
	if (err) {
		const char *errMsg = gpg_strerror(err);
		
		if (errMsg && strcmp(errMsg, "No such file or directory")) {
			NSLog(@"Error reading %s: %s", STORE_PATH, errMsg);
		}
	}

	otrg_ui_update_fingerprint();
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(adiumWillTerminate:)
									   name:AIAppWillTerminateNotification
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(updateSecurityDetails:) 
									   name:Chat_SourceChanged
									 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(updateSecurityDetails:) 
									   name:Chat_DestinationChanged
									 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(updateSecurityDetails:) 
									   name:Chat_DidOpen
									 object:nil];

	//Add the Encryption preferences
	OTRPrefs = [(ESOTRPreferences *)[ESOTRPreferences preferencePane] retain];
}

- (void)dealloc
{
	[OTRPrefs release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}


#pragma mark -

/* 
* @brief Return an NSDictionary* describing a ConnContext.
 *
 *      Key				 :        Contents
 * @"Their Fingerprint"	 : NSString of the contact's fingerprint's human-readable hash
 * @"Our Fingerprint"	 : NSString of our fingerprint's human-readable hash
 * @"Incoming SessionID" : NSString of the incoming sessionID
 * @"Outgoing SessionID" : NSString of the outgoing sessionID
 * @"EncryptionStatus"	 : An AIEncryptionStatus
 * @"AIAccount"			 : The AIAccount of this context
 * @"who"				 : The UID of the remote user *
 * @result The dictinoary
 */
static NSDictionary* details_for_context(ConnContext *context)
{
	if (!context) return nil;

	NSDictionary		*securityDetailsDict;
	Fingerprint *fprint = context->active_fingerprint;	

    if (!fprint || !(fprint->fingerprint)) return nil;
    context = fprint->context;
    if (!context) return nil;

    TrustLevel			level = otrg_plugin_context_to_trust(context);
	AIEncryptionStatus	encryptionStatus;
	AIAccount			*account;
	
	switch (level) {
		default:
	    case TRUST_NOT_PRIVATE:
			encryptionStatus = EncryptionStatus_None;
			break;
		case TRUST_UNVERIFIED:
			encryptionStatus = EncryptionStatus_Unverified;
			break;
		case TRUST_PRIVATE:
			encryptionStatus = EncryptionStatus_Verified;
			break;
		case TRUST_FINISHED:
			encryptionStatus = EncryptionStatus_Finished;
			break;
	}
	
    char our_hash[45], their_hash[45];

	otrl_privkey_fingerprint(otrg_get_userstate(), our_hash,
							 context->accountname, context->protocol);
	
    otrl_privkey_hash_to_human(their_hash, fprint->fingerprint);

	unsigned char *sessionid;
    char sess1[21], sess2[21];
	BOOL sess1_outgoing = (context->sessionid_half == OTRL_SESSIONID_FIRST_HALF_BOLD);
    size_t idhalflen = (context->sessionid_len) / 2;

    /* Make a human-readable version of the sessionid (in two parts) */
    sessionid = context->sessionid;
    for(NSUInteger i = 0; i < idhalflen; ++i) sprintf(sess1+(2*i), "%02x", sessionid[i]);
    for(NSUInteger i = 0; i < idhalflen; ++i) sprintf(sess2+(2*i), "%02x", sessionid[i+idhalflen]);

	account = [adium.accountController accountWithInternalObjectID:[NSString stringWithUTF8String:context->accountname]];

	securityDetailsDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:their_hash], @"Their Fingerprint",
		[NSString stringWithUTF8String:our_hash], @"Our Fingerprint",
		[NSNumber numberWithInteger:encryptionStatus], @"EncryptionStatus",
		account, @"AIAccount",
		[NSString stringWithUTF8String:context->username], @"who",
		[NSString stringWithUTF8String:sess1], (sess1_outgoing ? @"Outgoing SessionID" : @"Incoming SessionID"),
		[NSString stringWithUTF8String:sess2], (sess1_outgoing ? @"Incoming SessionID" : @"Outgoing SessionID"),
		nil];
	
	AILog(@"Security details: %@",securityDetailsDict);
	
	return securityDetailsDict;
}


static AIAccount* accountFromAccountID(const char *accountID)
{
	return [adium.accountController accountWithInternalObjectID:[NSString stringWithUTF8String:accountID]];
}

static AIService* serviceFromServiceID(const char *serviceID)
{
	return [adium.accountController serviceWithUniqueID:[NSString stringWithUTF8String:serviceID]];
}

static AIListContact* contactFromInfo(const char *accountID, const char *serviceID, const char *username)
{
	return [adium.contactController contactWithService:serviceFromServiceID(serviceID)
																		  account:accountFromAccountID(accountID)
																			  UID:[NSString stringWithUTF8String:username]];
}
static AIListContact* contactForContext(ConnContext *context)
{
	return contactFromInfo(context->accountname, context->protocol, context->username);
}

static AIChat* chatForContext(ConnContext *context)
{
	AIListContact *listContact = contactForContext(context);
	AIChat *chat = [adium.chatController existingChatWithContact:listContact];
	if (!chat) {
		chat = [adium.chatController chatWithContact:listContact];
	}
	
	return chat;
}


static OtrlPolicy policyForContact(AIListContact *contact)
{
	OtrlPolicy		policy = OTRL_POLICY_MANUAL_AND_RESPOND_TO_WHITESPACE;
	
	//Force OTRL_POLICY_MANUAL when interacting with mobile numbers
	if ([contact.UID hasPrefix:@"+"]) {
		policy = OTRL_POLICY_MANUAL_AND_RESPOND_TO_WHITESPACE;
		
	} else {
		AIEncryptedChatPreference	pref = contact.encryptedChatPreferences;
		switch (pref) {
				case EncryptedChat_Never:
					policy = OTRL_POLICY_NEVER;
					break;
				case EncryptedChat_Manually:
				case EncryptedChat_Default:
					policy = OTRL_POLICY_MANUAL_AND_RESPOND_TO_WHITESPACE;
					break;
				case EncryptedChat_Automatically:
					policy = OTRL_POLICY_OPPORTUNISTIC;
					break;
				case EncryptedChat_RejectUnencryptedMessages:
					policy = OTRL_POLICY_ALWAYS;
					break;
		}
	}
	
	return policy;
	
}

//Return the ConnContext for a Conversation, or NULL if none exists
static ConnContext* contextForChat(AIChat *chat)
{
	AIAccount	*account;
    const char *username, *accountname, *proto;
    ConnContext *context;
	
    /* Do nothing if this isn't an IM conversation */
    if (chat.isGroupChat) return nil;
	
    account = chat.account;
	accountname = [account.internalObjectID UTF8String];
	proto = [account.service.serviceCodeUniqueID UTF8String];
    username = [chat.listObject.UID UTF8String];
	
    context = otrl_context_find(otrg_plugin_userstate,
								username, accountname, proto, OTRL_INSTAG_BEST, 0, NULL,
								NULL, NULL);
	
	return context;
}

/* What level of trust do we have in the privacy of this ConnContext? */
TrustLevel otrg_plugin_context_to_trust(ConnContext *context)
{
    TrustLevel level = TRUST_NOT_PRIVATE;
	
    if (context && context->msgstate == OTRL_MSGSTATE_ENCRYPTED) {
		if (context->active_fingerprint->trust &&
			context->active_fingerprint->trust[0] != '\0') {
			level = TRUST_PRIVATE;
		} else {
			level = TRUST_UNVERIFIED;
		}
    } else if (context && context->msgstate == OTRL_MSGSTATE_FINISHED) {
		level = TRUST_FINISHED;
    }
	
    return level;
}

#pragma mark -
/* Return the OTR policy for the given context. */

static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	OtrlPolicy ret = policyForContact(contactForContext(context));
	
	[pool release];
	
	return ret;
}

/* Generate a private key for the given accountname/protocol */
void otrg_plugin_create_privkey(const char *accountname,
								const char *protocol)
{	
	AIAccount	*account = accountFromAccountID(accountname);
	AIService	*service = serviceFromServiceID(protocol);
	
	NSString	*identifier = [NSString stringWithFormat:@"%@ (%@)",account.formattedUID, [service shortDescription]];
	
	[ESOTRPrivateKeyGenerationWindowController startedGeneratingForIdentifier:identifier];
	
    /* Generate the key */
    otrl_privkey_generate(otrg_plugin_userstate, PRIVKEY_PATH,
						  accountname, protocol);
    otrg_ui_update_keylist();
	
    /* Mark the dialog as done. */
	[ESOTRPrivateKeyGenerationWindowController finishedGeneratingForIdentifier:identifier];
}

/* Create a private key for the given accountname/protocol if
 * desired. */
static void create_privkey_cb(void *opdata, const char *accountname,
							  const char *protocol)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	otrg_plugin_create_privkey(accountname, protocol);
	[pool release];
}

/* Report whether you think the given user is online.  Return 1 if
 * you think he is, 0 if you think he isn't, -1 if you're not sure.
 *
 * If you return 1, messages such as heartbeats or other
 * notifications may be sent to the user, which could result in "not
 * logged in" errors if you're wrong. */
static int is_logged_in_cb(void *opdata, const char *accountname,
						   const char *protocol, const char *recipient)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AIListContact *contact = contactFromInfo(accountname, protocol, recipient);
	int ret;
	if ([contact statusSummary] == AIUnknownStatus)
		ret = -1;
	else
		ret = (contact.online ? 1 : 0);
	
	[pool release];
	
	return ret;
}

/* Send the given IM to the given recipient from the given
 * accountname/protocol. */
static void inject_message_cb(void *opdata, const char *accountname,
							  const char *protocol, const char *recipient, const char *message)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[adium.contentController sendRawMessage:[NSString stringWithUTF8String:message]
															 toContact:contactFromInfo(accountname, protocol, recipient)];
	[pool release];
}

/* When the list of ConnContexts changes (including a change in
 * state), this is called so the UI can be updated. */
static void update_context_list_cb(void *opdata)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	otrg_ui_update_keylist();
	
	[pool release];
}

/* Return a newly allocated string containing a human-friendly
 * representation for the given account */
static const char *account_display_name_cb(void *opdata, const char *accountname, const char *protocol)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	const char *ret = strdup([[accountFromAccountID(accountname) formattedUID] UTF8String]);
	
	[pool release];
	
	return ret;
}

/* Deallocate a string returned by account_name */
static void account_display_name_free_cb(void *opdata, const char *account_display_name)
{
	if (account_display_name)
		free((char *)account_display_name);
}


/* A new fingerprint for the given user has been received. */
static void new_fingerprint_cb(void *opdata, OtrlUserState us,
								   const char *accountname, const char *protocol, const char *username,
								   unsigned char fingerprint[20])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ConnContext			*context;
	
	context = otrl_context_find(us, username, accountname,
								protocol, OTRL_INSTAG_BEST, 0, NULL, NULL, NULL);
	
	if (context == NULL/* || context->msgstate != OTRL_MSGSTATE_ENCRYPTED*/) {
		NSLog(@"otrg_adium_dialog_unknown_fingerprint: Ack!");
		return;
	}
	
	[adiumOTREncryption performSelector:@selector(verifyUnknownFingerprint:)
							 withObject:[NSValue valueWithPointer:context]
							 afterDelay:0];
	[pool release];
}

/* The list of known fingerprints has changed.  Write them to disk. */
static void write_fingerprints_cb(void *opdata)
{
	otrg_plugin_write_fingerprints();
}

/* A ConnContext has entered a secure state. */
static void gone_secure_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AIChat *chat = chatForContext(context);

    update_security_details_for_chat(chat);
	otrg_ui_update_fingerprint();
	
	[pool release];
}

/* A ConnContext has left a secure state. */
static void gone_insecure_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AIChat *chat = chatForContext(context);

    update_security_details_for_chat(chat);
	otrg_ui_update_fingerprint();
	
	[pool release];
}

/* We have completed an authentication, using the D-H keys we
 * already knew.  is_reply indicates whether we initiated the AKE. */
static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (is_reply == 0) {
		//		otrg_dialog_stillconnected(context);
		AILog(@"Still secure...");
    }
	
	[pool release];
}

/*!
 * @brief Find the maximum message size supported by this protocol.
 *
 * This method is called whenever a message is about to be sent with
 * fragmentation enabled.  The return value is checked against the size of
 * the message to be sent to determine whether fragmentation is necessary.
 *
 * Setting max_message_size to NULL will disable the fragmentation of all
 * sent messages; returning 0 from this callback will disable fragmentation
 * of a particular message.  The latter is useful, for example, for
 * protocols like XMPP (Jabber) that do not require fragmentation at all.
 */
int max_message_size_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AIChat *chat = chatForContext(context);
	
	/* Values from http://www.cypherpunks.ca/otr/UPGRADING-libotr-3.1.0.txt */
	static NSDictionary *maxSizeByServiceClassDict = nil;
	if (!maxSizeByServiceClassDict) {
		maxSizeByServiceClassDict = [[NSDictionary alloc] initWithObjectsAndKeys:
									 [NSNumber numberWithInteger:2343], @"AIM-compatible",
									 [NSNumber numberWithInteger:1409], @"MSN",
									 [NSNumber numberWithInteger:832], @"Yahoo!",
									 [NSNumber numberWithInteger:1999], @"Gadu-Gadu",
									 [NSNumber numberWithInteger:417], @"IRC",
									 nil];
	}

	/* This will return 0 if we don't know (unknown protocol) or don't need it (Jabber),
	 * which will disable fragmentation.
	 */
	int ret = [[maxSizeByServiceClassDict objectForKey:chat.account.service.serviceClass] intValue];
	
	[pool release];
	
	return ret;
}

static const char *error_message_cb(void *opdata, ConnContext *context, OtrlErrorCode err_code)
{
	NSString *errorMessage = nil;
	
	switch (err_code) {
		case OTRL_ERRCODE_ENCRYPTION_ERROR:
			errorMessage = AILocalizedStringFromTableInBundle(@"An error occured while encrypting a message", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			break;
		case OTRL_ERRCODE_MSG_NOT_IN_PRIVATE:
			errorMessage = AILocalizedStringFromTableInBundle(@"Sent encrypted message to somebody who is not in a mutual OTR session", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
		case OTRL_ERRCODE_MSG_UNREADABLE:
			errorMessage = AILocalizedStringFromTableInBundle(@"Sent an unreadable encrypted message", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
		case OTRL_ERRCODE_MSG_MALFORMED:
			errorMessage = AILocalizedStringFromTableInBundle(@"Message sent is malformed", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			
		default:
			return NULL;
	}
	
	const char *message_str = strdup([errorMessage UTF8String]);
	
	return message_str;
}

static void error_message_free_cb(void *opdata, const char *err_msg)
{
	free((char *)err_msg);
}

static const char *resent_msg_prefix_cb(void *opdata, ConnContext *context)
{
	const char *prefix_str = strdup([AILocalizedStringFromTableInBundle(@"[resent]", @"Prefix used by OTR for resent messages", [NSBundle bundleForClass:[AdiumOTREncryption class]], nil) UTF8String]);
	
	return prefix_str;
}

static void resent_msg_prefix_free_cb(void *opdata, const char *prefix)
{
	free((char *)prefix);
}

static void timer_control_cb(void *opdata, unsigned int interval) {
	static dispatch_source_t timer = NULL;
	
	if (!timer && interval > 0) {
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_MSEC);
		
		dispatch_source_set_event_handler(timer, ^{
			otrl_message_poll(otrg_plugin_userstate, &ui_ops, opdata);
		});
		
		dispatch_resume(timer);
	}
	if (timer && interval == 0) {
		dispatch_source_cancel(timer);
		dispatch_release(timer);
		timer = NULL;
	}
}

static void
handle_msg_event_cb(void *opdata, OtrlMessageEvent msg_event,
				  ConnContext *context, const char *message,
				  gcry_error_t err)
{
	AILogWithSignature(@"Something happened in this conversation: %s", message);
	
	AIListContact *listContact = contactForContext(context);
	AIChat *chat = chatForContext(context);
	
	switch (msg_event) {
		case OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED:
			if (!chat) chat = [adium.chatController chatWithContact:listContact];
			
			AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
																   withSource:listContact
																  destination:chat.account
																		 date:nil
																	  message:[AIHTMLDecoder decodeHTML:[NSString stringWithFormat:AILocalizedStringFromTableInBundle(@"The following message was received <b>unencrypted:</b> %s", @"libotr error message", [NSBundle bundleForClass:[AdiumOTREncryption class]], nil), message]]
																	autoreply:NO];
			
			[adium.contentController receiveContentObject:messageObject];
			break;
			
		case OTRL_MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE:
			AILogWithSignature(@"Received an OTR message for a different instance. We will silently ignore it: %s", message);
			break;
		
		case OTRL_MSGEVENT_LOG_HEARTBEAT_RCVD:
		case OTRL_MSGEVENT_LOG_HEARTBEAT_SENT:
			AILogWithSignature(@"I'm still alive");
			break;
			
		default:
			break;
	}
}

void create_instag_cb(void *opdata, const char *accountname,
					const char *protocol)
{
	otrl_instag_generate(otrg_plugin_userstate, INSTAG_PATH, accountname, protocol);
}

static OtrlMessageAppOps ui_ops = {
    policy_cb,
    create_privkey_cb,
    is_logged_in_cb,
    inject_message_cb,
    update_context_list_cb,
    new_fingerprint_cb,
    write_fingerprints_cb,
    gone_secure_cb,
    gone_insecure_cb,
    still_secure_cb,
	max_message_size_cb,
	account_display_name_cb,
	account_display_name_free_cb,
	NULL /* received_symkey */,
	error_message_cb,
	error_message_free_cb,
	resent_msg_prefix_cb,
	resent_msg_prefix_free_cb,
	NULL /* handle_smp_event */,
	handle_msg_event_cb,
	create_instag_cb,
	NULL /* convert_msg */,
	NULL /* convert_free */,
	timer_control_cb,
};

#pragma mark -

- (void)willSendContentMessage:(AIContentMessage *)inContentMessage
{
	const char	*originalMessage = [[inContentMessage encodedMessage] UTF8String];
	AIAccount	*account = (AIAccount *)[inContentMessage source];
    const char	*accountname = [account.internalObjectID UTF8String];
    const char	*protocol = [account.service.serviceCodeUniqueID UTF8String];
    const char	*username = [[[inContentMessage destination] UID] UTF8String];
	char		*fullOutgoingMessage = NULL;

    gcry_error_t err;
	
    if (!username || !originalMessage)
		return;
	
	ConnContext		*context = contextForChat(inContentMessage.chat);
	
    err = otrl_message_sending(otrg_plugin_userstate, &ui_ops, /* opData */ NULL,
							   accountname, protocol, username, OTRL_INSTAG_BEST, originalMessage, /* tlvs */ NULL, &fullOutgoingMessage,
							   OTRL_FRAGMENT_SEND_ALL_BUT_LAST, &context,
							   /* add_appdata cb */NULL, /* appdata */ NULL);

    if (err && fullOutgoingMessage == NULL) {
		//Be *sure* not to send out plaintext
		[inContentMessage setEncodedMessage:nil];

    } else if (fullOutgoingMessage) {
		//This new message is what should be sent to the remote contact
		[inContentMessage setEncodedMessage:[NSString stringWithUTF8String:fullOutgoingMessage]];

		//We're now done with the messages allocated by OTR
		otrl_message_free(fullOutgoingMessage);
    }
}

/* Abort the SMP protocol.  Used when malformed or unexpected messages
 * are received. */
static void otrg_plugin_abort_smp(ConnContext *context)
{
	otrl_message_abort_smp(otrg_plugin_userstate, &ui_ops, NULL, context);
}

/* Start the Socialist Millionaires' Protocol over the current connection,
 * using the given initial secret. */
void otrg_plugin_start_smp(ConnContext *context,
						   const unsigned char *secret, size_t secretlen)
{
    otrl_message_initiate_smp(otrg_plugin_userstate, &ui_ops, NULL,
							  context, secret, secretlen);	
}

/* Continue the Socialist Millionaires' Protocol over the current connection,
 * using the given initial secret (ie finish step 2). */
void otrg_plugin_continue_smp(ConnContext *context,
							  const unsigned char *secret, size_t secretlen)
{
	otrl_message_respond_smp(otrg_plugin_userstate, &ui_ops, NULL,
							 context, secret, secretlen);
}

/* Show a dialog asking the user to respond to an SMP secret sent by a remote contact.
 * Our user should enter the same secret entered by the remote contact. */
static void otrg_dialogue_respond_socialist_millionaires(ConnContext *context)
{
    if (context == NULL || context->msgstate != OTRL_MSGSTATE_ENCRYPTED)
		return;

	/* XXX Implement me - prompt to respond to a secret, and then call
	 * otrg_plugin_continue_smp() with the secret and the appropriate context */
}

static void otrg_dialog_update_smp(ConnContext *context, CGFloat percentage)
{
	/* SMP status update */
}

- (NSString *)decryptIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	NSString	*decryptedMessage = nil;
	const char *message = [inString UTF8String];
	char *newMessage = NULL;
    OtrlTLV *tlvs = NULL;
    OtrlTLV *tlv = NULL;
	const char *username = [inListContact.UID UTF8String];
    const char *accountname = [inAccount.internalObjectID UTF8String];
    const char *protocol = [inAccount.service.serviceCodeUniqueID UTF8String];
	BOOL	res;

	/* If newMessage is set to non-NULL and res is 0, use newMessage.
	 * If newMessage is set to non-NULL and res is not 0, display nothing as this was an OTR message
	 * If newMessage is set to NULL and res is 0, use message
	 */
    res = otrl_message_receiving(otrg_plugin_userstate, &ui_ops, NULL,
								 accountname, protocol, username, message,
								 &newMessage, &tlvs, NULL, NULL, NULL);
	
	if (!newMessage && !res) {
		//Use the original mesage; this was not an OTR-related message
		decryptedMessage = inString;
		
		AILogWithSignature(@"Not OTR-related message for decryption.");
	} else if (newMessage && !res) {
		//We decryped an OTR-encrypted message
		decryptedMessage = [NSString stringWithUTF8String:newMessage];

		AILogWithSignature(@"Decrypted an OTR message.");
	} else /* (newMessage && res) */{
		//This was an OTR protocol message
		decryptedMessage = nil;
		
		AILogWithSignature(@"Skipping an OTR protocol message.");
	}

	if (newMessage)
		otrl_message_free(newMessage);

    tlv = otrl_tlv_find(tlvs, OTRL_TLV_DISCONNECTED);
    if (tlv) {
		/* Notify the user that the other side disconnected. */
		
		NSString *localizedMessage = [NSString stringWithFormat:AILocalizedString(@"%s is no longer using encryption; you should cancel encryption on your side.", "Message when the remote contact cancels his half of an encrypted conversation. %s will be a name."), username];
		AIChat *chat = [adium.chatController chatWithContact:inListContact];
		
		if (chat) {
			[adium.contentController displayEvent:[[AIHTMLDecoder decodeHTML:localizedMessage] string]
										   ofType:@"encryption"
										   inChat:chat];
		}

		otrg_ui_update_keylist();
    }

	/* Keep track of our current progress in the Socialist Millionaires'
     * Protocol. */
	ConnContext *context = otrl_context_find(otrg_plugin_userstate, username,
											 accountname, protocol, OTRL_INSTAG_BEST, 0, NULL, NULL, NULL);
    if (context) {
		NextExpectedSMP nextMsg = context->smstate->nextExpected;
		
		tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP1);
		if (tlv) {
			if (nextMsg != OTRL_SMP_EXPECT1)
				otrg_plugin_abort_smp(context);
			else {
				otrg_dialogue_respond_socialist_millionaires(context);
			}
		}
		tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP2);
		if (tlv) {
			if (nextMsg != OTRL_SMP_EXPECT2)
				otrg_plugin_abort_smp(context);
			else {
				otrg_dialog_update_smp(context, 0.6f);
				context->smstate->nextExpected = OTRL_SMP_EXPECT4;
			}
		}
		tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP3);
		if (tlv) {
			if (nextMsg != OTRL_SMP_EXPECT3)
				otrg_plugin_abort_smp(context);
			else {
				otrg_dialog_update_smp(context, 1.0f);
				context->smstate->nextExpected = OTRL_SMP_EXPECT1;
			}
		}
		tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP4);
		if (tlv) {
			if (nextMsg != OTRL_SMP_EXPECT4)
				otrg_plugin_abort_smp(context);
			else {
				otrg_dialog_update_smp(context, 1.0f);
				context->smstate->nextExpected = OTRL_SMP_EXPECT1;
			}
		}
		tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP_ABORT);
		if (tlv) {
			otrg_dialog_update_smp(context, 0.0f);
			context->smstate->nextExpected = OTRL_SMP_EXPECT1;
		}
	}

    otrl_tlv_free(tlvs);
	
	return decryptedMessage;
}

- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat
{
	if (inSecureMessaging) {
		send_default_query_to_chat(inChat);

	} else {
		disconnect_from_chat(inChat);
	}
}

- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	ConnContext		*context = contextForChat(inChat);
	NSDictionary	*responseInfo = details_for_context(context);;

	[ESOTRUnknownFingerprintController showVerifyFingerprintPromptWithResponseInfo:responseInfo];	
}

/*!
 * @brief Adium will begin terminating
 *
 * Send the OTRL_TLV_DISCONNECTED packets when we're about to quit before we disconnect
 */
- (void)adiumWillTerminate:(NSNotification *)inNotification
{
	ConnContext *context = otrg_plugin_userstate->context_root;
	while(context) {
		ConnContext *next = context->next;
		if (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
			context->protocol_version > 1) {
			disconnect_from_context(context);
		}
		context = next;
	}
}

/*!
 * @brief A chat notification was posted after which we should update our security details
 *
 * @param inNotification A notification whose object is the AIChat in question
 */
- (void)updateSecurityDetails:(NSNotification *)inNotification
{
	AILog(@"Updating security details for %@",[inNotification object]);
	update_security_details_for_chat([inNotification object]);
}

void update_security_details_for_chat(AIChat *inChat)
{
	ConnContext *context = contextForChat(inChat);

	[adiumOTREncryption setSecurityDetails:details_for_context(context)
								   forChat:inChat];
}

- (void)setSecurityDetails:(NSDictionary *)securityDetailsDict forChat:(AIChat *)inChat
{
	if (inChat) {
		NSMutableDictionary	*fullSecurityDetailsDict;
		
		if (securityDetailsDict) {
			NSString				*format, *description;
			fullSecurityDetailsDict = [[securityDetailsDict mutableCopy] autorelease];
			
			/* Encrypted by Off-the-Record Messaging
				*
				* Fingerprint for TekJew:
				* <Fingerprint>
				*
				* Secure ID for this session:
				* Incoming: <Incoming SessionID>
				* Outgoing: <Outgoing SessionID>
				*/
			format = [@"%@\n\n" stringByAppendingString:AILocalizedString(@"Fingerprint for %@:","Fingerprint for <name>:")];
			format = [format stringByAppendingString:@"\n%@\n\n%@\n%@ %@\n%@ %@"];
			
			description = [NSString stringWithFormat:format,
				AILocalizedString(@"Encrypted by Off-the-Record Messaging",nil),
				[[inChat listObject] formattedUID],
				[securityDetailsDict objectForKey:@"Their Fingerprint"],
				AILocalizedString(@"Secure ID for this session:",nil),
				AILocalizedString(@"Incoming:","This is shown before the Off-the-Record Session ID (a series of numbers and letters) sent by the other party with whom you are having an encrypted chat."),
				[securityDetailsDict objectForKey:@"Incoming SessionID"],
				AILocalizedString(@"Outgoing:","This is shown before the Off-the-Record Session ID (a series of numbers and letters) sent by you to the other party with whom you are having an encrypted chat."),
				[securityDetailsDict objectForKey:@"Outgoing SessionID"],
				nil];
			
			[fullSecurityDetailsDict setObject:description
										forKey:@"Description"];
		} else {
			fullSecurityDetailsDict = nil;	
		}
		
		[inChat setSecurityDetails:fullSecurityDetailsDict];
	}
}	

#pragma mark -

void send_default_query_to_chat(AIChat *inChat)
{
	//Note that we pass a name for display, not internal usage
	char *msg = otrl_proto_default_query_msg([inChat.account.formattedUID UTF8String],
											 policyForContact([inChat listObject]));
	
	[adium.contentController sendRawMessage:[NSString stringWithUTF8String:(msg ? msg : "?OTRv2?")]
															 toContact:[inChat listObject]];
	if (msg)
		free(msg);
}

/* Disconnect a context, sending a notice to the other side, if
* appropriate. */
void disconnect_from_context(ConnContext *context)
{
    otrl_message_disconnect(otrg_plugin_userstate, &ui_ops, NULL,
							context->accountname, context->protocol, context->username, OTRL_INSTAG_BEST);
	gone_insecure_cb(NULL, context);
}

void disconnect_from_chat(AIChat *inChat)
{
	disconnect_from_context(contextForChat(inChat));
}

#pragma mark -

/* Forget a fingerprint */
void otrg_ui_forget_fingerprint(Fingerprint *fingerprint)
{
    ConnContext *context;

    /* Don't do anything with the active fingerprint if we're in the
	 * ENCRYPTED state. */
    context = (fingerprint ? fingerprint->context : NULL);
    if (context && (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
					context->active_fingerprint == fingerprint)) return;
	
    otrl_context_forget_fingerprint(fingerprint, 1);
    otrg_plugin_write_fingerprints();
}

void otrg_plugin_write_fingerprints(void)
{
    otrl_privkey_write_fingerprints(otrg_plugin_userstate, STORE_PATH);
	otrg_ui_update_fingerprint();
}

void otrg_ui_update_keylist(void)
{
	[adiumOTREncryption prefsShouldUpdatePrivateKeyList];
}

void otrg_ui_update_fingerprint(void)
{
	[adiumOTREncryption prefsShouldUpdateFingerprintsList];
}

OtrlUserState otrg_get_userstate(void)
{
	return otrg_plugin_userstate;
}

#pragma mark -

- (void)verifyUnknownFingerprint:(NSValue *)contextValue
{
	NSDictionary		*responseInfo;
	
	responseInfo = details_for_context([contextValue pointerValue]);
	
	[ESOTRUnknownFingerprintController showUnknownFingerprintPromptWithResponseInfo:responseInfo];
}

/*!
 * @brief Call this function when our DSA key is updated; it will redraw the Encryption preferences item, if visible.
 */
- (void)prefsShouldUpdatePrivateKeyList
{
	[OTRPrefs updatePrivateKeyList];
}

/*!
 * @brief Update the list of other users' fingerprints, if it's visible
 */
- (void)prefsShouldUpdateFingerprintsList
{
	[OTRPrefs updateFingerprintsList];
}

#pragma mark Upgrading gaim-otr --> Adium-otr
/*!
 * @brief Construct a dictionary converting libpurple prpl names to Adium serviceIDs for the purpose of fingerprint upgrading
 */
- (NSDictionary *)prplDict
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"libpurple-OSCAR-AIM", @"prpl-oscar",
		@"libpurple-Gadu-Gadu", @"prpl-gg",
		@"libpurple-Jabber", @"prpl-jabber",
		@"libpurple-Sametime", @"prpl-meanwhile",
		@"libpurple-MSN", @"prpl-msn",
		@"libpurple-GroupWise", @"prpl-novell",
		@"libpurple-Yahoo!", @"prpl-yahoo",
		@"libpurple-zephyr", @"prpl-zephyr", nil];
}

- (NSString *)upgradedFingerprintsFromFile:(NSString *)inPath
{
	NSString		*sourceFingerprints = [NSString stringWithContentsOfUTF8File:inPath];
	
	if (!sourceFingerprints  || ![sourceFingerprints length]) return nil;

	NSScanner		*scanner = [NSScanner scannerWithString:sourceFingerprints];
	NSMutableString *outFingerprints = [NSMutableString string];
	NSCharacterSet	*tabAndNewlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\t\n\r"];
	
	//Skip quotes
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
	
	NSDictionary	*prplDict = [self prplDict];

	while (![scanner isAtEnd]) {
		//username     accountname  protocol      key	trusted\n
		NSString		*chunk;
		NSString		*username = nil, *accountname = nil, *protocol = nil, *key = nil, *trusted = nil;
		
		//username
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&username];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//accountname
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&accountname];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//protocol
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&protocol];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];
		
		//key
		[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&key];
		[scanner scanCharactersFromSet:tabAndNewlineSet intoString:&chunk];
		
		//We have a trusted entry
		if ([chunk isEqualToString:@"\t"]) {
			//key
			[scanner scanUpToCharactersFromSet:tabAndNewlineSet intoString:&trusted];
			[scanner scanCharactersFromSet:tabAndNewlineSet intoString:NULL];		
		} else {
			trusted = nil;
		}
		
		if (username && accountname && protocol && key) {
			for (AIAccount *account in adium.accountController.accounts) {
				//Hit every possibile name for this account along the way
				if ([[NSSet setWithObjects:account.UID,account.formattedUID,[account.UID compactedString], nil] containsObject:accountname]) {
					if ([account.service.serviceCodeUniqueID isEqualToString:[prplDict objectForKey:protocol]]) {
						[outFingerprints appendString:
							[NSString stringWithFormat:@"%@\t%@\t%@\t%@", username, account.internalObjectID, account.service.serviceCodeUniqueID, key]];
						if (trusted) {
							[outFingerprints appendString:@"\t"];
							[outFingerprints appendString:trusted];
						}
						[outFingerprints appendString:@"\n"];
					}
				}
			}
		}
	}
	
	return outFingerprints;
}

- (NSString *)upgradedPrivateKeyFromFile:(NSString *)inPath
{
	NSMutableString	*sourcePrivateKey = [[[NSString stringWithContentsOfUTF8File:inPath] mutableCopy] autorelease];
	AILog(@"Upgrading private keys at %@ gave %@",inPath,sourcePrivateKey);
	if (!sourcePrivateKey || ![sourcePrivateKey length]) return nil;

	/*
	 * Gaim used the account name for the name and the prpl id for the protocol.
	 * We will use the internalObjectID for the name and the service's uniqueID for the protocol.
	 */

	/* Remove Jabber resources... from the private key list
	 * If you used a non-default resource, no upgrade for you.
	 */
	[sourcePrivateKey replaceOccurrencesOfString:@"/Adium"
									  withString:@""
										 options:NSLiteralSearch
										   range:NSMakeRange(0, [sourcePrivateKey length])];

	NSDictionary	*prplDict = [self prplDict];

	for (AIAccount *account in adium.accountController.accounts) {
		//Hit every possibile name for this account along the way
		NSString		*accountInternalObjectID = [NSString stringWithFormat:@"\"%@\"",account.internalObjectID];

		for (NSString *accountName in [NSSet setWithObjects:account.UID,account.formattedUID,[account.UID compactedString], nil]) {
			NSRange			accountNameRange = NSMakeRange(0, 0);
			NSRange			searchRange = NSMakeRange(0, [sourcePrivateKey length]);

			while (accountNameRange.location != NSNotFound &&
				   (NSMaxRange(searchRange) <= [sourcePrivateKey length])) {
				//Find the next place this account name is located
				accountNameRange = [sourcePrivateKey rangeOfString:accountName
														   options:NSLiteralSearch
															 range:searchRange];

				if (accountNameRange.location != NSNotFound) {
					//Update our search range
					searchRange.location = NSMaxRange(accountNameRange);
					searchRange.length = [sourcePrivateKey length] - searchRange.location;

					//Make sure that this account name actually begins and finishes a name; otherwise (name TekJew2) matches (name TekJew)
					if ((![[sourcePrivateKey substringWithRange:NSMakeRange(accountNameRange.location - 6, 6)] isEqualToString:@"(name "] &&
						 ![[sourcePrivateKey substringWithRange:NSMakeRange(accountNameRange.location - 7, 7)] isEqualToString:@"(name \""]) ||
						(![[sourcePrivateKey substringWithRange:NSMakeRange(NSMaxRange(accountNameRange), 1)] isEqualToString:@")"] &&
						 ![[sourcePrivateKey substringWithRange:NSMakeRange(NSMaxRange(accountNameRange), 2)] isEqualToString:@"\")"])) {
						continue;
					}

					/* Within that range, find the next "(protocol " which encloses
						* a string of the form "(protocol protocol-name)"
						*/
					NSRange protocolRange = [sourcePrivateKey rangeOfString:@"(protocol "
																	options:NSLiteralSearch
																	  range:searchRange];
					if (protocolRange.location != NSNotFound) {
						//Update our search range
						searchRange.location = NSMaxRange(protocolRange);
						searchRange.length = [sourcePrivateKey length] - searchRange.location;

						NSRange nextClosingParen = [sourcePrivateKey rangeOfString:@")"
																		   options:NSLiteralSearch
																			 range:searchRange];
						NSRange protocolNameRange = NSMakeRange(NSMaxRange(protocolRange),
																nextClosingParen.location - NSMaxRange(protocolRange));
						NSString *protocolName = [sourcePrivateKey substringWithRange:protocolNameRange];
						//Remove a trailing quote if necessary
						if ([[protocolName substringFromIndex:([protocolName length]-1)] isEqualToString:@"\""]) {
							protocolName = [protocolName substringToIndex:([protocolName length]-1)];
						}

						NSString *uniqueServiceID = [prplDict objectForKey:protocolName];

						if ([account.service.serviceCodeUniqueID isEqualToString:uniqueServiceID]) {
							//Replace the protocol name first
							[sourcePrivateKey replaceCharactersInRange:protocolNameRange
															withString:uniqueServiceID];

							//Then replace the account name which was before it (so the range hasn't changed)
							if ([sourcePrivateKey characterAtIndex:(accountNameRange.location - 1)] == '\"') {
								accountNameRange.location -= 1;
								accountNameRange.length += 1;
							}
							
							if ([sourcePrivateKey characterAtIndex:(accountNameRange.location + accountNameRange.length + 1)] == '\"') {
								accountNameRange.length += 1;
							}
							
							[sourcePrivateKey replaceCharactersInRange:accountNameRange
															withString:accountInternalObjectID];
						}
					}
				}
				
				AILog(@"%@ - %@",accountName, sourcePrivateKey);
			}
		}			
	}
	
	return sourcePrivateKey;
}

- (void)upgradeOTRIfNeeded
{
	if (![[adium.preferenceController preferenceForKey:@"GaimOTR_to_AdiumOTR_Update"
												   group:@"OTR"] boolValue]) {
		NSString	  *destinationPath = [adium.loginController userDirectory];
		NSString	  *sourcePath = [destinationPath stringByAppendingPathComponent:@"libpurple"];
		
		NSString *privateKey = [self upgradedPrivateKeyFromFile:[sourcePath stringByAppendingPathComponent:@"otr.private_key"]];
		if (privateKey && [privateKey length]) {
			[privateKey writeToFile:[destinationPath stringByAppendingPathComponent:@"otr.private_key"]
						 atomically:NO
						   encoding:NSUTF8StringEncoding
							  error:NULL];
		}

		NSString *fingerprints = [self upgradedFingerprintsFromFile:[sourcePath stringByAppendingPathComponent:@"otr.fingerprints"]];
		if (fingerprints && [fingerprints length]) {
			[fingerprints writeToFile:[destinationPath stringByAppendingPathComponent:@"otr.fingerprints"]
						   atomically:NO
							 encoding:NSUTF8StringEncoding
								error:NULL];
		}

		[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
											 forKey:@"GaimOTR_to_AdiumOTR_Update"
											  group:@"OTR"];
	}
	
	if (![[adium.preferenceController preferenceForKey:@"Libgaim_to_Libpurple_Update"
												   group:@"OTR"] boolValue]) {
		NSString	*destinationPath = [adium.loginController userDirectory];
		
		NSString	*privateKeyPath = [destinationPath stringByAppendingPathComponent:@"otr.private_key"];
		NSString	*fingerprintsPath = [destinationPath stringByAppendingPathComponent:@"otr.fingerprints"];

		NSMutableString *privateKeys = [[NSString stringWithContentsOfUTF8File:privateKeyPath] mutableCopy];
		[privateKeys replaceOccurrencesOfString:@"libgaim"
									 withString:@"libpurple"
										options:NSLiteralSearch
										  range:NSMakeRange(0, [privateKeys length])];
		[privateKeys writeToFile:privateKeyPath
					  atomically:YES
						encoding:NSUTF8StringEncoding
						   error:NULL];
		[privateKeys release];

		NSMutableString *fingerprints = [[NSString stringWithContentsOfUTF8File:fingerprintsPath] mutableCopy];
		[fingerprints replaceOccurrencesOfString:@"libgaim"
									 withString:@"libpurple"
										options:NSLiteralSearch
										  range:NSMakeRange(0, [fingerprints length])];
		[fingerprints writeToFile:fingerprintsPath
					   atomically:YES
						 encoding:NSUTF8StringEncoding
							error:NULL];
		[fingerprints release];

		[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
											 forKey:@"Libgaim_to_Libpurple_Update"
											  group:@"OTR"];
	}
}

@end
