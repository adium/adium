//
//  AIGroupChatStatusTooltipPlugin.m
//  Adium
//
//  Created by Zachary West on 2009-03-31.
//

#import "AIGroupChatStatusTooltipPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIGroupChatStatusIcons.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

/*!
 * @class AIGroupChatStatusTooltipPlugin
 * @brief Displays a tooltip with details of the contact's status in group chats
 */
@implementation AIGroupChatStatusTooltipPlugin
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
	if ([inObject isKindOfClass:[AIListContact class]] && [adium.chatController allGroupChatsContainingContact:(AIListContact *)inObject].count) {
		return AILocalizedString(@"Group Chats", nil);
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
	if (![inObject isKindOfClass:[AIListContact class]])
		return nil;
	
	NSSet *groupChats = [adium.chatController allGroupChatsContainingContact:(AIListContact *)inObject];
	
	NSMutableAttributedString *entry = nil;
	
	if (groupChats.count) {
		entry = [[NSMutableAttributedString alloc] init];
		
		BOOL shouldAppendNewline = NO;
		
		for (AIChat *chat in groupChats) {
			NSImage *chatImage = [[AIGroupChatStatusIcons sharedIcons] imageForFlag:[chat flagsForContact:inObject]];
			
			if (shouldAppendNewline) {
				[entry appendString:@"\r" withAttributes:nil];
			} else {
				shouldAppendNewline = YES;
			}
			
			if (chatImage) {
				NSTextAttachment		*attachment;
				NSTextAttachmentCell	*cell;
				
				cell = [[NSTextAttachmentCell alloc] init];
				[cell setImage:chatImage];
				
				attachment = [[NSTextAttachment alloc] init];
				[attachment setAttachmentCell:cell];
				[cell release];
				
				[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				[attachment release];
				
				[entry appendString:@" " withAttributes:nil];
			}
			
			[entry appendString:chat.name withAttributes:nil];
			
			NSString *alias = [chat aliasForContact:inObject];
			
			if (alias && ![alias isEqualToString:inObject.displayName]) {
				[entry appendString:@" (" withAttributes:nil];
				[entry appendString:alias withAttributes:nil];
				[entry appendString:@")" withAttributes:nil];
			}
		}
		
		[entry autorelease];
	}
	
	return entry;
}

- (BOOL)shouldDisplayInContactInspector
{
	// This should already be displayed by the account.
	return NO;
}

@end
