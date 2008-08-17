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

#import <Adium/AIPlugin.h>

@class ESGeneralPreferences;

typedef enum {
	AISwitchArrows = 0,
	AISwitchShiftArrows,
	AIBrackets,
	AIBraces,
	AIOptArrows
} AITabKeys;

typedef enum {
	AISendOnEnter = 0,
	AISendOnReturn,
	AISendOnBoth
} AISendKeys;

#define PREF_GROUP_CHAT_CYCLING			@"Chat Cycling"
#define KEY_TAB_SWITCH_KEYS				@"Tab Switching Keys"

#define	SEND_ON_RETURN					@"Send On Return"
#define	SEND_ON_ENTER					@"Send On Enter"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"

#define PREF_GROUP_STATUS_MENU_ITEM     @"Status Menu Item"
#define KEY_STATUS_MENU_ITEM_ENABLED    @"Status Menu Item Enabled"

#define PREF_GROUP_CONFIRMATIONS		@"Confirmations"
#define KEY_CONFIRM_QUIT				@"Confirm Quit"

#define	KEY_GENERAL_HOTKEY				@"General Hot Key"

@class PTHotKey;

@interface ESGeneralPreferencesPlugin : AIPlugin {
	ESGeneralPreferences	*preferences;
	
	PTHotKey	*globalHotKey;
}

@end
