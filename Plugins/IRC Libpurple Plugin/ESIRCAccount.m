//
//  ESIRCAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESIRCAccount.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "SLPurpleCocoaAdapter.h"

@interface SLPurpleCocoaAdapter (PRIVATE)
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
	BOOL		didCommand = [[self purpleAdapter] attemptPurpleCommandOnMessage:[[inContentMessage message] string]
																	 fromAccount:(AIAccount *)[inContentMessage source]
																		  inChat:[inContentMessage chat]];	

	if (!didCommand) {
		/* If we're sending a message on an encryption chat (can this even happen on irc?), we can encode the HTML normally, as links will go through fine.
		 * If we're sending a message normally, IRC will drop the title of any link, so we preprocess it to be in the form "title (link)"
		 */
		encodedString = [AIHTMLDecoder encodeHTML:([[inContentMessage chat] isSecure] ? [inContentMessage message] : [[inContentMessage message] attributedStringByConvertingLinksToStrings])
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

- (const char *)purpleAccountName
{
	NSString	*myUID = [self formattedUID];
	BOOL		serverAppendedToUID  = ([myUID rangeOfString:@"@"].location != NSNotFound);

	return [(serverAppendedToUID ? myUID : [myUID stringByAppendingString:[self serverSuffix]]) UTF8String];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username([self purpleAccount], [self purpleAccountName]);
	
	BOOL useSSL = [[self preferenceForKey:KEY_IRC_USE_SSL group:GROUP_ACCOUNT_STATUS] boolValue];
	
	purple_account_set_bool([self purpleAccount], "ssl", useSSL);
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
	NSString	*host;
	NSString	*myUID = [self UID];

	int location = [myUID rangeOfString:@"@"].location;
	
	if ((location != NSNotFound) && (location + 1 < [myUID length])) {
		host = [myUID substringFromIndex:(location + 1)];
		
	} else {
		host = [self serverSuffix];
	}
	
	return host;
}

- (NSString *)displayName
{
	NSString *myUID = [self formattedUID];
	unsigned int pos = [myUID rangeOfString:@"@"].location;
	
	if(pos == NSNotFound)
		return myUID;
	return [myUID substringToIndex:pos];
}

- (NSString *)formattedUIDForListDisplay
{
	// on IRC, the nickname isn't that important for an account, the server is
	// (I guess the number of IRC users that use the same server with different nicks is very low)
	return [NSString stringWithFormat:@"%@ (%@)", [self host], [self displayName]];
}

- (BOOL)canSendOfflineMessageToContact:(AIListContact *)inContact
{
	return ([[[inContact UID] lowercaseString] isEqualToString:@"nickserv"] ||
			[[[inContact UID] lowercaseString] isEqualToString:@"chanserv"]);
}

- (BOOL)closeChat:(AIChat*)chat
{
	if([adium isQuitting])
		return NO;
	else
		return [super closeChat:chat];
}

@end
