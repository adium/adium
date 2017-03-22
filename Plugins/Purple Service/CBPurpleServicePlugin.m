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

#import "CBPurpleServicePlugin.h"
#import "PurpleServices.h"
#import "SLPurpleCocoaAdapter.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "AMPurpleTuneTooltip.h"
#import "AIIRCServicesPasswordPlugin.h"
#import "AIAnnoyingIRCMessagesHiderPlugin.h"
#import "AIFacebookXMPPService.h"

@implementation CBPurpleServicePlugin

#pragma mark Plugin Installation
//  Plugin Installation ------------------------------------------------------------------------------------------------

#define PURPLE_DEFAULTS   @"PurpleServiceDefaults"

- (void)installPlugin
{
	//Register our defaults
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:PURPLE_DEFAULTS
																		forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	
    //Install the services
	[ESAIMService registerService];
	[ESDotMacService registerService];
	[AIMobileMeService registerService];
	[ESICQService registerService];
	[PurpleFacebookService registerService];
	[ESGaduGaduService registerService];
	[AIGTalkService registerService];
	[ESIRCService registerService];
	[AILiveJournalService registerService];
	/* TODO for release of 1.5: At the very least, present to users who had a QQ account
	 * a message that it's no longer supported.
	 */
	//[ESQQService registerService];
	[ESSimpleService registerService];
	[ESNovellService registerService];
	[ESJabberService registerService];
	//[ESZephyrService registerService];
	[ESMeanwhileService registerService];
    [AIFacebookXMPPService registerService];
	
	[SLPurpleCocoaAdapter pluginDidLoad];
	
	//tooltip for tunes
	tunetooltip = [[AMPurpleTuneTooltip alloc] init];
	[adium.interfaceController registerContactListTooltipEntry:tunetooltip secondaryEntry:YES];
	
	ircPasswordPlugin = [[AIIRCServicesPasswordPlugin alloc] init];
	[ircPasswordPlugin installPlugin];
	
	messageHiderPlugin = [[AIAnnoyingIRCMessagesHiderPlugin alloc] init];
	[messageHiderPlugin installPlugin];
}

- (void)uninstallPlugin
{
	[adium.interfaceController unregisterContactListTooltipEntry:tunetooltip secondaryEntry:YES];
	[tunetooltip release];
	tunetooltip = nil;	
	
	[ircPasswordPlugin uninstallPlugin];
	[ircPasswordPlugin release];
	
	[messageHiderPlugin uninstallPlugin];
	[messageHiderPlugin release];
}

@end
