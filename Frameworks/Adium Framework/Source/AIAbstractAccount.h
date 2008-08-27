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

#import <Adium/AIAccount.h>

@class AIWiredString;

typedef enum {
	AIReconnectNever = 0,
	AIReconnectImmediately,
	AIReconnectNormally
} AIReconnectDelayType;

@interface AIAccount (Abstract)

- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService;
- (NSData *)userIconData;
- (void)setUserIconData:(NSData *)inData;
- (NSString *)host;
- (int)port;
- (void)filterAndSetUID:(NSString *)inUID;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)inEnabled;

//Status
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (void)silenceAllContactUpdatesForInterval:(NSTimeInterval)interval;
- (void)updateContactStatus:(AIListContact *)inContact;
- (void)updateCommonStatusForKey:(NSString *)key;
- (AIStatus *)statusState;
- (AIStatus *)actualStatusState;
- (void)setStatusState:(AIStatus *)statusState;
- (void)setStatusStateAndRemainOffline:(AIStatus *)statusState;

//Properties
- (NSString *)currentDisplayName;

/*!
 * @brief Sent by an account to itself to update its user icon
 *
 * Both NSImage and NSData forms are passed to prevent duplication of data; either or both may be used.
 *
 * The image should be resized as needed for the protocol.
 *
 * Subclasses MUST call super's implementation.
 *
 * @param image An NSImage of the user icon, or nil if no image.
 * @param originalData The original data which made the image, which may be in any NSImage-compatible format, or nil if no image.
 */
- (void)setAccountUserImage:(NSImage *)image withData:(NSData *)originalData;

//Auto-Refreshing Status String
- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key;
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector context:(id)originalContext;
- (NSAttributedString *)autoRefreshingOriginalAttributedStringForStatusKey:(NSString *)key;
- (void)setValue:(id)value forProperty:(NSString *)key notify:(NotifyTiming)notify;
- (void)startAutoRefreshingStatusKey:(NSString *)key forOriginalValueString:(NSString *)originalValueString;
- (void)stopAutoRefreshingStatusKey:(NSString *)key;
- (void)_startAttributedRefreshTimer;
- (void)_stopAttributedRefreshTimer;
- (void)gotFilteredStatusMessage:(NSAttributedString *)statusMessage forStatusState:(AIStatus *)statusState;
- (void)updateLocalDisplayNameTo:(NSAttributedString *)displayName;
- (NSString *)currentDisplayName;

//Contacts
- (NSArray *)contacts;
- (AIListContact *)contactWithUID:(NSString *)sourceUID;
- (void)removeAllContacts;
- (void)removePropetyValuesFromContact:(AIListContact *)listContact silently:(BOOL)silent;

//Connectivity
- (BOOL)shouldBeOnline;
- (void)setShouldBeOnline:(BOOL)inShouldBeOnline;
- (void)toggleOnline;
- (void)didConnect;
- (NSSet *)contactProperties;
- (void)didDisconnect;
- (void)connectScriptCommand:(NSScriptCommand *)command;
- (void)disconnectScriptCommand:(NSScriptCommand *)command;
- (void)serverReportedInvalidPassword;
- (void)getProxyConfigurationNotifyingTarget:(id)target selector:(SEL)selector context:(id)context;
- (NSString *)lastDisconnectionError;
- (void)setLastDisconnectionError:(NSString *)inError;
- (AIReconnectDelayType)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError;
- (BOOL)encrypted;

//FUS Disconnecting
- (void)autoReconnectAfterDelay:(NSTimeInterval)delay;
- (void)cancelAutoReconnect;
- (void)initFUSDisconnecting;

//Temporary Accounts
- (BOOL)isTemporary;
- (void)setIsTemporary:(BOOL)inIsTemporary;

- (void)setPasswordTemporarily:(AIWiredString *)inPassword;
/*!
 * @brief While we are connected, return the password used to connect
 *
 * This will not look up the password in the keychain. Results are undefined if we are not connected.
 */
- (AIWiredString *)passwordWhileConnected;

@end

@interface AIAccount (Abstract_ForSubclasses)
//Chats
- (void)displayYouHaveConnectedInChat:(AIChat *)chat;
@end
