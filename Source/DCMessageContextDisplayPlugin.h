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
 

// Object pref keys
#define PREF_GROUP_CONTEXT_DISPLAY  @"Message Context Display"
#define KEY_MESSAGE_CONTEXT			@"Message Context"

// Pref keys
#define KEY_DISPLAY_CONTEXT			@"Display Message Context"
#define	KEY_DIM_RECENT_CONTEXT		@"Dim Recent Context"
#define KEY_DISPLAY_LINES			@"Lines to Display"
#define KEY_DISPLAY_MODE			@"Display Mode"
#define KEY_HAVE_TALKED_DAYS		@"Have Talked Days"
#define KEY_HAVE_NOT_TALKED_DAYS	@"Have Not Talked Days"
#define KEY_HAVE_TALKED_UNITS		@"Have Talked Units"
#define KEY_HAVE_NOT_TALKED_UNITS   @"Have Not Talked Units"

#define CONTEXT_DISPLAY_DEFAULTS	@"MessageContextDisplayDefaults"

// Possible Display Modes
typedef enum AIMessageHistoryDisplayModes {
	MODE_ALWAYS = 0,
	MODE_HAVE_TALKED,
	MODE_HAVE_NOT_TALKED
} AIMessageHistoryDisplayModes;

// Possible Units
typedef enum AIMessageHistoryDisplayUnits {
	UNIT_DAYS = 0,
	UNIT_HOURS
} AIMessageHistoryDisplayUnits;

@class DCMessageContextDisplayPreferences, SMSQLiteLoggerPlugin;

@interface DCMessageContextDisplayPlugin : AIPlugin {	
	BOOL							isObserving;
	BOOL							shouldDisplay;
	BOOL							dimRecentContext;
	NSInteger								linesToDisplay;
	
	NSInteger								displayMode;
	NSInteger								haveTalkedDays;
	NSInteger								haveNotTalkedDays;
	
	NSInteger								haveTalkedUnits;
	NSInteger								haveNotTalkedUnits;
	
	DCMessageContextDisplayPreferences  *preferences;
	
	NSMutableArray	  *foundMessages;
	NSMutableArray	  *elementStack;
	NSAutoreleasePool *parsingAutoreleasePool;
}

@end
