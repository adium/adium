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

@class AIListObject;

@interface AIPreferenceContainer : NSObject {
	NSString			*group;
	AIListObject		*object;
	NSMutableDictionary	*prefs;
	NSMutableDictionary	*defaults;
	NSInteger			preferenceChangeDelays;
}

+ (AIPreferenceContainer *)preferenceContainerForGroup:(NSString *)inGroup object:(AIListObject *)inObject create:(BOOL)create;
+ (void)preferenceControllerWillClose;

//Return a dictionary of preferences and defaults, appropriately merged together
@property (readonly, nonatomic) NSDictionary *dictionary;

//Replace all preferences for this container with the values and keys in inPreferences
- (void)setPreferences:(NSDictionary *)inPreferences;

//Return a dictionary of just the defaults
@property (readonly, nonatomic) NSDictionary *defaults;
- (void)registerDefaults:(NSDictionary *)inDefaults;

- (id)valueForKey:(NSString *)key ignoringDefaults:(BOOL)ignoreDefaults;
- (id)defaultValueForKey:(NSString *)key;

- (void)setPreferenceChangedNotificationsEnabled:(BOOL)inEnbaled;

@property (readwrite, nonatomic, copy) NSString *group;

@end
