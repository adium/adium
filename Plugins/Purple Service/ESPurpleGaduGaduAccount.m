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

#import "ESPurpleGaduGaduAccountViewController.h"
#import "ESPurpleGaduGaduAccount.h"
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <libpurple/gg.h>
#import <libpurple/buddylist.h>

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define MAX_GADU_STATUS_MESSAGE_LENGTH 70

@implementation ESPurpleGaduGaduAccount

- (const char*)protocolPlugin
{
    return "prpl-gg";
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Looking up server",nil);
			break;
		case 2:
			return AILocalizedString(@"Reading data","Connection step");
			break;			
		case 3:
			return AILocalizedString(@"Balancer handshake","Connection step");
			break;
		case 4:
			return AILocalizedString(@"Reading server key","Connection step");
			break;
		case 5:
			return AILocalizedString(@"Exchanging key hash","Connection step");
			break;
	}
	return nil;
}

- (void)uploadContactListToServer
{
	char *buddylist = ggp_buddylist_dump(account);
		
	if (buddylist) {
		PurpleConnection *gc = purple_account_get_connection(account);
		GGPInfo *info = gc->proto_data;
		
		AILog(@"Uploading gadu-gadu list...");
		
		gg_userlist_request(info->session, GG_USERLIST_PUT, buddylist);
		g_free(buddylist);
	}
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group
{
	[super moveListObjects:objects toGroup:group];
	
	[self uploadContactListToServer];
}

- (void)addContact:(AIListContact *)contact toGroup:(AIListGroup *)group
{
	[super addContact:contact toGroup:group];	
	
	[self uploadContactListToServer];
}

- (void)removeContacts:(NSArray *)objects
{
	[super removeContacts:objects];
	
	[self uploadContactListToServer];
}

- (void)downloadContactListFromServer
{
	//If we're connected and have no buddies, request 'em from the server.
	PurpleConnection *gc = purple_account_get_connection(account);
	GGPInfo *info = gc->proto_data;
	
	AILog(@"Requesting gadu-gadu list...");
	gg_userlist_request(info->session, GG_USERLIST_GET, NULL);	
}

- (void)accountConnectionConnected
{
	[self downloadContactListFromServer];

	[super accountConnectionConnected];
}

/*!
 * @brief Should offline messages be sent without prompting the user?
 *
 * Gadu-Gadu users make use of offline messaging heavily, possibly because of the prevelance of invisibile status usage.
 * The official client sends offline messages without prompting; we will, too.
 */
- (BOOL)sendOfflineMessagesWithoutPrompting
{
	return YES;
}

#pragma mark Status
/*!
 * @brief Encode an attributed string for a status type
 *
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	NSString	*messageString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];
	return [messageString stringWithEllipsisByTruncatingToLength:MAX_GADU_STATUS_MESSAGE_LENGTH];
}

- (BOOL)handleOfflineAsStatusChange
{
	return YES;
}

/*!
 * @brief Should we add a musical note when indicating a now playing status?
 * The note doesn't come out properly on Gadu-Gadu, presumably due to encoding issues.
 */
- (BOOL)shouldAddMusicalNoteToNowPlayingStatus
{
	return NO;
}

#pragma mark Menu Actions

- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	if (strcmp(label, _("Delete buddylist from Server")) == 0) return nil;

	return [super titleForAccountActionMenuLabel:label];
}

@end
