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


#define	KEY_STATUS_ICON_PACK		@"Status Icon Pack"
#define	KEY_SERVICE_ICON_PACK		@"Service Icon Pack"
#define KEY_MENU_BAR_ICONS			@"Menu Bar Icons"

#define KEY_LIST_LAYOUT_NAME		@"List Layout Name"
#define KEY_LIST_THEME_NAME			@"List Theme Name"

@class AIAppearancePreferences;

@interface AIAppearancePreferencesPlugin : AIPlugin {
	AIAppearancePreferences		*preferences;
}

//Themes and Layouts
- (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup;
- (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
- (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
- (BOOL)renameSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toName:(NSString *)newName;
- (BOOL)duplicateSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder newName:(NSString *)newName;
- (NSArray *)availableLayoutSets;
- (NSArray *)availableThemeSets;

@end
