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

#import "ESIRCAccount.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "AIMessageViewController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <libpurple/irc.h>
#import <libpurple/cmds.h>
#import "SLPurpleCocoaAdapter.h"

@interface SLPurpleCocoaAdapter ()
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end

@interface ESIRCAccount()
- (void)sendRawCommand:(NSString *)command;
- (void)apply:(BOOL)apply operation:(NSString *)operation flag:(NSString *)flag;

- (void)op;
- (void)deop;
- (void)devoice;
- (void)kick;
- (void)ban;
- (void)bankick;
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

- (BOOL)shouldDisplayOutgoingMUCMessages
{
  return NO;
}

/*!
 * @brief Open the info inspector when getting info
 *
 * A user can /whois; we want to display info for this case.
 */
- (void)openInspectorForContactInfo:(AIListContact *)theContact
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIShowContactInfo" object:theContact];
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
	
	// Set a fake display name preference since we differ from global always.
	[self setPreference:[[NSAttributedString stringWithString:@"Adium"] dataRepresentation]
				 forKey:KEY_ACCOUNT_DISPLAY_NAME
				  group:GROUP_ACCOUNT_STATUS];
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
	NSString	*messageString = inContentMessage.message.string;
	BOOL		didCommand = [self.purpleAdapter attemptPurpleCommandOnMessage:messageString
																   fromAccount:(AIAccount *)inContentMessage.source
																	    inChat:inContentMessage.chat];
	
	BOOL hasSlashMe = ([messageString rangeOfString:@"/me " options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0);
	
	/* /say is a special case; it's not actually a command, but an instruction to display the following text (even if
	 * that text would normally be a command itself).
	 */
	BOOL hasSlashSay = ([messageString rangeOfString:@"/say " options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0);
	
	if (!didCommand || hasSlashMe) {
		if (hasSlashMe) {
			inContentMessage.sendContent = NO;
			if (inContentMessage.chat.isGroupChat) {
				inContentMessage.displayContent = NO;
			}
		}
		/* If we're sending a message on an encrypted direct msg, we can encode the HTML normally, as links will go through fine.
		 * However, in all other cases, IRC will drop the title of any link, so we preprocess it to be in the form "title (link)"
		 */
		NSAttributedString *messageAttributedString = inContentMessage.message;
		
		/* Remove the "/say" */
		if (hasSlashSay)
			messageAttributedString = [messageAttributedString attributedSubstringFromRange:NSMakeRange([@"/say " length], 
																										messageAttributedString.length - [@"/say " length])];
		
		encodedString = [AIHTMLDecoder encodeHTML:(inContentMessage.chat.isSecure ? 
												   messageAttributedString :
												   [messageAttributedString attributedStringByConvertingLinksToURLStrings])
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
	
	
	if (!didCommand && !hasSlashSay && [messageString hasPrefix:@"/"]) {
		// Try to send it to the server, if we don't know what it is; definitely don't display.
		[self sendRawCommand:[messageString substringFromIndex:1]];
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
	
	// Encoding
	NSString *encoding = [self preferenceForKey:KEY_IRC_ENCODING group:GROUP_ACCOUNT_STATUS] ?: @"UTF-8";
	purple_account_set_string(self.purpleAccount, "encoding", [encoding UTF8String]);
	
	if (![encoding isEqualToString:@"UTF-8"]) {
		purple_account_set_bool(self.purpleAccount, "autodetect_utf8", TRUE);
	}
	
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

/*!
 * @brief Should an autoreply be sent to this message?
 */
- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return NO;
}

#pragma mark Server contacts (NickServ, ChanServ)
/*!
 * @brief Sends a raw command to identify for the nickname
 */
- (void)identifyForName:(NSString *)name password:(NSString *)inPassword
{
	if ([self.host rangeOfString:@"quakenet" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[self sendRawCommand:[NSString stringWithFormat:@"PRIVMSG Q@CServe.quakenet.org :AUTH %@ %@", name, inPassword]];
	} else if ([self.host rangeOfString:@"undernet" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[self sendRawCommand:[NSString stringWithFormat:@"PRIVMSG X@channels.undernet.org :LOGIN %@ %@", name, inPassword]];
	} else if ([self.host rangeOfString:@"gamesurge" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		[self sendRawCommand:[NSString stringWithFormat:@"PRIVMSG AuthServ@Services.GameSurge.net :AUTH %@ %@", name, inPassword]];
	} else {
		[self sendRawCommand:[NSString stringWithFormat:@"NICKSERV identify %@", inPassword]];	
	}
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

/*!
 * @brief Our flags in a chat
 */
- (AIGroupChatFlags)flagsInChat:(AIChat *)chat
{
	NSString *ourUID = [NSString stringWithUTF8String:purple_normalize(self.purpleAccount, [self.displayName UTF8String])];
	
	// XXX Once we don't create a fake contact for ourself, we should do this the right way.
	return [chat flagsForContact:[self contactWithUID:ourUID]];
}

#pragma mark Action Menu
-(NSMenu*)actionMenuForChat:(AIChat*)chat
{
	NSMenu *menu;
	
	NSArray *listObjects = chat.chatContainer.messageViewController.selectedListObjects;
	AIListObject *listObject = nil;
	
	if (listObjects.count) {
		listObject = [listObjects objectAtIndex:0];
	}
	
	menu = [adium.menuController contextualMenuWithLocations:[NSArray arrayWithObjects:
															   [NSNumber numberWithInteger:Context_Contact_GroupChat_ParticipantAction],		
															   [NSNumber numberWithInteger:Context_Contact_Manage],
															   nil]
												forListObject:listObject
													   inChat:chat];
	
	
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:AILocalizedString(@"Op", nil)
					target:self
					action:@selector(op)
			 keyEquivalent:@""
					   tag:AIRequiresOp];
	
	[menu addItemWithTitle:AILocalizedString(@"Deop", nil)
					target:self
					action:@selector(deop)
			 keyEquivalent:@""
					   tag:AIRequiresOp];
	
	[menu addItemWithTitle:AILocalizedString(@"Voice", nil)
					target:self
					action:@selector(voice)
			 keyEquivalent:@""
					   tag:AIRequiresOp];
	
	[menu addItemWithTitle:AILocalizedString(@"Devoice", nil)
					target:self
					action:@selector(devoice)
			 keyEquivalent:@""
					   tag:AIRequiresOp];

	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:AILocalizedString(@"Kick", nil)
					target:self
					action:@selector(kick)
			 keyEquivalent:@""
					   tag:AIRequiresHalfop];
	
	[menu addItemWithTitle:AILocalizedString(@"Ban", nil)
					target:self
					action:@selector(ban)
			 keyEquivalent:@""
					   tag:AIRequiresHalfop];
	
	[menu addItemWithTitle:AILocalizedString(@"Bankick", nil)
					target:self
					action:@selector(bankick)
			 keyEquivalent:@""
					   tag:AIRequiresHalfop];
	
	return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIOperationRequirement req = (AIOperationRequirement)menuItem.tag;
	AIChat *chat = adium.interfaceController.activeChat;
	BOOL anySelected = chat.chatContainer.messageViewController.selectedListObjects.count > 0;
		
	AIGroupChatFlags flags = [self flagsInChat:chat];
	
	switch (req) {
		case AIRequiresHalfop:
			return (anySelected && ((flags & AIGroupChatOp) == AIGroupChatOp || (flags & AIGroupChatHalfOp) == AIGroupChatHalfOp));
			break;
			
		case AIRequiresOp:
			return (anySelected && ((flags & AIGroupChatOp) == AIGroupChatOp));
			break;
			
		case AIRequiresNoLevel:
			return anySelected;
			break;
			
		default:
			return YES;
			break;
	}
}

#pragma mark Action Menu's Actions
- (void)apply:(BOOL)apply operation:(NSString *)operation flag:(NSString *)flag
{
	AIChat *chat = adium.interfaceController.activeChat;
	NSArray *objects = chat.chatContainer.messageViewController.selectedListObjects;
	
	NSMutableString *names = [NSMutableString string];
	
	for (NSUInteger x = 0; x < objects.count; x++) {
		AIListObject *listObject = [objects objectAtIndex:x];
		
		if ([flag isEqualToString:@"b"] && [listObject valueForProperty:@"User Host"]) {
			[names appendString:[NSString stringWithFormat:@"*!%@", [listObject valueForProperty:@"User Host"]]];
		} else {
			[names appendString:listObject.UID];
		}
		
		[names appendString:@" "];
		
		if ((x+1) % 4 == 0 || x+1 == objects.count) {
			if ([operation isEqualToString:@"MODE"]) {
				[self sendRawCommand:[NSString stringWithFormat:@"MODE %@ %@%@ %@",
									  chat.name,
									  (apply ? @"+" : @"-"),
									  [@"" stringByPaddingToLength:(x + 1) % 4 ?: 4
														withString:flag 
												   startingAtIndex:0],
									  names]];
			} else if ([operation isEqualToString:@"KICK"]) {
				[self sendRawCommand:[NSString stringWithFormat:@"KICK %@ %@",
									  chat.name,
									  [names stringByReplacingOccurrencesOfString:@" " withString:@","]]];
			}
			
			[names setString:@""];
		}
	}
}

- (void)op
{
	[self apply:YES operation:@"MODE" flag:@"o"];
}

- (void)deop
{
	[self apply:NO operation:@"MODE" flag:@"o"];
}

- (void)voice
{
	[self apply:YES operation:@"MODE" flag:@"v"];
}

- (void)devoice
{
	[self apply:NO operation:@"MODE" flag:@"v"];
}

- (void)kick
{
	[self apply:NO operation:@"KICK" flag:nil];
}

- (void)ban
{
	[self apply:YES operation:@"MODE" flag:@"b"];
}

- (void)bankick
{
	[self ban];
	[self kick];
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

@end
