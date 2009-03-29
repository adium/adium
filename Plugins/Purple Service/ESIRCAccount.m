//
//  ESIRCAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESIRCAccount.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "SLPurpleCocoaAdapter.h"
#import <Adium/AIListContact.h>
#import <libpurple/irc.h>
#import <libpurple/cmds.h>

@interface SLPurpleCocoaAdapter ()
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end

@interface ESIRCAccount()
- (void)sendRawCommand:(NSString *)command;
@end

static PurpleConversation *fakeConversation(PurpleAccount *account);

@implementation ESIRCAccount

/*!
 * @brief Our explicit formatted UID contains our hostname, so we can differentiate ourself.
 */
- (NSString *)explicitFormattedUID
{
	if (self.host) {
		return [NSString stringWithFormat:@"%@ (%@)", self.host, self.displayName];
	} else {
		return self.displayName;
	}
}

#pragma mark IRC-ism overloads

/*!
 * @brief We always want to autocomplete the UID.
 */
- (BOOL)chatShouldAutocompleteUID:(AIChat *)inChat
{
	return YES;
}

/*!
 * @brief Use the object ID for password name
 *
 * We mess around a lot with the UID. This lets it actually save right.
 */
- (BOOL)useInternalObjectIDForPasswordName
{
	return YES;
}

- (BOOL)openChat:(AIChat *)chat
{
	chat.hideUserIconAndStatus = YES;
	
	return [super openChat:chat];
}

#pragma mark Command handling
/*!
 * @brief We've connected
 *
 * Send the commands the user wants sent when we do so. Creates a fake conversation to pipe them through.
 */
- (void)didConnect
{
	[super didConnect];
	
	PurpleConversation *conv = fakeConversation(self.purpleAccount);
	
	for (NSString *command in [[self preferenceForKey:KEY_IRC_COMMANDS
												group:GROUP_ACCOUNT_STATUS] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
		if ([command hasPrefix:@"/"]) {
			command = [command substringFromIndex:1];
		}
		
		command = [command stringByReplacingOccurrencesOfString:@"$me" withString:self.displayName];
		
		if (command.length) {
			char *error;
			PurpleCmdStatus cmdStatus = purple_cmd_do_command(conv, [command UTF8String], [command UTF8String], &error);
			
			if (cmdStatus == PURPLE_CMD_STATUS_NOT_FOUND) {
				// If it's not found, send it as a raw command like we do in chats.
				[self sendRawCommand:command];
			} else if (cmdStatus != PURPLE_CMD_STATUS_OK) {
				// The command failed with something other than "not found" - log it.
				AILogWithSignature(@"Command (%@) failed: %d - %@", command, cmdStatus, [NSString stringWithUTF8String:error]);
			}
		}
	}
	
	// The fakeConversation was allocated; now free it.
	g_free(conv);
}

/*!
 * @brief Send a raw command to the IRC server.
 */
- (void)sendRawCommand:(NSString *)command
{
	PurpleConnection *connection = purple_account_get_connection(account);
	
	if (!connection)
		return;
	
	const char *quote = [command UTF8String];
	irc_cmd_quote(connection->proto_data, NULL, NULL, &quote);	
}

/*!
 * @brief This creates a fake PurpleConversation
 *
 * This fake conversation is used for sending purple_cmd_do_command() messages, which requires
 * a conversation for the command to occur. Free this when finished.
 *
 * This is taken from irchelper.c, the pidgin plugin.
 */
static PurpleConversation *fakeConversation(PurpleAccount *account)
{
	PurpleConversation *conv;
	
	conv = g_new0(PurpleConversation, 1);
	conv->type = PURPLE_CONV_TYPE_IM;
	/* If we use this then the conversation updated signal is fired and
	 * other plugins might start doing things to our conversation, such as
	 * setting data on it which we would then need to free etc. It's easier
	 * just to be more hacky by setting account directly. */
	/* purple_conversation_set_account(conv, account); */
	conv->account = account;
	
	return conv;
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{

	NSString	*encodedString = nil;
	BOOL		didCommand = [self.purpleAdapter attemptPurpleCommandOnMessage:inContentMessage.message.string
																   fromAccount:(AIAccount *)inContentMessage.source
																	    inChat:inContentMessage.chat];
	
	NSRange meRange = [inContentMessage.message.string rangeOfString:@"/me " options:NSCaseInsensitiveSearch];

	if (!didCommand || meRange.location == 0) {
		if (meRange.location == 0) {
			inContentMessage.sendContent = NO;
		}
		/* If we're sending a message on an encryption chat (can this even happen on irc?), we can encode the HTML normally, as links will go through fine.
		 * If we're sending a message normally, IRC will drop the title of any link, so we preprocess it to be in the form "title (link)"
		 */
		encodedString = [AIHTMLDecoder encodeHTML:(inContentMessage.chat.isSecure ? inContentMessage.message : [inContentMessage.message attributedStringByConvertingLinksToStrings])
										  headers:NO
										 fontTags:YES
							   includingColorTags:YES
									closeFontTags:YES
										styleTags:YES
					   closeStyleTagsOnFontChange:YES
								   encodeNonASCII:NO
									 encodeSpaces:NO
									   imagesPath:nil
								attachmentsAsText:YES
						onlyIncludeOutgoingImages:NO
								   simpleTagsOnly:YES
								   bodyBackground:NO
							  allowJavascriptURLs:YES];
	}
	
	if (!didCommand && [inContentMessage.message.string hasPrefix:@"/"]) {
		// Try to send it to the server, if we don't know what it is; definitely don't display.
		[self sendRawCommand:[inContentMessage.message.string substringFromIndex:1]];
		return nil;
	} else {
		return encodedString;
	}
}

#pragma mark Libpurple
- (const char *)protocolPlugin
{
	return "prpl-irc";
}

- (const char *)purpleAccountName
{
	return [[NSString stringWithFormat:@"%@@%@", self.formattedUID, self.host] UTF8String];
}

- (NSString *)defaultUsername
{
	return @"Adium";
}

- (NSString *)defaultRealname
{
	return AILocalizedString(@"Adium User", nil);
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username(self.purpleAccount, self.purpleAccountName);
	
	// Use SSL
	BOOL useSSL = [[self preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(self.purpleAccount, "ssl", useSSL);
	
	// Username (for connecting)
	NSString *username = [self preferenceForKey:KEY_IRC_USERNAME group:GROUP_ACCOUNT_STATUS] ?: self.defaultUsername;
	purple_account_set_string(self.purpleAccount, "username", [username UTF8String]);
	
	// Realname (for connecting)
	NSString *realname = [self preferenceForKey:KEY_IRC_REALNAME group:GROUP_ACCOUNT_STATUS] ?: self.defaultRealname;
	purple_account_set_string(self.purpleAccount, "realname", [realname UTF8String]);
}

/*!
 * @brief Our display name; either retrieve our current nickname, or return our stored one.
 */
- (NSString *)displayName
{
	// Try and get the purple display name, since it changes without telling us.
	if (account) {
		PurpleConnection	*purpleConnection = purple_account_get_connection(account);
		
		if (purpleConnection) {
			return [NSString stringWithUTF8String:purple_connection_get_display_name(purpleConnection)];
		}
	}
	
	return self.formattedUID;
}


/*!
 * @brief Re-create the chat's join options.
 */
- (NSDictionary *)extractChatCreationDictionaryFromConversation:(PurpleConversation *)conv
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSString stringWithUTF8String:purple_conversation_get_name(conv)] forKey:@"channel"];
	const char *pass = purple_conversation_get_data(conv, "password");
	if (pass)
		[dict setObject: [NSString stringWithUTF8String:pass] forKey:@"password"];
	
	return dict;
}

#pragma mark Server contacts (NickServ, ChanServ)
/*!
 * @brief Sends a raw command to identify for the nickname
 */
- (void)identifyForNickServName:(NSString *)name password:(NSString *)inPassword
{
	[self sendRawCommand:[NSString stringWithFormat:@"NICKSERV identify %@ %@", name, inPassword]];
}

/*!
 * @brief Is this contact a server contact?
 */
BOOL contactUIDIsServerContact(NSString *contactUID)
{
	return (([contactUID caseInsensitiveCompare:@"nickserv"] == NSOrderedSame) ||
			([contactUID caseInsensitiveCompare:@"chanserv"] == NSOrderedSame) ||
			([contactUID rangeOfString:@"-connect" options:(NSBackwardsSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound));
}

/*!
 * @brief Can we send an offline message to this contact?
 *
 * We can only send offline messages to the server contacts, since such a message might cause us to connect
 */
- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return contactUIDIsServerContact(inContact.UID);
}

/*!
 * @brief Don't autoreply to server contacts (services) or FreeNode's stupidity.
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return !contactUIDIsServerContact(message.source.UID);
}

/*!
 * @brief Don't log server contacts (services) or FreeNode's stupidity.
 */
- (BOOL)shouldLogChat:(AIChat *)chat
{
	NSString *source = chat.listObject.UID;
	BOOL shouldLog = YES;
	
	if (source && (([source caseInsensitiveCompare:@"nickserv"] == NSOrderedSame) ||
				   ([source caseInsensitiveCompare:@"chanserv"] == NSOrderedSame) ||
				   ([source rangeOfString:@"-connect" options:(NSBackwardsSearch | NSCaseInsensitiveSearch | NSAnchoredSearch)].location != NSNotFound))) {
		shouldLog = NO;	
	}

	return (shouldLog && [super shouldLogChat:chat]);
}

#pragma mark Chat handling

/*!
 * @brief Allow the chat to close unless we're quitting.
 */
- (BOOL)closeChat:(AIChat*)chat
{
	if(adium.isQuitting)
		return NO;
	else
		return [super closeChat:chat];
}

/*!
 * @brief Do group chats support topics?
 */
- (BOOL)groupChatsSupportTopic
{
	return YES;
}

@end
