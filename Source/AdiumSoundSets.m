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

#import "AdiumSoundSets.h"
#import "AISoundController.h"
#import "AISoundSet.h"

#define SOUNDSET_RESOURCE_PATH			@"Sounds"

#define	SOUND_PACK_PATHNAME				@"AdiumSetPathname_Private"
#define	SOUND_PACK_VERSION				@"AdiumSetVersion"
#define SOUND_NAMES						@"Sounds"
#define SOUND_SET_PATH_EXTENSION		@"AdiumSoundSet"

@implementation AdiumSoundSets

/*!
 * @brief Init
 */
- (id)init {
	if ((self = [super init])) {
		//Create a custom sounds directory ~/Library/Application Support/Adium 2.0/Sounds
		[adium createResourcePathForName:SOUNDSET_RESOURCE_PATH];
	}
	
	return self;
}

/*!
 * @brief Returns all available soundsets
 *
 * @return NSArray of AISoundSet objects
 */
- (NSArray *)soundSets
{
	NSFileManager	*mgr = [NSFileManager defaultManager];
    NSMutableArray	*soundSets = [NSMutableArray array];
	
	for (NSString *path in [adium resourcePathsForName:SOUNDSET_RESOURCE_PATH]) {
		for (NSString *file in [mgr contentsOfDirectoryAtPath:path error:NULL]) {
			if([[file pathExtension] caseInsensitiveCompare:SOUND_SET_PATH_EXTENSION] == NSOrderedSame){
				NSString	*fullPath = [path stringByAppendingPathComponent:file];
				AISoundSet	*soundSet = [AISoundSet soundSetWithContentsOfFile:fullPath];
				if (soundSet) {
					[soundSets addObject:soundSet];
				}
			}
		}
	}
    
    return soundSets;
}

@end
