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

#import <WebKit/WebKit.h>
#import <Adium/AIInterfaceControllerProtocol.h>

typedef enum {
	AIWebkitRegularChat = 0,
	AIWebkitGroupChat
} AIWebkitStyleType;

/*!
 *	@brief Preference group for webkit display prefs
 *	@see AIPreferencesController
 */
#define PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY	@"WebKit Message Display"
#define PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY		@"WebKit Message Display (Group)"

/*!
 *	@brief Preference group for custom images as background in the webkit message view
 *	@see AIPreferencesController
 */
#define PREF_GROUP_WEBKIT_BACKGROUND_IMAGES		@"WebKit Custom Backgrounds"

/*!
 *	@brief Preference group for default settings
 *	@see AIPreferencesController
 */
#define WEBKIT_DEFAULT_PREFS					@"WebKit Defaults"

/*!
 *	@brief The path to the currently selected message style
 */
#define KEY_CURRENT_WEBKIT_STYLE_PATH			@"Current Style Path"

/*!
 *	@brief Key for the preference controlling whether we should show user icons in the message view
 */
#define KEY_WEBKIT_SHOW_USER_ICONS				@"Show User Icons"

/*!
 *	@brief Key for the preference controlling whether we should show a header in the message view
 */
#define KEY_WEBKIT_SHOW_HEADER					@"Show Header"

/*!
 *	@brief Key for the preference controlling whether we should show received message colors
 */
#define KEY_WEBKIT_SHOW_MESSAGE_COLORS			@"Show Message Colors"

/*!
 *	@brief Key for the preference controlling whether we should show received message fonts
 */
#define KEY_WEBKIT_SHOW_MESSAGE_FONTS			@"Show Message Fonts"

/*!
 *	@brief Key for the preference controlling how the usernames should be displayed
 */
#define KEY_WEBKIT_NAME_FORMAT					@"Name Format"

/*!
 *	@brief Key for the preference controlling whether we're using a custom format for usernames
 */
#define KEY_WEBKIT_USE_NAME_FORMAT				@"Use Custom Name Format"

/*!
 *	@brief Key for the preference controlling what message style is in use
 */
#define KEY_WEBKIT_STYLE						@"Message Style"

/*!
 *	@brief Key for the preference controlling how the timestamp on messages should be formatted
 */
#define	KEY_WEBKIT_TIME_STAMP_FORMAT			@"Time Stamp"

/*!
 *	@brief Key for the preference controlling the minimum font size in the message view
 */
#define KEY_WEBKIT_MIN_FONT_SIZE				@"Min Font Size"

/*!
 * @brief Key for group chats to use the same preferences as regular.
 */
#define KEY_WEBKIT_USE_REGULAR_PREFERENCES		@"Use Regular Chat Preferences"

#define NEW_CONTENT_RETRY_DELAY					0.01 

@class ESWebKitMessageViewPreferences, AIChat, AIWebkitMessageViewStyle;

/*!
 *	@class AIWebKitMessageViewPlugin AIWebKitMessageViewPlugin.h
 *	@brief Handles loading the WKMV plugin into Adium
 *	@see AIWebKitMessageViewController
 */
@interface AIWebKitMessageViewPlugin : AIPlugin <AIMessageDisplayPlugin> {
	ESWebKitMessageViewPreferences  *preferences;
	NSMutableDictionary				*styleDictionary;
	AIWebkitMessageViewStyle		*currentGroupStyle;
	AIWebkitMessageViewStyle		*currentRegularStyle;
	NSDate							*lastStyleLoadDate;
	
	BOOL							useRegularForGroupChat;
}

/*!
 *	@return a new webkit message view controller initialized to display inChat
 *	@param inChat the chat that the message view will display
 */
- (id <AIMessageDisplayController>)messageDisplayControllerForChat:(AIChat *)inChat;

/*!
 *	This method is fairly expensive the first time it's run; however, the first time will almost always been in a thread at startup, to preload the styles. This method is threadsafe.
 *	@return A dictionary of all available message styles, with their identifiers as keys
 */
- (NSDictionary *)availableMessageStyles;

/*!
 *	@return a message style NSBundle
 *	@param identifier the identifier of the message style
 */
- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)identifier;

/*!
 *	@brief Returns a preference key which is style specific
 *	@param key The preference key
 *	@param style The style name it will be specific to
 */
- (NSString *)styleSpecificKey:(NSString *)key forStyle:(NSString *)style;

/*!
 *	@brief Returns the shared instance of the currently used message style for a particular chat
 */
- (AIWebkitMessageViewStyle *) currentMessageStyleForChat:(AIChat *)chat;

- (NSString *)preferenceGroupForChat:(AIChat *)chat;

@end
