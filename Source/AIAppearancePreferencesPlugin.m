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

#import "AIAppearancePreferencesPlugin.h"
#import "AIAppearancePreferences.h"
#import "AIDockController.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIServiceIcons.h>
#import <AIMenuBarIcons.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import "AIXtrasManager.h"

#define APPEARANCE_DEFAULT_PREFS 	@"AppearanceDefaults"

#define SHOW_USER_ICONS_TITLE		AILocalizedString(@"Show User Icons", nil)
#define HIDE_USER_ICONS_TITLE		AILocalizedString(@"Hide User Icons", nil)

#define SHOW_STATUS_MESSAGES_TITLE	AILocalizedString(@"Show Status Messages", nil)
#define HIDE_STATUS_MESSAGES_TITLE	AILocalizedString(@"Hide Status Messages", nil)

@implementation AIAppearancePreferencesPlugin

- (void)installPlugin
{
	id<AIPreferenceController> preferenceController = adium.preferenceController;

	[adium createResourcePathForName:LIST_LAYOUT_FOLDER];
	[adium createResourcePathForName:LIST_THEME_FOLDER];

	//Prepare our preferences
	[preferenceController registerDefaults:[NSDictionary dictionaryNamed:APPEARANCE_DEFAULT_PREFS
																forClass:[self class]] 
	                              forGroup:PREF_GROUP_APPEARANCE];

	preferences = [[AIAppearancePreferences preferencePaneForPlugin:self] retain];	

	[[adium notificationCenter] addObserver:self
								   selector:@selector(invalidStatusSetActivated:)
									   name:AIStatusIconSetInvalidSetNotification
									 object:nil];
	
	//Add the menu item for configuring the sort
	menuItem_userIcons = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SHOW_USER_ICONS_TITLE
																			  target:self
																			  action:@selector(toggleAppearancePreference:)
																	   keyEquivalent:@"i"];
	[menuItem_userIcons setKeyEquivalentModifierMask:(NSControlKeyMask | NSCommandKeyMask)];
	[adium.menuController addMenuItem:menuItem_userIcons toLocation:LOC_View_Appearance_Toggles];
	
	menuItem_userStatusMessages = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SHOW_STATUS_MESSAGES_TITLE
																					   target:self
																					   action:@selector(toggleAppearancePreference:)
																				keyEquivalent:@"s"];
	[menuItem_userStatusMessages setKeyEquivalentModifierMask:(NSControlKeyMask | NSCommandKeyMask)];
	[adium.menuController addMenuItem:menuItem_userStatusMessages toLocation:LOC_View_Appearance_Toggles];
	
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];	
}	

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[menuItem_userIcons release];
	[menuItem_userStatusMessages release];

	[super dealloc];
}

/*!
 * @brief Apply changed preferences
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Status icons
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if (firstTime || [key isEqualToString:KEY_STATUS_ICON_PACK]) {
			NSString *path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_STATUS_ICON_PACK]
											 extension:@"AdiumStatusIcons"
									resourceFolderName:@"Status Icons"];
			BOOL success = NO;
			
			if (path) {
				success = [AIStatusIcons setActiveStatusIconsFromPath:path];
			}

			//If the preferred pack isn't found (it was probably deleted while active), use the default one
			if (!success) {
				NSString *name = [adium.preferenceController defaultPreferenceForKey:KEY_STATUS_ICON_PACK
																				 group:PREF_GROUP_APPEARANCE
																				object:nil];
				path = [adium pathOfPackWithName:name
									   extension:@"AdiumStatusIcons"
							  resourceFolderName:@"Status Icons"];
				
				[AIStatusIcons setActiveStatusIconsFromPath:path];
			}
		}
		
		//Service icons
		if (firstTime || [key isEqualToString:KEY_SERVICE_ICON_PACK]) {
			NSString *path = [adium pathOfPackWithName:[prefDict objectForKey:KEY_SERVICE_ICON_PACK]
											 extension:@"AdiumServiceIcons"
									resourceFolderName:@"Service Icons"];
			BOOL success = NO;
			
			if (path) {
				success = [AIServiceIcons setActiveServiceIconsFromPath:path];
			}
			
			//If the preferred pack isn't found (it was probably deleted while active), use the default one
			if (!success) {
				NSString *name = [adium.preferenceController defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																				 group:PREF_GROUP_APPEARANCE
																				object:nil];
				path = [adium pathOfPackWithName:name
									   extension:@"AdiumServiceIcons"
							  resourceFolderName:@"Service Icons"];

				[AIServiceIcons setActiveServiceIconsFromPath:path];
			}
		}
		
		// Menu Bar Icons
		if (firstTime || [key isEqualToString:KEY_MENU_BAR_ICONS]) {
			// Post a notification to update the menu bar icons.
			[[adium notificationCenter] postNotificationName:AIMenuBarIconsDidChangeNotification
																			   object:nil];
		}
		
		//Theme
		if (firstTime || [key isEqualToString:KEY_LIST_THEME_NAME]) {
			[self applySetWithName:[prefDict objectForKey:KEY_LIST_THEME_NAME]
						 extension:LIST_THEME_EXTENSION
						  inFolder:LIST_THEME_FOLDER
				 toPreferenceGroup:PREF_GROUP_LIST_THEME];
		}
	
		if (firstTime || [key isEqualToString:KEY_LIST_LAYOUT_NAME]) {
			[self applySetWithName:[prefDict objectForKey:KEY_LIST_LAYOUT_NAME]
						 extension:LIST_LAYOUT_EXTENSION
						  inFolder:LIST_LAYOUT_FOLDER
				 toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
		}		
	}

	//Layout
	if ([group isEqualToString:PREF_GROUP_LIST_LAYOUT]) {
		if (firstTime || !key ||
			[key isEqualToString:KEY_LIST_LAYOUT_SHOW_ICON] ||
			[key isEqualToString:KEY_LIST_LAYOUT_SHOW_EXT_STATUS]) {
			[menuItem_userIcons setTitle:([[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue] ?
										  HIDE_USER_ICONS_TITLE :
										  SHOW_USER_ICONS_TITLE)];
			[menuItem_userStatusMessages setTitle:([[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue] ?
												   HIDE_STATUS_MESSAGES_TITLE :
												   SHOW_STATUS_MESSAGES_TITLE)];
		}
	}
}

/*!
 * @brief An invalid status set was activated
 *
 * Reset to the default by clearing our preference
 */
- (void)invalidStatusSetActivated:(NSNotification *)inNotification
{
	[adium.preferenceController setPreference:nil
										 forKey:KEY_STATUS_ICON_PACK
										  group:PREF_GROUP_APPEARANCE];
	
	//Tell the preferences to update
	[preferences xtrasChanged:nil];
}

- (void)toggleAppearancePreference:(NSMenuItem *)sender
{
	NSString *key;

	if (sender == menuItem_userIcons) {
		key = KEY_LIST_LAYOUT_SHOW_ICON;
		
	} else if (sender == menuItem_userStatusMessages) {
		key = KEY_LIST_LAYOUT_SHOW_EXT_STATUS;

	} else {
		key = nil;
	}
	
	if (key) {
		BOOL	 oldValue = [[adium.preferenceController preferenceForKey:key
																   group:PREF_GROUP_LIST_LAYOUT] boolValue];

		[adium.preferenceController setPreference:[NSNumber numberWithBool:!oldValue]
											 forKey:key
											  group:PREF_GROUP_LIST_LAYOUT];

		//Save the updated layout
		[self createSetFromPreferenceGroup:PREF_GROUP_LIST_LAYOUT
								  withName:[adium.preferenceController preferenceForKey:KEY_LIST_LAYOUT_NAME
																					group:PREF_GROUP_APPEARANCE]
								 extension:LIST_LAYOUT_EXTENSION
								  inFolder:LIST_LAYOUT_FOLDER];
	}
}

#pragma mark ListLayout and ListTheme preference management
//Apply a set of preferences
- (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup
{
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSEnumerator	*enumerator;
	NSString		*fileName, *resourcePath;
	NSDictionary	*setDictionary = nil;
	
	//Look in each resource location until we find it
	fileName = [setName stringByAppendingPathExtension:extension];
	
	enumerator = [[adium resourcePathsForName:folder] objectEnumerator];
	while ((resourcePath = [enumerator nextObject]) && !setDictionary) {
		NSString		*filePath = [resourcePath stringByAppendingPathComponent:fileName];
		
		if ([defaultManager fileExistsAtPath:filePath]) {
			NSBundle *xtraBundle;
			if((xtraBundle = [NSBundle bundleWithPath:filePath]) &&
			   ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) {
				filePath = [[xtraBundle resourcePath] stringByAppendingPathComponent:@"Data.plist"];
			}

			setDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
		}
	}
	
	//Apply its values
	if (setDictionary) {
		[adium.preferenceController setPreferences:setDictionary
											 inGroup:preferenceGroup];
	}
}

//Create a layout or theme set
- (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString		*path;
	NSString		*fileName = [[setName safeFilenameString] stringByAppendingPathExtension:extension];
	
	//If we don't find one, create a path to a bundle in the application support directory
	path = [[[adium applicationSupportDirectory] stringByAppendingPathComponent:folder] stringByAppendingPathComponent:fileName];
	if ([AIXtrasManager createXtraBundleAtPath:path])
		path = [path stringByAppendingPathComponent:@"Contents/Resources/Data.plist"];
	
	if ([[adium.preferenceController preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]) {
		[[adium notificationCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
		
		return YES;
	} else {
		NSRunAlertPanel(AILocalizedString(@"Error Saving Theme",nil),
						AILocalizedString(@"Unable to write file %@ to %@",nil),
						AILocalizedString(@"OK",nil),
						nil,
						nil,
						fileName,
						path);
		return NO;
	}
}

//Delete a layout or theme set
- (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	BOOL		success;
	
	success = [[NSFileManager defaultManager] removeFileAtPath:[adium pathOfPackWithName:setName
																			   extension:extension
																	  resourceFolderName:folder]
													   handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[adium notificationCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

//
- (BOOL)renameSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toName:(NSString *)newName
{
	BOOL		success;
	
	NSString	*destFolder = [[adium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] movePath:[adium pathOfPackWithName:setName
																	   extension:extension
															  resourceFolderName:folder]
												toPath:[destFolder stringByAppendingPathComponent:newFileName]
											   handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[adium notificationCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

//
- (BOOL)duplicateSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder newName:(NSString *)newName
{
	BOOL		success;
	
	//Duplicate the set
	NSString	*destFolder = [[adium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*newFileName = [newName stringByAppendingPathExtension:extension];
	
	success = [[NSFileManager defaultManager] copyPath:[adium pathOfPackWithName:setName
																	   extension:extension
															  resourceFolderName:folder]
												toPath:[destFolder stringByAppendingPathComponent:newFileName]
											   handler:nil];
	
	//The availability of an xtras just changed, since we deleted it... post a notification so we can update
	[[adium notificationCenter] postNotificationName:AIXtrasDidChangeNotification object:extension];
	
	return success;
}

//Sort sets
NSInteger availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context) {
	return [[objectA objectForKey:@"name"] caseInsensitiveCompare:[objectB objectForKey:@"name"]];
}

//
- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[adium allResourcesForName:folder withExtensions:extension] objectEnumerator];
	NSMutableSet	*alreadyAddedArray = [NSMutableSet set];
	NSString		*filePath;
	
    while ((filePath = [enumerator nextObject])) {
		NSString		*name;
		NSBundle		*xtraBundle;
		NSDictionary 	*themeDict;

		name = [[filePath lastPathComponent] stringByDeletingPathExtension];

		if((xtraBundle = [NSBundle bundleWithPath:filePath]) &&
		   ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) {
			filePath = [[xtraBundle resourcePath] stringByAppendingPathComponent:@"Data.plist"];
		}

		if ((themeDict = [NSDictionary dictionaryWithContentsOfFile:filePath])) {			
			//The Adium resource path is last in our resourcePaths array; by only adding sets we haven't
			//already added, we allow precedence to occur rather than conflict.
			if (![alreadyAddedArray containsObject:name]) {
				[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					name, @"name",
					filePath, @"path",
					themeDict, @"preferences",
					nil]];
				[alreadyAddedArray addObject:name];
			}
		}
	}
	
	return [setArray sortedArrayUsingFunction:availableSetSort context:nil];
}

- (NSArray *)availableLayoutSets
{
	return [self availableSetsWithExtension:LIST_LAYOUT_EXTENSION 
								 fromFolder:LIST_LAYOUT_FOLDER];
}
- (NSArray *)availableThemeSets
{
	return [self availableSetsWithExtension:LIST_THEME_EXTENSION
								 fromFolder:LIST_THEME_FOLDER];
}

@end
