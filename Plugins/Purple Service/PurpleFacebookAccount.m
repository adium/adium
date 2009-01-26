//
//  PurpleFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 1/15/09.
//  Copyright 2009 Adium X. All rights reserved.
//

#import "PurpleFacebookAccount.h"
#import <Adium/AIHTMLDecoder.h>

@implementation PurpleFacebookAccount

- (const char*)protocolPlugin
{
    return "prpl-bigbrownchunx-facebookim";
}

- (NSString *)webProfileStringForContact:(AIListContact *)contact
{
	return [NSString stringWithFormat:NSLocalizedString(@"View %@'s Facebook profile", nil), 
			[contact displayName]];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	/* We could add a pref for this, but not without some enhancements to mail notifications. Currently, this being
	 * enabled means ugly nasty "You have new mail!" popups continuously, since that's how 'notifications' are passed
	 * to us.
	 */
	purple_account_set_bool(account, "facebook_get_notifications", FALSE);
}

- (NSString *)host
{
	return @"login.facebook.com";
}

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							  arguments:(NSMutableDictionary *)arguments
{
	if ([statusState statusType] == AIOfflineStatusType) {
		return "offline";
	} else {
		return "available";
	}
}

- (void)setSocialNetworkingStatusMessage:(NSAttributedString *)statusMessage
{
	NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
	NSString *encodedStatusMessage = (statusMessage ? 
									  [self encodedAttributedString:statusMessage
													 forStatusState:nil] :
									  nil);
	if (encodedStatusMessage) {
		[arguments setObject:encodedStatusMessage
					  forKey:@"message"];
	}

	purple_account_set_bool(account, "facebook_set_status_through_pidgin", TRUE);
	[self setStatusState:nil
				statusID:"available" /* facebook only supports available */
				isActive:[NSNumber numberWithBool:YES]
			   arguments:arguments];
	purple_account_set_bool(account, "facebook_set_status_through_pidgin", FALSE);
}

/*!
 * @brief Status message for a contact
 */
- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)buddy
{
	PurplePluginProtocolInfo *prpl_info = NULL;
	const char *message;

	if (account && purple_account_get_connection(account) && purple_account_get_connection(account)->prpl)
		prpl_info = PURPLE_PLUGIN_PROTOCOL_INFO(purple_account_get_connection(account)->prpl);
	
	if (prpl_info && prpl_info->status_text)
		message = prpl_info->status_text(buddy);

	return (message ? [AIHTMLDecoder decodeHTML:[NSString stringWithUTF8String:message]] : nil);
}


- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
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
					  simpleTagsOnly:NO
					  bodyBackground:NO
				 allowJavascriptURLs:YES];
}

@end
