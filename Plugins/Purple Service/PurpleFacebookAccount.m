//
//  PurpleFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 1/15/09.
//  Copyright 2009 Adium X. All rights reserved.
//

#import "PurpleFacebookAccount.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>

@implementation PurpleFacebookAccount

- (const char*)protocolPlugin
{
    return "prpl-bigbrownchunx-facebookim";
}

- (NSString *)webProfileStringForContact:(AIListContact *)contact
{
	return [NSString stringWithFormat:NSLocalizedString(@"View %@'s Facebook profile", nil), 
			contact.displayName];
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];
	
	/* We could add a pref for this, but not without some enhancements to mail notifications. Currently, this being
	 * enabled means ugly nasty "You have new mail!" popups continuously, since that's how 'notifications' are passed
	 * to us.
	 */
	purple_account_set_bool(account, "facebook_get_notifications", FALSE);
	
	// We do our own history; don't let the server's history get displayed as new messages
	purple_account_set_bool(account, "facebook_show_history", FALSE);
	
	// Use friends list as groups.
	purple_account_set_bool(account, "facebook_use_groups", TRUE);
	
	// Allow for moving through libpurple
	purple_account_set_bool(account, "facebook_manage_friends", TRUE);
	
	// Disable the Facebook CAPTCHA since it causes heartache and pain.
	purple_account_set_bool(account, "ignore-facebook-captcha", TRUE);
}

- (NSString *)host
{
	return @"login.facebook.com";
}

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							  arguments:(NSMutableDictionary *)arguments
{
	if (statusState.statusType == AIOfflineStatusType) {
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

/*!
 * @brief Set an alias for a contact
 *
 * Normally, we consider the name a 'serverside alias' unless it matches the UID's characters
 * However, the UID in facebook should never be presented to the user if possible; it's for internal use
 * only.  We'll therefore consider any alias a formatted UID such that it will replace the UID when displayed
 * in Adium.
 */
- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![purpleAlias isEqualToString:theContact.formattedUID] && 
		![purpleAlias isEqualToString:theContact.UID]) {
		[theContact setFormattedUID:purpleAlias
							 notify:NotifyLater];
		
		//Apply any changes
		[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
	}
}

@end
