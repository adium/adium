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


@class ESGeneralPreferences;

typedef enum {
	AISwitchArrows = 0,
	AISwitchShiftArrows,
	AIBrackets,
	AIBraces,
	AIOptArrows,
	AICtrlTab
} AITabKeys;

#define PREF_GROUP_CHAT_CYCLING			@"Chat Cycling"
#define KEY_TAB_SWITCH_KEYS				@"Tab Switching Keys"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"

#define PREF_GROUP_STATUS_MENU_ITEM     @"Status Menu Item"
#define KEY_STATUS_MENU_ITEM_ENABLED    @"Status Menu Item Enabled"

#define	KEY_GENERAL_HOTKEY				@"General Hot Key"

@class SGHotKey;

@interface ESGeneralPreferencesPlugin : AIPlugin {
	ESGeneralPreferences	*preferences;
	
	SGHotKey	*globalHotKey;
}

@end
