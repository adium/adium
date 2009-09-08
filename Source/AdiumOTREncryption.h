//
//  AdiumOTREncryption.h
//  Adium
//
//  Created by Evan Schoenberg on 12/28/05.
//

#import <libotr/context.h>
#import <libotr/userstate.h>
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
