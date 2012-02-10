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

#import "ESPurpleMeanwhileAccount.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>

extern const char *mwServiceAware_getText(void *, void *);

@implementation ESPurpleMeanwhileAccount

#ifndef MEANWHILE_NOT_AVAILABLE

#define MW_KEY_FORCE       "force_login"
#define MW_KEY_FAKE_IT     "fake_client_id"
#define MW_KEY_CLIENT      "client_id_val"
#define MW_KEY_MAJOR       "client_major"
#define MW_KEY_MINOR       "client_minor"

- (const char*)protocolPlugin
{
    return "prpl-meanwhile";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	purple_prefs_set_int(MW_PRPL_OPT_BLIST_ACTION, Meanwhile_CL_Load_And_Save);
	purple_account_set_bool(account, MW_KEY_FORCE, [[self preferenceForKey:KEY_MEANWHILE_FORCE_LOGIN
																	group:GROUP_ACCOUNT_STATUS] boolValue]);
	
	BOOL fakeIt = [[self preferenceForKey:KEY_MEANWHILE_FAKE_CLIENT_ID
									group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, MW_KEY_FAKE_IT, fakeIt);
	if (fakeIt) {
		NSInteger client;
		if ((client = [[NSUserDefaults standardUserDefaults] integerForKey:@"AISametimeClient"])) {
			NSAssert( INT_MAX >= client,
							 @"client value larget than libpurple can handle.  Abort." );
			purple_account_set_int(account, MW_KEY_CLIENT, (int)client);
		}

		NSInteger majorVersion;
		if (!(majorVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"AISametimeMajorVersion"]))
			majorVersion = 0x001e;

		NSInteger minorVersion;
		if (!(minorVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"AISametimeMinorVersion"]))
			minorVersion = 0x196f;
		
		NSAssert( INT_MAX >= majorVersion,
						 @"majorVersion value larget than libpurple can handle.  Abort." );
		NSAssert( INT_MAX >= minorVersion,
						 @"minorVersion value larget than libpurple can handle.  Abort." );
		
		purple_account_set_int(account, MW_KEY_MAJOR, (int)majorVersion);
		purple_account_set_int(account, MW_KEY_MINOR, (int)minorVersion);
	}
}

#pragma mark Status Messages
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)b
{
	NSString				*statusMessageString;
	NSAttributedString		*buddyStatusMessage = nil;
	const char				*statusMessageText;
	PurpleConnection			*gc = purple_account_get_connection(purple_buddy_get_account(b));
	struct mwPurplePluginData	*pd = ((struct mwPurplePluginData *)(gc->proto_data));
	struct mwAwareIdBlock	t = { mwAware_USER,  (char *)purple_buddy_get_name(b), NULL };
	
	statusMessageText = (const char *)mwServiceAware_getText(pd->srvc_aware, &t);
	statusMessageString = (statusMessageText ? [NSString stringWithUTF8String:statusMessageText] : nil);

	if (statusMessageString && [statusMessageString length]) {
		buddyStatusMessage = [[[NSAttributedString alloc] initWithString:statusMessageString
														 attributes:nil] autorelease];
	}

	return buddyStatusMessage;
}

#pragma mark Status

- (NSString *)connectionStringForStep:(NSInteger)step
{
	switch (step)
	{
		case 1:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 2:
			return AILocalizedString(@"Sending Handshake",nil);
			break;
		case 3:
			return AILocalizedString(@"Waiting for Handshake Acknowledgement",nil);
			break;			
		case 4:
			return AILocalizedString(@"Handshake Acknowledged; Sending Login",nil);
			break;
		case 5:
			return AILocalizedString(@"Waiting for Login Acknowledgement",nil);
			break;
		case 6:
			return AILocalizedString(@"Login Redirected",nil);
			break;
		case 7:
			return AILocalizedString(@"Forcing Login",nil);
			break;
		case 8:
			return AILocalizedString(@"Login Acknowledged",nil);
			break;
		case 9:
			return AILocalizedString(@"Starting Services",nil);
			break;
		case 10:
			return AILocalizedString(@"Connected",nil);
			break;
	}
	
	return nil;
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
			statusID = "active";
			break;

		case AIAwayStatusType:
		case AIInvisibleStatusType: //Meanwhile does not support invisibility
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]] == NSOrderedSame))
				statusID = "dnd";
			else
				statusID = "away";
			break;
		}

		case AIOfflineStatusType:
			break;
	}
	
	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (strcmp(label, _("Import Sametime List...")) == 0) {
		return AILocalizedString(@"Import Sametime List...",nil);

	} else if (strcmp(label, _("Export Sametime List...")) == 0) {
		return AILocalizedString(@"Export Sametime List...",nil);
	}

	return [super titleForAccountActionMenuLabel:label];
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

#endif /* #ifndef MEANWHILE_NOT_AVAILABLE */
@end
