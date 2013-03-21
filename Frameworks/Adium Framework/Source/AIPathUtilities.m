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

#import <Adium/AIPathUtilities.h>

#define CACHES_DIRECTORY			@"Caches"
#define ADIUM_CACHES				@"Adium"

#define BUNDLE_CONTENTS				@"Contents"
#define BUNDLE_RESOURCES			@"Resources"

#define APPLICATION_SUPPORT			@"Application Support"
#define ADIUM_APP_SUPPORT			@"Adium 2.0"

#define PLUGINS_DIRECTORY			@"PlugIns"
#define CONTACT_LIST_DIRECTORY		@"Contact List"
#define DOCK_ICONS_DIRECTORY		@"Dock Icons"
#define EMOTICONS_DIRECTORY			@"Emoticons"
#define MESSAGE_STYLES_DIRECTORY	@"Message Styles"
#define SCRIPTS_DIRECTORY			@"Scripts"
#define SERVICE_ICONS_DIRECTORY		@"Service Icons"
#define SOUNDS_DIRECTORY			@"Sounds"
#define STATUS_ICONS_DIRECTORY		@"Status Icons"
#define MENU_BAR_ICONS_DIRECTORY	@"Menu Bar Icons"


NSArray *AISearchPathForDirectories(NSUInteger directory)
{
	return AISearchPathForDirectoriesInDomainsExpanding(directory, AIAllDomainsMask & ~AIInternalDomainMask, YES);
}

/*!
 * @brief Function to search for Adium resources
 *
 * This function works as a drop-in replacement for NSSearchPathForDirectoriesInDomains, but offers
 * support for Adium-specific search paths.
 *
 * @param directory Like NSSearchPathForDirectoriesInDomains, but with a number of other options; see AIPathUtilities.h.
 * @param domainMask Like NSSearchPathForDirectoriesInDomains, but with AIInternalDomainMask and AIAllDomainsMask.
 * @param expandTilde If true, expand the ~ in home directory paths.
 * @result NSArray of search paths, like NSSearchPathForDirectoriesInDomains.
 */
NSArray *AISearchPathForDirectoriesInDomainsExpanding(NSUInteger directory, NSUInteger domainMask, BOOL expandTilde)
{
	NSMutableArray *dirs = [[NSMutableArray alloc] init];
	NSString *adiumResourceName = nil;
	NSArray *internalRelativePath = nil;
	NSArray *externalRelativePath = nil;

	if (directory == AICachesDirectory) {
		directory = NSLibraryDirectory;
		domainMask &= NSUserDomainMask; // Only search ~
		externalRelativePath = [NSArray arrayWithObjects:CACHES_DIRECTORY, ADIUM_CACHES, nil];
	} else if (directory == AIPluginsDirectory) {
		//Special case; PlugIns isn't inside Resources/
		internalRelativePath = [NSArray arrayWithObjects:BUNDLE_CONTENTS, PLUGINS_DIRECTORY, nil];
		adiumResourceName = PLUGINS_DIRECTORY;
	} else if (directory == AIContactListDirectory) {
		adiumResourceName = CONTACT_LIST_DIRECTORY;
	} else if (directory == AIDockIconsDirectory) {
		adiumResourceName = DOCK_ICONS_DIRECTORY;
	} else if (directory == AIEmoticonsDirectory) {
		adiumResourceName = EMOTICONS_DIRECTORY;
	} else if (directory == AIMessageStylesDirectory) {
		adiumResourceName = MESSAGE_STYLES_DIRECTORY;
	} else if (directory == AIScriptsDirectory) {
		adiumResourceName = SCRIPTS_DIRECTORY;
	} else if (directory == AIServiceIconsDirectory) {
		adiumResourceName = SERVICE_ICONS_DIRECTORY;
	} else if (directory == AISoundsDirectory) {
		adiumResourceName = SOUNDS_DIRECTORY;
	} else if (directory == AIStatusIconsDirectory) {
		adiumResourceName = STATUS_ICONS_DIRECTORY;
	} else if (directory == AIMenuBarIconsDirectory) {
		adiumResourceName = MENU_BAR_ICONS_DIRECTORY;
	}

	if (adiumResourceName) {
		if (!internalRelativePath) {
			internalRelativePath = [NSArray arrayWithObjects:BUNDLE_CONTENTS, BUNDLE_RESOURCES, adiumResourceName, nil];
		}

		// Don't search for Adium resources in /System
		domainMask &= ~(NSSystemDomainMask);

		directory = NSLibraryDirectory;
		externalRelativePath = [NSArray arrayWithObjects:APPLICATION_SUPPORT, ADIUM_APP_SUPPORT, adiumResourceName, nil];
	}

	// Internal directories.
	if (((domainMask & AIInternalDomainMask) != 0) && internalRelativePath) {
		NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *fullAppendPath = [NSString pathWithComponents:internalRelativePath];

		[dirs addObject:[bundlePath stringByAppendingPathComponent:fullAppendPath]];
	}

	// Let NSSearchPathForDirectoriesInDomains do the rest of the work.
	if (directory && domainMask) {
		NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde);

		if (externalRelativePath) {
			NSString *pathToAppend = [NSString pathWithComponents:externalRelativePath];

			NSString *path;

			for (path in searchPaths) {
				[dirs addObject:[path stringByAppendingPathComponent:pathToAppend]];
			}
		} else {
			[dirs addObjectsFromArray:searchPaths];
		}
		
		/* If we are retrieving directories in the user domain, be sure to include the current Adium app support folder, which
		 * may not be covered above if we are installed as Portable Adium
		 */
		if (adiumResourceName &&
			((domainMask & NSUserDomainMask) != 0)) {
			NSString *path = [[adium applicationSupportDirectory] stringByAppendingPathComponent:adiumResourceName];

			if (![dirs containsObject:path]) {
				//Our application support directory should always be first
				if ([dirs count]) {
					[dirs insertObject:path atIndex:0];
				} else {
					[dirs addObject:path];			
				}
			}
		}
	}

	return dirs;
}
