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

#import <Adium/AIStatusControllerProtocol.h>
#import "DCPurpleMeanwhileJoinChatViewController.h"
#import "ESPurpleMeanwhileAccount.h"
#import "ESPurpleMeanwhileAccountViewController.h"
#import "ESMeanwhileService.h"
#import <AIUtilities/AICharacterSetAdditions.h>

@implementation ESMeanwhileService

//Account Creation
- (Class)accountClass{
	return [ESPurpleMeanwhileAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESPurpleMeanwhileAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
	return [DCPurpleMeanwhileJoinChatViewController joinChatView];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"libpurple-Sametime";
}
- (NSString *)serviceID{
	return @"Sametime";
}
- (NSString *)serviceClass{
	return @"Sametime";
}
- (NSString *)shortDescription{
	return @"Sametime";
}
- (NSString *)longDescription{
	return @"Lotus Sametime";
}
- (NSURL *)serviceAccountSetupURL
{
	return [NSURL URLWithString:AILocalizedString(@"http://trac.adium.im/wiki/Sametime", @"URL for Sametime signup or about page. Replace with the URL to an equivalent page in your language if one exists.")];
}
- (NSString *)accountSetupLabel
{
	return AILocalizedString(@"About Sametime", @"Text for Lotus Sametime sign up button");
}
- (NSCharacterSet *)allowedCharacters{
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;

	[allowedCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	[allowedCharacters formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
	[allowedCharacters addCharactersInString:@" "];

	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];
	
	return [returnSet autorelease];
}
- (NSUInteger)allowedLength{
	return 1000;
}
- (BOOL)caseSensitive{
	return YES;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (BOOL)canCreateGroupChats{
	return YES;
}
- (void)registerStatuses{
	//"available"
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];

	//"away"
	[adium.statusController registerStatus:STATUS_NAME_AWAY
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	//"busy"
	[adium.statusController registerStatus:STATUS_NAME_DND
							 withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]
									  ofType:AIAwayStatusType
								  forService:self];
	
	/*
	 m = g_list_append(m, _("Active"));
	 m = g_list_append(m, _("Away"));
	 m = g_list_append(m, _("Do Not Disturb"));
	 */ 
}
@end
