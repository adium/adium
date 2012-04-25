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

#import "ESPurpleZephyrAccountViewController.h"
#import "ESPurpleZephyrAccount.h"
#import <Adium/AIStatus.h>
#import <Adium/AIListContact.h>

#define ZHM_NAME @"zhm"

@implementation ESPurpleZephyrAccount

gboolean purple_init_zephyr_plugin(void);
- (const char*)protocolPlugin
{
    return "prpl-zephyr";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	NSString	*exposure_level, *encoding;
	BOOL		write_anyone, write_zsubs;
	
	write_anyone = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_ANYONE group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "write_anyone", write_anyone);

	write_zsubs = [[self preferenceForKey:KEY_ZEPHYR_EXPORT_SUBS group:GROUP_ACCOUNT_STATUS] boolValue];
	purple_account_set_bool(account, "write_zsubs", write_zsubs);
	
	exposure_level = [self preferenceForKey:KEY_ZEPHYR_EXPOSURE group:GROUP_ACCOUNT_STATUS];
	purple_account_set_string(account, "exposure_level", [exposure_level UTF8String]);

	encoding = [self preferenceForKey:KEY_ZEPHYR_ENCODING group:GROUP_ACCOUNT_STATUS];
	purple_account_set_string(account, "encoding", [encoding UTF8String]);
}

//Zephyr connects to a local host so need not disconnect/reconnect as the network changes
- (BOOL)connectivityBasedOnNetworkReachability
{
	return NO;
}

// Improve the formatting of displayed names in zephyr group chats (classes).
- (AIListContact *)contactWithUID:(NSString *)sourceUID
{
	AIListContact *contact = [super contactWithUID:sourceUID];

	NSRange firstSpace = [sourceUID rangeOfString:@" "];
	if (firstSpace.location != NSNotFound) {
		// sourceUID is of the form "username instance".
		// Set the displayName of contact to "realname / instance",
		// where realname is the displayName of the contact with UID "username".
		// Also convert the instance to all lowercase, like owl does.
		NSString *username = [sourceUID substringToIndex:firstSpace.location];
		NSString *realname = [[adium.contactController contactWithService:service account:self UID:username] displayName];
		NSString *instance = [[sourceUID substringFromIndex:(firstSpace.location+1)] lowercaseString];
		NSString *display = [NSString stringWithFormat:@"%@ / %@", realname, instance];
		[contact setDisplayName:display];
	}
	
	return contact;
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

	switch (statusState.statusType) {
		case AIAvailableStatusType:
			break;
		case AIInvisibleStatusType:
			statusID = "hidden";
			break;
		case AIAwayStatusType:
		case AIOfflineStatusType:
			break;
	}

	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];

	return statusID;
}

/*!
 * @brief Kill any currently-running instances of the zhm program.
 *
 * Since we kill zhms that we didn't run, we're a slightly bad citizen.  However, this only gets called
 * if the use internal host manager option is enabled, and there's no good way for multiple host
 * managers to be running on the same machine.
 *
 * If no zhm is running, just return.
 */
- (void)killHostManagerInstances
{
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObject:ZHM_NAME]] waitUntilExit];
    // We assume that killall worked...
}

/*!
 * @brief Make sure zhm is started when connecting a zephyr account
 *
 * Because of the way Zephyr works, we can't support multiple zephyr accounts on different servers
 * (without reimplimenting zhm).  We fail and show an error box in the case that zhm is already
 * running.  Theoretically, if zhm is already running, but on the right servers, we could share
 * the zhm instance, but currently we have no good way of detecting whether that is the case.
 */
- (void)connect
{
    if ([[self preferenceForKey:KEY_ZEPHYR_LAUNCH_ZHM group:GROUP_ACCOUNT_STATUS] boolValue]) {
        //Start zhm
        NSTask		 *zhm = [[NSTask alloc] init];
        NSPipe		 *newPipe = [NSPipe pipe];
        NSFileHandle *readHandle = [newPipe fileHandleForReading];
        NSData		 *inData;

        [zhm setLaunchPath:[[NSBundle bundleForClass:[ESPurpleZephyrAccount class]] pathForResource:ZHM_NAME ofType:nil]];
        [zhm setArguments:[self preferenceForKey:KEY_ZEPHYR_SERVERS group:GROUP_ACCOUNT_STATUS]];
        [zhm setStandardOutput:newPipe];
        [zhm setStandardError:newPipe];
        [zhm launch];
        inData = [readHandle readDataToEndOfFile];
        [zhm waitUntilExit];

        NSInteger status = [zhm terminationStatus];
        if (status != 0 && status != -1) { 
			//zhm returned an error (why is -1 also not an error???)
            NSString *tempString = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];

            NSRunCriticalAlertPanel(AILocalizedString(@"zhm Failure", "zhm is the Zephyr Host Manager and should not be a localized word"),
									AILocalizedString(@"The Zephyr Host Manager reported an error #%d: %@", "Be careful to keep the % parts the same in this string. %@ will be replaced by an error message."),
                                    AILocalizedString(@"OK", nil), nil, nil, status, tempString);

            //Should we stop here, or keep going, knowing we'll get another error message when we try to connect via libpurple?
        }
    }

    // Actually connect
	[super connect];
}

/*!
 * @brief When we have disconnected, kill our zhm process (if we started one).
 */
- (void)didDisconnect
{
    /* Only kill zhm if we launched zhm.  Never mess with zhm otherwise.
     * If someone changed this preference while we were connected, we'll kill their zhm instance.
     * However, that's not much of a problem.
     */
    if ([[self preferenceForKey:KEY_ZEPHYR_LAUNCH_ZHM group:GROUP_ACCOUNT_STATUS] boolValue])
        [self killHostManagerInstances];

    [super didDisconnect];
}

@end
