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

@interface SLPurpleCocoaAdapter ()
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end

/*
void purple_account_set_username(void *account, const char *username);
void purple_account_set_bool(void *account, const char *name,
						   BOOL value);
*/
@implementation ESIRCAccount

- (const char *)protocolPlugin
{
	return "prpl-irc";
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{

	NSString	*encodedString = nil;
	BOOL		didCommand = [self.purpleAdapter attemptPurpleCommandOnMessage:inContentMessage.message.string
																	 fromAccount:(AIAccount *)inContentMessage.source
																		  inChat:inContentMessage.chat];	

	if (!didCommand) {
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
	
	return encodedString;
}

- (NSString *)serverSuffix
{
	return @"irc.freenode.net";
}

- (NSString *)UID
{
	return [NSString stringWithFormat:@"%@@%@", self.formattedUID, self.host];
}

- (const char *)purpleAccountName
{
	return [self.UID UTF8String];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username(self.purpleAccount, self.purpleAccountName);
	
	BOOL useSSL = [[self preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	
	purple_account_set_bool(self.purpleAccount, "ssl", useSSL);
}

/*!
* @brief Connect Host
 *
 * Convenience method for retrieving the connect host for this account
 *
 * Rather than having a separate server field, IRC uses the servername after the user name.
 * username@server.org
 */
- (NSString *)host
{
	NSString *host = [self preferenceForKey:KEY_CONNECT_HOST group:GROUP_ACCOUNT_STATUS];
	if(!host)
		return self.serverSuffix;
	return host;
}

- (NSString *)displayName
{
	return self.formattedUID;
}

- (NSString *)formattedUIDForListDisplay
{
	// on IRC, the nickname isn't that important for an account, the server is
	// (I guess the number of IRC users that use the same server with different nicks is very low)
	return [NSString stringWithFormat:@"%@ (%@)", self.host, [self displayName]];
}

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

- (BOOL)shouldSendAutoreplyToMessage:(AIContentMessage *)message
{
	return !contactUIDIsServerContact(message.source.UID);
}

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

- (BOOL)closeChat:(AIChat*)chat
{
	if(adium.isQuitting)
		return NO;
	else
		return [super closeChat:chat];
}

@end
