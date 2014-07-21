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
#import "ESPurpleNovellAccount.h"
#import <Adium/AIStatus.h>

@implementation ESPurpleNovellAccount

gboolean purple_init_novell_plugin(void);
- (const char*)protocolPlugin
{
    return "prpl-novell";
}

#pragma mark Status
- (NSString *)connectionStringForStep:(NSInteger)step
{
	switch (step)
	{
		case 1:
			return AILocalizedString(@"Connecting",nil);
		case 2:
			return AILocalizedString(@"Authenticating",nil);
		case 3:
			return AILocalizedString(@"Waiting for Response",nil);
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
			break;
			
		case AIAwayStatusType:
			if (([statusName isEqualToString:STATUS_NAME_BUSY]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY]] == NSOrderedSame))
				statusID = "busy";
			break;

		case AIInvisibleStatusType:
			statusID = "appearoffline";
			break;

		case AIOfflineStatusType:
			break;
	}

	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

@end
