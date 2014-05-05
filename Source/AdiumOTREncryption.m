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

#import "ESOTRPreferences.h"
#import "ESOTRUnknownFingerprintController.h"
#import "OTRCommon.h"
#import "AIOTRSMPSecretAnswerWindowController.h"
#import "AIOTRSMPSharedSecretWindowController.h"
#import "AIOTRTopBarUnverifiedContactController.h"
#import "AIMessageViewController.h"

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
@end

@implementation AdiumOTREncryption

/* We'll only use the one OtrlUserState. */
static OtrlUserState		otrg_plugin_userstate = NULL;
static AdiumOTREncryption	*adiumOTREncryption = nil;
static OtrlMessageAppOps	ui_ops;

void send_default_query_to_chat(AIChat *inChat);
void disconnect_from_chat(AIChat *inChat);
void disconnect_from_context(ConnContext *context);
static OtrlMessageAppOps ui_ops;
TrustLevel otrg_plugin_context_to_trust(ConnContext *context);

#pragma mark Singleton management

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


#pragma mark Lookup functions between OTR contexts and accounts/chats

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
static NSDictionary*
details_for_context(ConnContext *context)
{
	if (!context) return nil;
	if (context->recent_child) context = context->recent_child;

	NSDictionary *securityDetailsDict;
	Fingerprint  *fprint = context->active_fingerprint;

    if (!fprint || !(fprint->fingerprint)) return nil;
	
    TrustLevel			level = otrg_plugin_context_to_trust(context);
	AIEncryptionStatus	encryptionStatus;
	AIAccount			*account;
	
	switch (level) {
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
	
    char our_hash[OTRL_PRIVKEY_FPRINT_HUMAN_LEN], their_hash[OTRL_PRIVKEY_FPRINT_HUMAN_LEN];

	otrl_privkey_fingerprint(otrg_get_userstate(), our_hash,
							 context->accountname, context->protocol);
	
    otrl_privkey_hash_to_human(their_hash, fprint->fingerprint);

	unsigned char *sessionid;
	BOOL sess1_outgoing = (context->sessionid_half == OTRL_SESSIONID_FIRST_HALF_BOLD);
    size_t idhalflen = (context->sessionid_len) / 2;
	
	NSMutableString *sess1, *sess2;
	sess1 = [[[NSMutableString alloc] initWithCapacity:21] autorelease];
	sess2 = [[[NSMutableString alloc] initWithCapacity:21] autorelease];

    /* Make a human-readable version of the sessionid (in two parts) */
    sessionid = context->sessionid;
	
	int i;
    for (i = 0; i < idhalflen; i++){
		[sess1 appendFormat:@"%02x", sessionid[i]];
		[sess2 appendFormat:@"%02x", sessionid[i+idhalflen]];
	}

	account = [adium.accountController accountWithInternalObjectID:[NSString stringWithUTF8String:context->accountname]];

	securityDetailsDict = @{ @"Their Fingerprint" : [NSString stringWithUTF8String:their_hash],
						  @"Our Fingerprint" : [NSString stringWithUTF8String:our_hash],
						  @"EncryptionStatus": @(encryptionStatus),
						  @"AIAccount" : account,
						  @"who": [NSString stringWithUTF8String:context->username],
						  (sess1_outgoing ? @"Outgoing SessionID" : @"Incoming SessionID"): sess1,
						  (sess1_outgoing ? @"Incoming SessionID" : @"Outgoing SessionID"): sess2 };
	
	AILog(@"Security details: %@", securityDetailsDict);
	
	return securityDetailsDict;
}


static AIAccount*
accountFromAccountID(const char *accountID)
{
	return [adium.accountController accountWithInternalObjectID:[NSString stringWithUTF8String:accountID]];
}

static AIService*
serviceFromServiceID(const char *serviceID)
{
	return [adium.accountController serviceWithUniqueID:[NSString stringWithUTF8String:serviceID]];
}

static AIListContact*
contactFromInfo(const char *accountID, const char *serviceID, const char *username)
{
	return [adium.contactController contactWithService:serviceFromServiceID(serviceID)
											   account:accountFromAccountID(accountID)
												   UID:[NSString stringWithUTF8String:username]];
}

static AIListContact*
contactForContext(ConnContext *context)
{
	return contactFromInfo(context->accountname, context->protocol, context->username);
}

static AIChat*
chatForContext(ConnContext *context)
{
	AIListContact *listContact = contactForContext(context);
	AIChat *chat = [adium.chatController existingChatWithContact:listContact];
	
	if (!chat) {
		chat = [adium.chatController chatWithContact:listContact];
	}
	
	return chat;
}


static OtrlPolicy
policyForContact(AIListContact *contact)
{
	OtrlPolicy policy = OTRL_POLICY_MANUAL_AND_RESPOND_TO_WHITESPACE;
	AIEncryptedChatPreference pref = contact.encryptedChatPreferences;
	
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
	
	return policy;
	
}

//Return the ConnContext for a Conversation, or NULL if none exists
static ConnContext*
contextForChat(AIChat *chat)
{
	AIAccount	*account;
    ConnContext *context;
	const char  *username, *accountname, *proto;

    /* Do nothing if this isn't an IM conversation */
    if (chat.isGroupChat) return NULL;
	
    account = chat.account;
	accountname = [account.internalObjectID UTF8String];
	proto = [account.service.serviceCodeUniqueID UTF8String];
    username = [chat.listObject.UID UTF8String];
	

	context = otrl_context_find(otrg_plugin_userstate,
							   username, accountname, proto, OTRL_INSTAG_MASTER, TRUE, NULL,
							   NULL, NULL);
	
	AILogWithSignature(@"%@ -> %p", chat, context);
	
	return context;
}

/* What level of trust do we have in the privacy of this ConnContext? */
TrustLevel
otrg_plugin_context_to_trust(ConnContext *context)
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

#pragma mark Implementations of the app ops

/* Return the OTR policy for the given context. */
static OtrlPolicy
policy_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	OtrlPolicy ret = policyForContact(contactForContext(context));
	
	[pool release];
	
	return ret;
}

/* Asynchronously generate a private key for the given accountname/protocol */
void
otrg_plugin_create_privkey(const char *accountname, const char *protocol)
{
	static BOOL alreadyGenerating = FALSE;
	static dispatch_queue_t keyGenerationQueue = NULL;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		keyGenerationQueue = dispatch_queue_create("im.adium.OTR.KeyGenerationQueue", NULL);
	});
	
	if (alreadyGenerating) {
		AILogWithSignature(@"A key generation is already running. Canceling");
		return;
	}
	
    /* Generate the key */
	void *newkeyp;
    otrl_privkey_generate_start(otrg_get_userstate(),
								accountname, protocol, &newkeyp);
	alreadyGenerating = TRUE;
	
	dispatch_async(keyGenerationQueue, ^{
		AILogWithSignature(@"Generating a new private key");
		otrl_privkey_generate_calculate(newkeyp);
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			otrl_privkey_generate_finish(otrg_get_userstate(), newkeyp, PRIVKEY_PATH);
			
			otrg_ui_update_keylist();
			
			AILogWithSignature(@"Done.");
			
			alreadyGenerating = FALSE;
		});
	});
}

/* Create a private key for the given accountname/protocol if
 * desired. */
static void
create_privkey_cb(void *opdata, const char *accountname, const char *protocol)
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
static int
is_logged_in_cb(void *opdata, const char *accountname, const char *protocol, const char *recipient)
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
static void
inject_message_cb(void *opdata, const char *accountname, const char *protocol, const char *recipient, const char *message)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[adium.contentController sendRawMessage:[NSString stringWithUTF8String:message]
								  toContact:contactFromInfo(accountname, protocol, recipient)];
	[pool release];
}

/* When the list of ConnContexts changes (including a change in
 * state), this is called so the UI can be updated. */
static void
update_context_list_cb(void *opdata)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	otrg_ui_update_keylist();
	
	[pool release];
}

/* Return a newly allocated string containing a human-friendly
 * representation for the given account */
static const char *
account_display_name_cb(void *opdata, const char *accountname, const char *protocol)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	const char *ret = strdup([[accountFromAccountID(accountname) formattedUID] UTF8String]);
	
	[pool release];
	
	return ret;
}

/* Deallocate a string returned by account_name */
static void
account_display_name_free_cb(void *opdata, const char *account_display_name)
{
	if (account_display_name)
		free((char *)account_display_name);
}


/* A new fingerprint for the given user has been received. */
static void
new_fingerprint_cb(void *opdata, OtrlUserState us, const char *accountname, const char *protocol, const char *username, unsigned char fingerprint[20])
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	ConnContext			*context;
	
	context = otrl_context_find(us, username, accountname,
								protocol, OTRL_INSTAG_RECENT, 0, NULL, NULL, NULL);
	
	if (context == NULL/* || context->msgstate != OTRL_MSGSTATE_ENCRYPTED*/) {
		NSLog(@"otrg_adium_dialog_unknown_fingerprint: Ack!");
		return;
	}
	
	[pool release];
}

/* The list of known fingerprints has changed.  Write them to disk. */
static void
write_fingerprints_cb(void *opdata)
{
	otrg_plugin_write_fingerprints();
}

/* A ConnContext has entered a secure state. Refresh the chat and the fingerprint list. */
static void
gone_secure_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    update_security_details_for_context(context);
	otrg_ui_update_fingerprint();
	
	[pool release];
}

/* A ConnContext has left a secure state. */
static void
gone_insecure_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    update_security_details_for_context(context);
	otrg_ui_update_fingerprint();
	
	[pool release];
}

/* We have completed an authentication, using the D-H keys we
 * already knew.  is_reply indicates whether we initiated the AKE. */
static void
still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (is_reply == 0) {
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
int
max_message_size_cb(void *opdata, ConnContext *context)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AIChat *chat = chatForContext(context);
	
	/* Values from https://otr.cypherpunks.ca/UPGRADING-libotr-3.1.0.txt */
	static NSDictionary *maxSizeByServiceClassDict = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		maxSizeByServiceClassDict = [@{ @"AIM-compatible": @(2343),
									 @"MSN" : @(1409),
									 @"Yahoo!" : @(832),
									 @"Gadu-Gadu": @(1999),
									 @"IRC" : @(417) } retain];
	});

	/* This will return 0 if we don't know (unknown protocol) or don't need it (Jabber),
	 * which will disable fragmentation.
	 */
	int ret = [[maxSizeByServiceClassDict objectForKey:chat.account.service.serviceClass] intValue];
	
	[pool release];
	
	return ret;
}

/* Create a string describing an error message event. */
static const char *
error_message_cb(void *opdata, ConnContext *context, OtrlErrorCode err_code)
{
	NSString *errorMessage = nil;
	
	switch (err_code) {
		case OTRL_ERRCODE_ENCRYPTION_ERROR:
			errorMessage = AILocalizedStringFromTableInBundle(@"An error occured while encrypting a message", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			break;
		case OTRL_ERRCODE_MSG_NOT_IN_PRIVATE:
			errorMessage = AILocalizedStringFromTableInBundle(@"Sent encrypted message to somebody who is not in a mutual OTR session", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			break;
		case OTRL_ERRCODE_MSG_UNREADABLE:
			errorMessage = AILocalizedStringFromTableInBundle(@"Sent an unreadable encrypted message", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			break;
		case OTRL_ERRCODE_MSG_MALFORMED:
			errorMessage = AILocalizedStringFromTableInBundle(@"Message sent is malformed", nil, [NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			break;
		default:
			return NULL;
	}
	
	const char *message_str = strdup([errorMessage UTF8String]);
	
	return message_str;
}

/* Free a string allocated by error_message_cb. */
static void
error_message_free_cb(void *opdata, const char *err_msg)
{
	if (err_msg) free((char *)err_msg);
}

/* Translate "[resent]" to the sender's own localization. */
static const char *
resent_msg_prefix_cb(void *opdata, ConnContext *context)
{
	const char *prefix_str = strdup([AILocalizedStringFromTableInBundle(@"[resent]", @"Prefix used by OTR for resent messages", [NSBundle bundleForClass:[AdiumOTREncryption class]], nil) UTF8String]);
	
	return prefix_str;
}

/* Free the string allocated by resent_msg_prefix_cb. */
static void
resent_msg_prefix_free_cb(void *opdata, const char *prefix)
{
	if (prefix) free((char *)prefix);
}

/* Create a timer for libotr to clean up. The timer doesn't need to be
 * exact, so we give it a 1 sec leeway. */
static void
timer_control_cb(void *opdata, unsigned int interval) {
	static dispatch_source_t timer = NULL;
	
	if (timer) {
		dispatch_source_cancel(timer);
		dispatch_release(timer);
		timer = NULL;
	}
	
	if (interval > 0) {
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		
		dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_SEC);
		
		dispatch_source_set_event_handler(timer, ^{
			otrl_message_poll(otrg_plugin_userstate, &ui_ops, opdata);
		});
		
		dispatch_resume(timer);
	}
}

static void
handle_msg_event_cb(void *opdata, OtrlMessageEvent msg_event, ConnContext *context, const char *message, gcry_error_t err)
{
	AILogWithSignature(@"Something happened in this conversation: %d %s", msg_event, message);
	
	AIListContact *listContact = contactForContext(context);
	AIChat *chat = chatForContext(context);
	
	switch (msg_event) {
		case OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED:
			if (!chat) chat = [adium.chatController chatWithContact:listContact];
			
			AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
																   withSource:listContact
																  destination:chat.account
																		 date:nil
																	  message:[AIHTMLDecoder decodeHTML:[AILocalizedStringFromTableInBundle(@"The following message was <b>not encrypted</b>: ",
																																			@"libotr error message",
																																			[NSBundle bundleForClass:[AdiumOTREncryption class]], nil)
																										 stringByAppendingString:[NSString stringWithUTF8String:message]]]
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
		case OTRL_MSGEVENT_RCVDMSG_UNRECOGNIZED:
		case OTRL_MSGEVENT_RCVDMSG_MALFORMED:
		case OTRL_MSGEVENT_RCVDMSG_NOT_IN_PRIVATE:
		case OTRL_MSGEVENT_RCVDMSG_UNREADABLE: {
			NSString *localizedMessage = [NSString stringWithFormat:AILocalizedStringFromTableInBundle(@"An encrypted message from %@ could not be decrypted.", @"libotr error message", [NSBundle bundleForClass:[AdiumOTREncryption class]], nil), listContact.UID];
			
			if (!chat) chat = [adium.chatController chatWithContact:listContact];
			[adium.contentController displayEvent:[[AIHTMLDecoder decodeHTML:localizedMessage] string]
										   ofType:@"encryption"
										   inChat:chat];
			break;
		}
		case OTRL_MSGEVENT_CONNECTION_ENDED: {
			NSString *localizedMessage = [NSString stringWithFormat:AILocalizedStringFromTableInBundle(@"Your message was not sent. %@ is no longer using encryption; you should cancel or refresh encryption on your side.",
																									   @"libotr error message", [NSBundle bundleForClass:[AdiumOTREncryption class]],
																									   @"Message when the remote contact cancels his half of an encrypted conversation. %@ will be a name."), listContact.UID];
			
			if (!chat) chat = [adium.chatController chatWithContact:listContact];

			[adium.contentController displayEvent:[[AIHTMLDecoder decodeHTML:localizedMessage] string]
										   ofType:@"encryption"
										   inChat:chat];
			break;
		}
		default:
			break;
	}
}


/* Create an instag for this account. */
void
create_instag_cb(void *opdata, const char *accountname, const char *protocol)
{
	otrl_instag_generate(otrg_plugin_userstate, INSTAG_PATH, accountname, protocol);
}

/* Something related to Socialist Millionaire Protocol happened. Handle it. */
static void
handle_smp_event_cb(void *opdata, OtrlSMPEvent smp_event, ConnContext *context, unsigned short progress_percent, char *question)
{
	AIListContact *listContact = contactForContext(context);
	
	AIChat *chat = chatForContext(context);
	if (!chat) chat = [adium.chatController chatWithContact:listContact];
	
	switch (smp_event) {
		case OTRL_SMPEVENT_ASK_FOR_ANSWER: {
			AIOTRSMPSecretAnswerWindowController *questionController = [[AIOTRSMPSecretAnswerWindowController alloc]
																		initWithQuestion:[NSString stringWithUTF8String:question]
																		from:listContact
																		completionHandler:^(NSData *answer,NSString *_question){
																			
																			if (context != contextForChat(chat)) {
																				AILogWithSignature(@"Something's wrong: %p != %p. Did the conversation close before you sent the secret question?", context, contextForChat(chat));
																				return;
																			}
																			
																			if(!answer) {
																				otrl_message_abort_smp(otrg_get_userstate(), &ui_ops, opdata, context);
																			} else
																				otrl_message_respond_smp(otrg_get_userstate(), &ui_ops, opdata, context, [answer bytes], [answer length]);
																		}
																		isInitiator:NO];
			
			[questionController showWindow:nil];
			[questionController.window orderFront:nil];
			
			[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedStringFromTableInBundle(@"%@ has sent you a secret question and is awaiting your answer to verify your identity.", nil,
																												[NSBundle bundleForClass:[AdiumOTREncryption class]], nil),
												   listContact.displayName]
										   ofType:@"encryption"
										   inChat:chat];
			
			break;
		}
		case OTRL_SMPEVENT_ASK_FOR_SECRET: {
			AIOTRSMPSharedSecretWindowController *questionController = [[AIOTRSMPSharedSecretWindowController alloc]
																		initFrom:listContact
																		completionHandler:^(NSData *answer){
																			
																			if (context != contextForChat(chat)) {
																				AILogWithSignature(@"Something's wrong: %p != %p. Did the conversation close before you sent the secret question?", context, contextForChat(chat));
																				return;
																			}
																			
																			otrl_message_respond_smp(otrg_get_userstate(), &ui_ops, opdata, context, [answer bytes], [answer length]);
																		}
																		isInitiator:NO];
			
			[questionController showWindow:nil];
			[questionController.window orderFront:nil];
			
			[adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedStringFromTableInBundle(@"%@ has requested to compare your shared secret to verify your identity.", nil,
																												[NSBundle bundleForClass:[AdiumOTREncryption class]], nil),
												   listContact.displayName]
										   ofType:@"encryption"
										   inChat:chat];
			
			break;
		}
		case OTRL_SMPEVENT_CHEATED:
		case OTRL_SMPEVENT_ERROR:
		case OTRL_SMPEVENT_FAILURE:
		case OTRL_SMPEVENT_ABORT: {
			NSString *localizedMessage = AILocalizedStringFromTableInBundle(@"The secret question was <b>not</b> answered correctly. You might be talking to an imposter.",
																			nil,
																			[NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			
			[adium.contentController displayEvent:localizedMessage
										   ofType:@"encryption"
										   inChat:chat];
			break;
		}
		case OTRL_SMPEVENT_SUCCESS: {
			NSString *localizedMessage = AILocalizedStringFromTableInBundle(@"The secret question was answered correctly.",
																			nil,
																			[NSBundle bundleForClass:[AdiumOTREncryption class]], nil);
			
			[adium.contentController displayEvent:localizedMessage
										   ofType:@"encryption"
										   inChat:chat];
			update_security_details_for_context(context);
			otrg_plugin_write_fingerprints();
			otrg_ui_update_keylist();
			break;
		}
			
		default:
			break;
	}
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
	handle_smp_event_cb,
	handle_msg_event_cb,
	create_instag_cb,
	NULL /* convert_msg */,
	NULL /* convert_free */,
	timer_control_cb,
};

#pragma mark Input/output of messages between Adium and libotr

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
		
    err = otrl_message_sending(otrg_plugin_userstate, &ui_ops, /* opData */ NULL,
							   accountname, protocol, username, OTRL_INSTAG_RECENT, originalMessage, /* tlvs */ NULL, &fullOutgoingMessage,
							   OTRL_FRAGMENT_SEND_ALL_BUT_LAST, NULL,
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

- (NSString *)decryptIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	NSString	*decryptedMessage = nil;
	const char *message = [inString UTF8String];
	char *newMessage = NULL;
    OtrlTLV *tlvs = NULL;
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

- (void)questionVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	ConnContext		*context = contextForChat(inChat);
	
	if (context->recent_child) context = context->recent_child;
	
	AIOTRSMPSecretAnswerWindowController *windowController = [[AIOTRSMPSecretAnswerWindowController alloc]
															  initWithQuestion:@""
															  from:inChat.listObject
															  completionHandler:^(NSData *answer, NSString *question) {
																  
																  if (context != contextForChat(inChat)) {
																	  AILogWithSignature(@"Something's wrong: %p != %p. Did the conversation close before you sent the secret question?", context, contextForChat(inChat));
																	  return;
																  }
																  
																  otrl_message_initiate_smp_q(otrg_get_userstate(),
																							  &ui_ops, NULL, context,
																							  (const char *)[question UTF8String],
																							  [answer bytes],
																							  [answer length]);
																  
																  [adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"You have asked %@ a secret question to verify their identity. Awaiting answer...", nil), inChat.listObject.displayName]
																								 ofType:@"encryption"
																								 inChat:inChat];
															  }
															  isInitiator:TRUE];
	
	[windowController showWindow:nil];
	[windowController.window orderFront:nil];
}

- (void)sharedVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	ConnContext		*context = contextForChat(inChat);
	
	if (context->recent_child) context = context->recent_child;
	
	AIOTRSMPSharedSecretWindowController *windowController = [[AIOTRSMPSharedSecretWindowController alloc]
															  initFrom:inChat.listObject
															  completionHandler:^(NSData *answer) {
																  
																  if (context != contextForChat(inChat)) {
																	  AILogWithSignature(@"Something's wrong: %p != %p. Did the conversation close before you sent the secret question?", context, contextForChat(inChat));
																	  return;
																  }
																  
																  otrl_message_initiate_smp(otrg_get_userstate(),
																							&ui_ops, NULL,
																							context,
																							[answer bytes],
																							[answer length]);
																  
																  [adium.contentController displayEvent:[NSString stringWithFormat:AILocalizedString(@"You have asked %@ to compare your shared secret to verify their identity. Awaiting answer...", nil), inChat.listObject.displayName]
																								 ofType:@"encryption"
																								 inChat:inChat];
	}
															  isInitiator:TRUE];
	
	[windowController showWindow:nil];
	[windowController.window orderFront:nil];
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
	AIChat *chat = [inNotification object];
	
	ConnContext *context = contextForChat(chat);
	
	if (context) update_security_details_for_context(context);
}

void update_security_details_for_context(ConnContext *context)
{
	AIChat *chat = chatForContext(context);
	
	[adiumOTREncryption setSecurityDetails:details_for_context(context)
								   forChat:chat];
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
		
		
		NSInteger oldEncryptionStatus = [[[inChat securityDetails] objectForKey:@"EncryptionStatus"] integerValue];
		
		[inChat setSecurityDetails:fullSecurityDetailsDict];
		
		NSInteger newEncryptionStatus = [[securityDetailsDict objectForKey:@"EncryptionStatus"] integerValue];
		

		if (newEncryptionStatus == EncryptionStatus_Unverified && oldEncryptionStatus != EncryptionStatus_Unverified) {
			AIOTRTopBarUnverifiedContactController *warningController = [[AIOTRTopBarUnverifiedContactController alloc] init];
			AIMessageViewController *mvc = [[inChat chatContainer] messageViewController];
			[mvc addTopBarController:warningController];
		}
	}
}

#pragma mark -

void
send_default_query_to_chat(AIChat *inChat)
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
void
disconnect_from_context(ConnContext *context)
{
    otrl_message_disconnect_all_instances(otrg_plugin_userstate, &ui_ops, NULL,
							context->accountname, context->protocol, context->username);
	gone_insecure_cb(NULL, context);
}

void
disconnect_from_chat(AIChat *inChat)
{
	disconnect_from_context(contextForChat(inChat));
}

#pragma mark -

/* Forget a fingerprint */
void
otrg_ui_forget_fingerprint(Fingerprint *fingerprint)
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

void
otrg_plugin_write_fingerprints(void)
{
    otrl_privkey_write_fingerprints(otrg_plugin_userstate, STORE_PATH);
	otrg_ui_update_fingerprint();
}

void
otrg_ui_update_keylist(void)
{
	[adiumOTREncryption prefsShouldUpdatePrivateKeyList];
}

void
otrg_ui_update_fingerprint(void)
{
	[adiumOTREncryption prefsShouldUpdateFingerprintsList];
}

OtrlUserState
otrg_get_userstate(void)
{
	return otrg_plugin_userstate;
}

#pragma mark -

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

@end
