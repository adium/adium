/*
 *  AIAccountControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/30/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@class AIService, AIAccount, AIListContact, AIStatus;

#define Account_ListChanged 					@"Account_ListChanged"
#define Adium_RequestSetManualIdleTime			@"Adium_RequestSetManualIdleTime"

@protocol AIAccountControllerRemoveConfirmationDialog <NSObject>
- (void)runModal;
- (void)beginSheetModalForWindow:(NSWindow*)window;
@end

@interface NSObject (AIEditAccountWindowControllerTarget)
//Optional
- (void)editAccountWindow:(NSWindow*)window didOpenForAccount:(AIAccount *)inAccount;

//Required
- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)successful;
@end

typedef enum {
	AIPromptAsNeeded = 0,
	AIPromptAlways,
	AIPromptNever
} AIPromptOption;

@protocol AIAccountController <AIController>

#pragma mark Services
/*!
 * @brief Register an AIService instance
 *
 * All services should be registered before they are used. A service provides access to an instant messaging protocol.
 */
- (void)registerService:(AIService *)inService;

/*!
 * @brief Returns an array of all available services
 *
 * @return NSArray of AIService instances
 */
- (NSArray *)services;

/*!
 * @brief Returns an array of all active services
 *
 * "Active" services are those for which the user has an enabled account.
 * @param includeCompatible Include services which are compatible with an enabled account but not specifically active.
 *        For example, if an AIM account is enabled, the ICQ service will be included if this is YES.
 * @return NSArray of AIService instances
 */
- (NSSet *)activeServicesIncludingCompatibleServices:(BOOL)includeCompatible;

/*!
 * @brief Retrieves a service by its unique ID
 *
 * @param uniqueID The serviceCodeUniqueID of the desired service
 * @return AIService if found, nil if not found
 */
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID;

/*!
 * @brief Retrieves a service by service ID.
 *
 * Service IDs may be shared by multiple services if the same service is provided by two different plugins.
 * -[AIService serviceID] returns serviceIDs. An example is @"AIM".
 * @return The first service with the matching service ID, or nil if none is found.
 */
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID;

#pragma mark Passwords
/*!
 * @brief Set the password of an account
 *
 * @param inPassword password to store
 * @param inAccount account the password belongs to
 */
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;

/*!
 * @brief Forget the password of an account
 *
 * @param inAccount account whose password should be forgotten. Any stored keychain item will be removed.
 */
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;

/*!
 * @brief Retrieve the stored password of an account
 * 
 * @param inAccount account whose password is desired
 * @return account password, or nil if the password is not available without prompting
 */
- (NSString *)passwordForAccount:(AIAccount *)inAccount;

/*!
 * @brief Retrieve the password of an account, prompting the user if necessary
 *
 * @param inAccount account whose password is desired
 * @param promptOption An AIPromptOption determining whether and how a prompt for the password should be displayed if it is needed. This allows forcing or suppressing of the prompt dialogue.
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available. Selector is of the form - (void)returnedPassword:(NSString *)p returnCode:(AIPasswordPromptReturn)returnCode context:(id)context
 * @param inContext context passed to target
 */
- (void)passwordForAccount:(AIAccount *)inAccount promptOption:(AIPromptOption)promptOption notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;

/*!
 * @brief Set the password for a proxy server
 *
 * @param inPassword password to store. Nil to forget the password for this server/username pair.
 * @param server proxy server name
 * @param userName proxy server user name
 *
 * XXX - This is inconsistent.  Above we have a separate forget method, here we forget when nil is passed...
 */
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName;

/*!
 * @brief Retrieve the stored password for a proxy server
 * 
 * @param server proxy server name
 * @param userName proxy server user name
 * @return proxy server password, or nil if the password is not available without prompting
 */
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName;

/*!
 * @brief Retrieve the password for a proxy server, prompting the user if necessary
 *
 * @param server proxy server name
 * @param userName proxy server user name
 * @param inTarget target to notify when password is available
 * @param inSelector selector to notify when password is available. Selector is of the form - (void)returnedPassword:(NSString *)p returnCode:(AIPasswordPromptReturn)returnCode context:(id)context
 * @param inContext context passed to target
 */
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;

#pragma mark Accounts
- (NSArray *)accounts;
- (NSArray *)accountsCompatibleWithService:(AIService *)service;
- (NSArray *)accountsWithCurrentStatus:(AIStatus *)status;
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID;
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID;
- (void)addAccount:(AIAccount *)inAccount;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (void)accountDidChangeUID:(AIAccount *)inAccount;

//Preferred Accounts
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;

//Connection convenience methods
- (void)disconnectAllAccounts;
- (BOOL)oneOrMoreConnectedAccounts;
- (BOOL)oneOrMoreConnectedOrConnectingAccounts;

/*!
 * @brief Display account configuration for an account
 *
 * @param account The account to edit. Must not be nil.
 * @param window The window on which to attach the configuration as a sheet. If nil, the editor is shown as a free-standing window.
 * @param target The target to notify when editing is complete. See the AIEditAccountWindowControllerTarget informal protocol.
 */
- (void)editAccount:(AIAccount *)account onWindow:(NSWindow *)window notifyingTarget:(id)target;

@end
