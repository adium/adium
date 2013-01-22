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

#import "OTRCommon.h"
#import <Adium/AIContentControllerProtocol.h>

@class ESOTRPreferences, AIContentMessage, AIAccount, AIListContact, AIChat;

typedef enum {
    TRUST_NOT_PRIVATE,
    TRUST_UNVERIFIED,
    TRUST_PRIVATE,
    TRUST_FINISHED
} TrustLevel;

@interface AdiumOTREncryption : NSObject <AdiumMessageEncryptor> {
	ESOTRPreferences	*OTRPrefs;
}

- (void)willSendContentMessage:(AIContentMessage *)inContentMessage;
- (NSString *)decryptIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount;

- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat;
- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat;
- (void)questionVerifyEncryptionIdentityInChat:(AIChat *)inChat;
- (void)sharedVerifyEncryptionIdentityInChat:(AIChat *)inChat;

- (void)prefsShouldUpdatePrivateKeyList;
- (void)prefsShouldUpdateFingerprintsList;

OtrlUserState otrg_get_userstate(void);
void otrg_ui_forget_fingerprint(Fingerprint *fingerprint);
void otrg_plugin_write_fingerprints(void);
void otrg_ui_update_keylist(void);

TrustLevel otrg_plugin_context_to_trust(ConnContext *context);

/* Generate a private key for the given accountname/protocol */
void otrg_plugin_create_privkey(const char *accountname,
								const char *protocol);

@end
