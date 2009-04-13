//
//  AIUserHostTooltip.m
//  Adium
//
//  Created by Zachary West on 2009-04-01.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AIUserHostTooltip.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

@implementation AIUserHostTooltip
- (void)installPlugin
{
	[adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];
}

- (void)uninstallPlugin
{
	[adium.interfaceController unregisterContactListTooltipEntry:self secondaryEntry:YES];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]] && [inObject valueForProperty:@"User Host"]) {
		return AILocalizedString(@"User Host", nil);
	} else {
		return nil;
	}
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	if (![inObject isKindOfClass:[AIListContact class]] || ![inObject valueForProperty:@"User Host"])
		return nil;
	
	return [NSAttributedString stringWithString:[inObject valueForProperty:@"User Host"]];
}

- (BOOL)shouldDisplayInContactInspector
{
	// This should already be displayed by the account.
	return NO;
}

@end
