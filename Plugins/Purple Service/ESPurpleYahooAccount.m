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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import "ESPurpleYahooAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <libpurple/libymsg.h>
#import <libpurple/yahoo_friend.h>

@implementation ESPurpleYahooAccount

- (const char*)protocolPlugin
{
    return "prpl-yahoo";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_string(account, "room_list_locale", [[self preferenceForKey:KEY_YAHOO_ROOM_LIST_LOCALE
																		   group:GROUP_ACCOUNT_STATUS] UTF8String]);
	
	// We only have account proxies; use the account proxy for SSL connections.
	purple_account_set_bool(account, "proxy_ssl", TRUE);
}

- (NSString *)stringByRemovingYahooSuffix:(NSString *)inString
{
	if ((inString && ([inString length] > 0))) {
		//If inString contains @yahoo., we consider this to be an email address suffix such as @yahoo.com or @yahoo.it, and delete it and everything after it. Thus, jdoe@yahoo.com becomes simply jdoe.
		//However, we must leave other suffixes, such as sbcglobal.net, alone. We can't simply match @, or we would delete the @sbcglobal.net suffix and leave the user unable to connect with it.
		NSRange yahooRange = [inString rangeOfString:@"@yahoo." 
		                                     options:NSLiteralSearch];
		if (yahooRange.location != NSNotFound) {
			//Future expansion: Only delete if “@yahoo.” is followed by a known TLD and (if appropriate) 2LD, in order to support oddball suffixes such as “@yahoo.example.com”. I don't know whether any such suffixes exist. —boredzo
			inString = [inString substringToIndex:yahooRange.location];
		}
	}
	
	return inString;
}

/*!
* @brief The UID will be changed. The account has a chance to perform modifications
 *
 * Remove @yahoo.com from the proposedUID - a common mistake is to include it in the yahoo ID
 *
 * @param proposedUID The proposed, pre-filtered UID (filtered means it has no characters invalid for this servce)
 * @result The UID to use; the default implementation just returns proposedUID.
 */
- (NSString *)accountWillSetUID:(NSString *)proposedUID
{
	return [self stringByRemovingYahooSuffix:proposedUID];
}

/*!
 * @brief Name to use when creating a PurpleAccount for this CBPurpleAccount
 */
- (const char *)purpleAccountName
{
	return [[self stringByRemovingYahooSuffix:self.formattedUID] UTF8String];
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

/*!
 * @brief Should set aliases serverside?
 *
 * Yahoo supports serverside aliases.
 */
- (BOOL)shouldSetAliasesServerside
{
	return YES;
}

#pragma mark Connection
- (NSString *)connectionStringForStep:(NSInteger)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
	}
	return nil;
}

#pragma mark Encoding
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

/*!
 * @brief Status name to use for a Purple buddy
 */
- (NSString *)statusNameForPurpleBuddy:(PurpleBuddy *)buddy
{
	NSString		*statusName = nil;
	PurplePresence	*presence = purple_buddy_get_presence(buddy);
	PurpleStatus		*status = purple_presence_get_active_status(presence);
	const char		*purpleStatusID = purple_status_get_id(status);
	
	if (!purpleStatusID) return nil;
	
	if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_BRB)) {
		statusName = STATUS_NAME_BRB;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_BUSY)) {
		statusName = STATUS_NAME_BUSY;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_NOTATHOME)) {
		statusName = STATUS_NAME_NOT_AT_HOME;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_NOTATDESK)) {
		statusName = STATUS_NAME_NOT_AT_DESK;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_NOTINOFFICE)) {
		statusName = STATUS_NAME_NOT_IN_OFFICE;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_ONPHONE)) {
		statusName = STATUS_NAME_PHONE;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_ONVACATION)) {
		statusName = STATUS_NAME_VACATION;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_OUTTOLUNCH)) {
		statusName = STATUS_NAME_LUNCH;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_STEPPEDOUT)) {
		statusName = STATUS_NAME_STEPPED_OUT;
		
	} else if (!strcmp(purpleStatusID, YAHOO_STATUS_TYPE_INVISIBLE)) {
		statusName = STATUS_NAME_INVISIBLE;
	}
	
	return statusName;
}

/*!
 * @brief Update the status message and away state of the contact
 */
- (void)updateStatusForContact:(AIListContact *)theContact toStatusType:(NSNumber *)statusTypeNumber statusName:(NSString *)statusName statusMessage:(NSAttributedString *)inStatusMessage isMobile:(BOOL)isMobile
{
	NSString	*statusMessageString = [inStatusMessage string];
	char		*normalized = g_strdup(purple_normalize(account, [theContact.UID UTF8String]));
	YahooData	*od;
	YahooFriend	*f;

	/* Grab the idle time while we have a chance */
	if ((purple_account_is_connected(account)) &&
		(od = purple_account_get_connection(account)->proto_data) &&
		(f = g_hash_table_lookup(od->friends, normalized))) {

		if (f->status == YAHOO_STATUS_IDLE) {
			//Now idle
			NSInteger		idle = f->idle;
			NSDate	*idleSince;
			
			if (idle != -1) {
				idleSince = [NSDate dateWithTimeIntervalSinceNow:-idle];
			} else {
				idleSince = [NSDate date];
			}
			
			[theContact setValue:idleSince
								 forProperty:@"idleSince"
								 notify:NotifyLater];
			
		} else if (f->status == YAHOO_STATUS_INVISIBLE) {
			statusTypeNumber = [NSNumber numberWithInteger:AIInvisibleStatusType]; /* Invisible has a special status type */
		}
	}

	g_free(normalized);
	
	//Yahoo doesn't have an explicit mobile state; instead the status message is automatically set to indicate mobility.
	if (statusMessageString && ([statusMessageString isEqualToString:@"I'm on SMS"] ||
								([statusMessageString rangeOfString:@"I'm mobile"].location != NSNotFound))) {
		[theContact setIsMobile:YES notify:NotifyLater];

	} else if (theContact.isMobile) {
		[theContact setIsMobile:NO notify:NotifyLater];		
	}
	
	[super updateStatusForContact:theContact
					 toStatusType:statusTypeNumber
					   statusName:statusName
					statusMessage:inStatusMessage
						 isMobile:isMobile];
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
			statusID = YAHOO_STATUS_TYPE_AVAILABLE;
			break;

		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_BRB]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BRB]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_BRB;

			else if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_BUSY;

			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_HOME]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AT_HOME]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_NOTATHOME;

			else if (([statusName isEqualToString:STATUS_NAME_NOT_AT_DESK]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AT_DESK]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_NOTATDESK;
			
			else if (([statusName isEqualToString:STATUS_NAME_PHONE]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_PHONE]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_ONPHONE;
			
			else if (([statusName isEqualToString:STATUS_NAME_VACATION]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_VACATION]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_ONVACATION;
			
			else if (([statusName isEqualToString:STATUS_NAME_LUNCH]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_LUNCH]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_OUTTOLUNCH;
			
			else if (([statusName isEqualToString:STATUS_NAME_STEPPED_OUT]) ||
					 ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_STEPPED_OUT]] == NSOrderedSame))
				statusID = YAHOO_STATUS_TYPE_STEPPEDOUT;
			
			
			break;
		}
			
		case AIInvisibleStatusType:
			statusID = YAHOO_STATUS_TYPE_INVISIBLE;
			break;
		
		case AIOfflineStatusType:
			break;
	}
	
	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

- (BOOL)shouldAddMusicalNoteToNowPlayingStatus
{
	return NO;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (!strcmp(label, _("Add Buddy"))) {
		//We handle Add Buddy ourselves
		return nil;
		
	} else if (!strcmp(label, _("Join in Chat"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Join %@'s Chat",nil),inContact.formattedUID];

	} else if (!strcmp(label, _("Initiate Conference"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Initiate Conference with %@",nil), inContact.formattedUID];

	} else if (!strcmp(label, _("Presence Settings"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Presence Settings for %@",nil), inContact.formattedUID];

	} else if (!strcmp(label, _("Appear Online"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Appear Online to %@",nil), inContact.formattedUID];
		
	} else if (!strcmp(label, _("Appear Offline"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Appear Offline to %@",nil), inContact.formattedUID];
		
	} else if (!strcmp(label, _("Appear Permanently Offline"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Always Appear Offline to %@",nil), inContact.formattedUID];
		
	} else if (!strcmp(label, _("Don't Appear Permanently Offline"))) {
		return [NSString stringWithFormat:AILocalizedString(@"Don't Always Appear Offline to %@",nil), inContact.formattedUID];
		
	} else if (!strcmp(label, _("View Webcam"))) {
		//return [NSString stringWithFormat:AILocalizedString(@"View %@'s Webcam",nil), inContact.formattedUID];		
		return nil;

	} else if (!strcmp(label, _("Start Doodling"))) {
		return nil;
	}

	return [super titleForContactMenuLabel:label forContact:inContact];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* The Yahoo actions are "Activate ID" (or perhaps "Active ID," depending on where in the code you look)
	 * and "Join User in Chat...".  These are dumb. Additionally, Join User in Chat doesn't work as of purple 1.1.4. */
	return nil;
}

@end
