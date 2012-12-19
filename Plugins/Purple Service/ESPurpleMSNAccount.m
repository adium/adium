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

#import "ESPurpleMSNAccount.h"

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <FriBidi/NSString-FBAdditions.h>

#import "SLPurpleCocoaAdapter.h"

#define DEFAULT_MSN_PASSPORT_DOMAIN				@"@hotmail.com"
#define SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES	10

@interface ESPurpleMSNAccount ()
- (void)updateFriendlyNameAfterConnect;
- (void)setServersideDisplayName:(NSString *)friendlyName;
- (void)gotFilteredFriendlyName:(NSAttributedString *)filteredFriendlyName context:(NSDictionary *)infoDict;
@end

@implementation ESPurpleMSNAccount

/*!
 * @brief The UID will be changed. The account has a chance to perform modifications
 *
 * For example, MSN adds @hotmail.com to the proposedUID and returns the new value
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	NSString	*correctUID;
	
	if (([proposedUID length] > 0) && 
	   ([proposedUID rangeOfString:@"@"].location == NSNotFound)) {
		correctUID = [proposedUID stringByAppendingString:DEFAULT_MSN_PASSPORT_DOMAIN];
	} else {
		correctUID = proposedUID;
	}
	
	return correctUID;
}

- (void)initAccount
{
	[super initAccount];
	lastFriendlyNameChange = nil;
}

- (const char*)protocolPlugin
{
	return "prpl-msn";
}

/*!
 * @brief Should set aliases serverside?
 *
 * MSN as of P15 supports serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	NSString	*encodedString;
	BOOL		didCommand = [[self purpleAdapter] attemptPurpleCommandOnMessage:inContentMessage.message.string
															  fromAccount:(AIAccount *)inContentMessage.source
																   inChat:inContentMessage.chat];	
	
	if (!didCommand) {
		/* If we're sending a message on an encryption chat, we can encode the HTML normally, as links will go through fine.
		 * If we're sending a message normally, MSN will drop the title of any link, so we preprocess it to be in the form "title (link)"
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
	} else {
		encodedString = nil;
	}

	if (encodedString) {
		/* If our message contains RTL string we shall surround it with a span tag
		 * with proper dir attribute so libpurple can apply the MSN writing direction
		 * flag. Note that we must check the string of the content message and not the
		 * one returned by our superclass as it appends its own html to the string.
		 * Only the content message can tell us the original direction.
		 */
		return (([[inContentMessage.message string] baseWritingDirection] == NSWritingDirectionRightToLeft)
				? [NSString stringWithFormat:@"<span dir=\"rtl\">%@</span>", encodedString]
				: encodedString);
	} else {
		return nil;
	}
}

#pragma mark Connection
- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	BOOL HTTPConnect = [[self preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "http_method", HTTPConnect);
	
	BOOL blockDirectConnections = [[self preferenceForKey:KEY_MSN_BLOCK_DIRECT_CONNECTIONS group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "direct_connect", !blockDirectConnections);
}

- (NSString *)connectionStringForStep:(NSInteger)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Handshaking",nil);
			break;			
		case 2:
			return AILocalizedString(@"Transferring",nil);
			break;
		case 3:
			return AILocalizedString(@"Handshaking",nil);
			break;
		case 4:
			return AILocalizedString(@"Starting authentication",nil);
			break;
		case 5:
			return AILocalizedString(@"Getting Cookie",nil);
			break;
		case 6:
			return AILocalizedString(@"Authenticating",nil);
			break;
		case 7:
			return AILocalizedString(@"Sending Cookie",nil);
			break;
		case 8:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
	}
	return nil;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [AIHTMLDecoder encodeHTML:inAttributedString
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

#pragma mark Status
//Update our full name on connect
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	
	[self updateFriendlyNameAfterConnect];
}	

/*!
 * @brief Update our friendly name to match the server friendly name if appropriate
 *
 * Well behaved MSN clients respect the serverside display name so that an update on one client is reflected on another.
 * 
 * If our display name is static and specified specifically for our account, we should update to the serverside one if they aren't the same.
 *
 * However, if our display name is dynamic, most likely we're looking at the filtered version of our dynamic
 * name, so we shouldn't update to the filtered one.  Furthermore, if our display name is set at the Aduim-global level,
 * we should use that name, not whatever is specified by the last client to connect.
 */
- (void)updateFriendlyNameAfterConnect
{
	const char			*displayName = NULL;
	
	if (account) {
		PurpleConnection	*purpleConnection = purple_account_get_connection(account);
		
		if (purpleConnection) {
			displayName = purple_connection_get_display_name(purpleConnection);
		}
	}
	
	NSAttributedString	*accountDisplayName = [[self preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
														   group:GROUP_ACCOUNT_STATUS] attributedString];
	
	NSAttributedString *globalPreference = [[adium.preferenceController preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME group:GROUP_ACCOUNT_STATUS] attributedString];
	BOOL				accountDisplayNameChanged = NO;
	BOOL				shouldUpdateDisplayNameImmediately= NO;

	/* If the friendly name changed since the last time we connected (the user changed it while offline)
	 * set it serverside and clear the flag.
	 */
	if ((accountDisplayName && (accountDisplayNameChanged = [[self preferenceForKey:KEY_MSN_DISPLAY_NAMED_CHANGED group:GROUP_ACCOUNT_STATUS] boolValue])) ||
		(!accountDisplayName && globalPreference)) {
		shouldUpdateDisplayNameImmediately = YES;

		if (accountDisplayNameChanged) {
			[self setPreference:nil
						 forKey:KEY_MSN_DISPLAY_NAMED_CHANGED
						  group:GROUP_ACCOUNT_STATUS];
		}

	} else {
		/* If our locally set friendly name didn't change since the last time we connected but one is set,
		 * we want to update to the serverside settings as appropriate.
		 *
		 * An important exception is if our per-account display name is dynamic (i.e. a 'Now Playing in iTunes' name).
		 *
		 * We explicitly ignore any display name starting with "<msnobj" because purple_connection_get_display_name() occassionaly (rarely)
		 * returns invalid data starting with that string.  The user can still set this as an MSN display name if she is really that weird, but
		 * we won't update to match other clients setting it.
		 */
		if (displayName &&
			strncmp(displayName, "<msnobj", 7) &&
			strcmp(displayName, [self.UID UTF8String]) &&
			strcmp(displayName, [self.formattedUID UTF8String])) {
			/* There is a serverside display name, and it's not the same as our UID. */
			const char			*accountDisplayNameUTF8String = [[accountDisplayName string] UTF8String];
			
			if (accountDisplayNameUTF8String &&
				strcmp(accountDisplayNameUTF8String, displayName)) {
				/* The display name is different from our per-account preference, which exists. Check if our preference is static.
				 * If the if() above got FALSE, we don't need to do anything; the serverside preference should stand as-is. */
				[adium.contentController filterAttributedString:accountDisplayName
												  usingFilterType:AIFilterContent
														direction:AIFilterOutgoing
													filterContext:self
												  notifyingTarget:self
														 selector:@selector(gotFilteredFriendlyName:context:)
														  context:[NSDictionary dictionaryWithObjectsAndKeys:
															  accountDisplayName, @"accountDisplayName",
															  [NSString stringWithUTF8String:displayName], @"displayName",
															  nil]];
			}

		} else {
			shouldUpdateDisplayNameImmediately = YES;
		}
	}
	
	if (shouldUpdateDisplayNameImmediately) {
		[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];
	}
}

- (void)gotFilteredFriendlyName:(NSAttributedString *)filteredFriendlyName context:(NSDictionary *)infoDict
{
	if ((!filteredFriendlyName && [infoDict objectForKey:@"displayName"]) ||
	   ([[filteredFriendlyName string] isEqualToString:[[infoDict objectForKey:@"accountDisplayName"] string]])) {
		/* Filtering made no changes to the string, so we're static. If we make it here, update to match the server. */
		NSAttributedString	*newPreference;

		newPreference = [[NSAttributedString alloc] initWithString:[infoDict objectForKey:@"displayName"]];

		[self setPreference:[newPreference dataRepresentation]
					 forKey:KEY_ACCOUNT_DISPLAY_NAME
					  group:GROUP_ACCOUNT_STATUS];

		[self updateStatusForKey:KEY_ACCOUNT_DISPLAY_NAME];

	} else {
		//Set it serverside
		[self setServersideDisplayName:[filteredFriendlyName string]];
	}
}

- (void)doQueuedSetServersideDisplayName
{
	[self setServersideDisplayName:queuedFriendlyName];
	queuedFriendlyName = nil;
}

- (void)setServersideDisplayName:(NSString *)friendlyName
{
	if (account && purple_account_is_connected(account)) {		
		NSDate *now = [NSDate date];

		if (!lastFriendlyNameChange ||
			[now timeIntervalSinceDate:lastFriendlyNameChange] > SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES) {

			//Don't allow newlines in the friendly name; convert them to slashes.
			NSMutableString		*noNewlinesFriendlyName = [friendlyName mutableCopy];
			[noNewlinesFriendlyName convertNewlinesToSlashes];
			friendlyName = noNewlinesFriendlyName;

			/*
			 * The MSN display name will be URL encoded via purple_url_encode().  The maximum length of the _encoded_ string is
			 * BUDDY_ALIAS_MAXLEN (387 characters as of purple 2.7.5). We can't simply encode and truncate as we might end up with
			 * part of an encoded character being cut off, so we instead truncate to smaller and smaller strings and encode, until it fits
			 */
			#define BUDDY_ALIAS_MAXLEN 387
			const char *friendlyNameUTF8String = [friendlyName UTF8String];
			NSInteger currentMaxNumberOfPreEncodedCharacters = BUDDY_ALIAS_MAXLEN;

			while (friendlyNameUTF8String &&
				   strlen(purple_url_encode(friendlyNameUTF8String)) > BUDDY_ALIAS_MAXLEN) {
				AILog(@"Shortening because %s (max len %li) [%s] len (%zi) > %i",
					  friendlyNameUTF8String, currentMaxNumberOfPreEncodedCharacters,
					  purple_url_encode(friendlyNameUTF8String),strlen(purple_url_encode(friendlyNameUTF8String)),
					  BUDDY_ALIAS_MAXLEN);
				friendlyName = [noNewlinesFriendlyName stringWithEllipsisByTruncatingToLength:currentMaxNumberOfPreEncodedCharacters];				
				friendlyNameUTF8String = [friendlyName UTF8String];
				currentMaxNumberOfPreEncodedCharacters -= 10;
			}

            purple_account_set_alias(account, friendlyNameUTF8String);
            purple_account_set_public_alias(account, friendlyNameUTF8String, NULL, NULL);

			lastFriendlyNameChange = now;

		} else {
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(doQueuedSetServersideDisplayName)
													   object:nil];
			if (queuedFriendlyName != friendlyName) {
				queuedFriendlyName = friendlyName;
			}
			[self performSelector:@selector(doQueuedSetServersideDisplayName)
					   withObject:nil
					   afterDelay:(SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES - [now timeIntervalSinceDate:lastFriendlyNameChange])];

			AILog(@"%@: Queueing serverside display name change to %@ for %0f seconds", self, queuedFriendlyName, (SECONDS_BETWEEN_FRIENDLY_NAME_CHANGES - [now timeIntervalSinceDate:lastFriendlyNameChange]));
		}
	}
}

/*!
 * @brief Set our serverside 'friendly name'
 *
 * There is a rate limit on how quickly we can set our friendly name.
 *
 * @param attributedFriendlyName The new friendly name.  This is used as plaintext; it is an NSAttributedString for generic useage with the autoupdating filtering system.
 *
 */
- (void)gotFilteredDisplayName:(NSAttributedString *)attributedDisplayName
{
	NSString	*friendlyName = [attributedDisplayName string];
	AILog(@"%@: gotFilteredDisplayName: %@ (I am currently %@)",self,friendlyName,[self currentDisplayName]);

	if (!friendlyName || ![friendlyName isEqualToString:[self currentDisplayName]]) {		
		[self setServersideDisplayName:friendlyName];
	}
	
	[super gotFilteredDisplayName:attributedDisplayName];
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

#pragma mark Status messages

- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	NSString		*statusName = nil;
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = purple_presence_get_active_status(presence);
	const char		*purpleStatusID = purple_status_get_id(status);

	if (!purpleStatusID) return nil;

	if (!strcmp(purpleStatusID, "brb")) {
		statusName = STATUS_NAME_BRB;
		
	} else if (!strcmp(purpleStatusID, "busy")) {
		statusName = STATUS_NAME_BUSY;
		
	} else if (!strcmp(purpleStatusID, "phone")) {
		statusName = STATUS_NAME_PHONE;
		
	} else if (!strcmp(purpleStatusID, "lunch")) {
		statusName = STATUS_NAME_LUNCH;
		
	} else if (!strcmp(purpleStatusID, "invisible")) {
		statusName = STATUS_NAME_INVISIBLE;		
	}
	
	return statusName;
}

/*!
 * @brief Should a status message be set when using the default "Away" state?
 */
- (BOOL)shouldSetStatusMessageForDefaultAwayState
{
	return NO;
}

/*!
 * @brief Return the purple status ID to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * statusState.statusType for a general idea of the status's type.
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
	NSString		*statusName = statusState.statusName;
	NSString		*statusMessageString = [statusState statusMessageString];

	if (!statusMessageString) statusMessageString = @"";

	switch (statusState.statusType) {
		case AIAvailableStatusType:
			break;

		case AIAwayStatusType:
			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BRB]] == NSOrderedSame))
				statusID = "brb";
			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY]] == NSOrderedSame))
				statusID = "busy";
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_PHONE]] == NSOrderedSame))
				statusID = "phone";
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_LUNCH]] == NSOrderedSame))
				statusID = "lunch";

			break;
			
		case AIInvisibleStatusType:
		case AIOfflineStatusType:
			break;
	}
	
	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];

	return statusID;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, _("Send to Mobile")) == 0) {
		return [NSString stringWithFormat:AILocalizedString(@"Send to %@'s Mobile",nil),inContact.formattedUID];
	}
	
	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{	
	if (strcmp(label, _("Set Friendly Name...")) == 0) {
		/* Don't include the Set Friendly Name action since we have our own UI for this */
		return nil;

	} else if (strcmp(label, _("Set Home Phone Number...")) == 0) {
		return [AILocalizedString(@"Set Home Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, _("Set Work Phone Number...")) == 0) {
		return [AILocalizedString(@"Set Work Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, _("Set Mobile Phone Number...")) == 0) {
		return [AILocalizedString(@"Set Mobile Phone Number",nil) stringByAppendingEllipsis];
		
	} else if (strcmp(label, _("Allow/Disallow Mobile Pages...")) == 0) {
		return [AILocalizedString(@"Allow/Disallow Mobile Pages","Action menu item for MSN accounts to toggle whether Mobile pages [forwarding messages to a mobile device] are enabled") stringByAppendingEllipsis];

	}

	return [super titleForAccountActionMenuLabel:label];
}

@end

