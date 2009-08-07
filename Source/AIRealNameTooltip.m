//
//  AIRealNameTooltip.m
//  Adium
//
//  Created by Zachary West on 2009-04-01.
//

#import "AIRealNameTooltip.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

@implementation AIRealNameTooltip
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
	if ([inObject isKindOfClass:[AIListContact class]] && [inObject valueForProperty:@"Real Name"]) {
		return AILocalizedString(@"Real Name", nil);
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
	if (![inObject isKindOfClass:[AIListContact class]] || ![inObject valueForProperty:@"Real Name"])
		return nil;
	
	return [NSAttributedString stringWithString:[inObject valueForProperty:@"Real Name"]];
}

- (BOOL)shouldDisplayInContactInspector
{
	// This should already be displayed by the account.
	return NO;
}
@end
