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

#import <Adium/AISoundSet.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define SOUNDSET_TEMP_EXTENSION		@"AdiumSoundSetOld"
#define SOUNDSET_PLIST_FILENAME		@"Sounds.plist"

#define SOUNDSET_VERSION			@"AdiumSetVersion"
#define SOUNDSET_INFO				@"Info"
#define SOUNDSET_SOUNDS				@"Sounds"
#define SOUNDSET_SOUND_LOCATIONS	@"Location"

#define SOUND_LOCATION_SEPARATOR	@"////"

@interface AISoundSet ()
- (id)initWithContentsOfFile:(NSString *)inPath;
- (BOOL)_loadSoundSetFromPath:(NSString *)inPath;
- (NSString *)_fullPathForSoundAtLocalPath:(NSString *)localPath searchLocations:(NSArray *)locations;
- (BOOL)_upgradeTextBasedSoundSet:(NSString *)inPath;
@end

@implementation AISoundSet

#pragma mark Birth and death

/*!
 * @brief Create a new soundset object from the specified path
 */
+ (id)soundSetWithContentsOfFile:(NSString *)inPath
{
	return [[self alloc] initWithContentsOfFile:inPath];
}

/*!
 * @brief Init
 *
 * @param inPath NSString path to the .AdiumSoundSet file
 */
- (id)initWithContentsOfFile:(NSString *)inPath
{
	if ((self = [super init])) {
		//Return nil if we can't load our sound set
		if (!inPath || ![inPath length] || ![self _loadSoundSetFromPath:inPath]) {
			return nil;
		}

		sourcePath = inPath;
	}
	
	return self;
}

- (void)dealloc
{
	sourcePath = nil;
}

#pragma mark Accessors

/*!
 * @brief Returns the name of this soundSet
 */
@synthesize name;

/*!
 * @brief Returns the info for this soundSet
 *
 * @return NSString containing information about the soundset and its creator in no particular format.
 */
@synthesize info;

/*!
 * @brief Returns a dictionary of sounds
 *
 * @return NSDictionary with sound identifiers as keys and full paths as objects
 */
@synthesize sounds;

#pragma mark Private methods

/*!
 * @brief Initialize this object from a soundset at the given path
 *
 * @param inPath NSString path to the .AdiumSoundSet file
 * @return YES if succesful
 */
- (BOOL)_loadSoundSetFromPath:(NSString *)inPath
{
	BOOL	success = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:inPath]) return NO;
	NSBundle * xtraBundle = [NSBundle bundleWithPath:inPath];
	if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1)) {
		inPath = [xtraBundle resourcePath];
		name = [xtraBundle objectForInfoDictionaryKey:@"CFBundleName"];
	}
	
	//If we don't have a Sound.plist, assume this is an old format soundset and attempt to upgrade it
	NSString *soundPlistPath = [inPath stringByAppendingPathComponent:SOUNDSET_PLIST_FILENAME];
	if (![[NSFileManager defaultManager] fileExistsAtPath:soundPlistPath]) {
		if (![self _upgradeTextBasedSoundSet:inPath]) {
			NSString		*currentFolder = [inPath stringByDeletingLastPathComponent];
			NSString		*oldFolderName = [currentFolder lastPathComponent];
			NSString		*newFolderName = [oldFolderName stringByAppendingString:@" (Disabled)"];
			NSString		*newFolder = [[currentFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFolderName];
			NSFileManager	*mgr = [NSFileManager defaultManager];
			
			//Move the sound pack into a folder with the same name as its parent folder, but with (Disabled) after it
			[mgr createDirectoryAtPath:newFolder withIntermediateDirectories:YES attributes:nil error:NULL];
			[mgr moveItemAtPath:inPath
				   toPath:[newFolder stringByAppendingPathComponent:[inPath lastPathComponent]]
				  error:NULL];

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-security"
			NSRunAlertPanel(AILocalizedString(@"Sound set upgrade failed", nil),
							[NSString stringWithFormat:AILocalizedString(@"This version of Adium uses a new format for sound sets. Adium was not able to update the sound set %@ located at %@. It has been disabled.", nil),
								[[inPath lastPathComponent] stringByDeletingPathExtension],
								inPath],
							nil, nil, nil);
#pragma GCC diagnostic pop
			success = NO;
		}
	}
	
	//Load the sound set
	if (success) {
		NSDictionary 	*soundSet = [NSDictionary dictionaryWithContentsOfFile:soundPlistPath];	
		int				version = [[soundSet objectForKey:SOUNDSET_VERSION] intValue];
		
		if (version == 1) {			
			//Retrieve the set name and information
			if(!name) //this will have been set from info.plist if it's a new-format xtra
				name = [[inPath lastPathComponent] stringByDeletingPathExtension];
			info = [soundSet objectForKey:SOUNDSET_INFO];
			
			//Search locations.  If none are provided, search within the soundset folder.
			NSArray *locations = [soundSet objectForKey:SOUNDSET_SOUND_LOCATIONS];
			if(!locations) locations = [NSArray arrayWithObject:inPath];
			
			//Retrieve the sound keys and paths, converting local paths to full paths
			NSDictionary *localSounds = [soundSet objectForKey:SOUNDSET_SOUNDS];
			sounds = [[NSMutableDictionary alloc] init];
			
			for (NSString *key in [localSounds keyEnumerator]) {
				[(NSMutableDictionary *)sounds setObject:[[self _fullPathForSoundAtLocalPath:[localSounds objectForKey:key]
													  searchLocations:locations] stringByCollapsingBundlePath]
						   forKey:key];
			}
			
		} else {
			NSRunAlertPanel(AILocalizedString(@"Cannot open sound set", nil),
							AILocalizedString(@"The sound set %@ is version %i, and this version of Adium does not know how to handle that; perhaps try a later version of Adium.", nil),
							/*defaultButton*/ nil, /*alternateButton*/ nil, /*otherButton*/ nil,
							[soundPlistPath lastPathComponent], version);
			
			success = NO;
		}
	}

	return success;
}

/*!
 * @brief Converts a local sound path into a full path, searching multiple locations.
 *
 * This method takes a local path and an array of locations.  If one location is passed it will simply return a full
 * path by combining the local path and location.  If multiple locations are passed it will search them for the
 * existance of the sound file specified by local path and return the full path that actually contains the sound file.
 * 
 * Locations may be in one of two possible formats:
 * 	<string>/absolute/path/to/directory</string>
 * 	<string>CFBundleIdentifier////relative/path/from/bundle/to/directory</string>
 *
 * The latter allows a soundSet to search within the bundle of an application for sounds.
 *
 * @param localPath NSString local path to the sound file
 * @param locations NSArray of NSString paths to search for the sound file's local path
 * @return NSString full path to the sound file
 */
- (NSString *)_fullPathForSoundAtLocalPath:(NSString *)localPath searchLocations:(NSArray *)locations
{
	//If we've been passed more than one location, scan all of them for the sound file
	if([locations count] > 1){
		NSString		*location;
		
		for(location in locations){
			NSArray		*splitPath = [location componentsSeparatedByString:SOUND_LOCATION_SEPARATOR];
			NSString	*fullPath;
			BOOL 		isDir;

			//Resolve bundle relative paths
			if ([splitPath count] == 2) {
				location = [NSString pathWithComponents:[NSArray arrayWithObjects:
					[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[splitPath objectAtIndex:0]],
					[splitPath objectAtIndex:1],
					nil]];
			}
			
			//If we found the sound file, return its path
			fullPath = [location stringByAppendingPathComponent:localPath];
			if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
				return fullPath;
			}
		}
	}

	//Otherwise (or, if we cannot find our sound file), return a path in the first location
	return [[locations lastObject] stringByAppendingPathComponent:localPath];
}

/*!
 * @brief Upgrade a sound pack from the old format (controlled by a .txt file) to the new .plist based format
 *
 * The soundSet is upgraded in place, so this should only need to be called once per soundSet.
 * @param inPath NSString path to the .AdiumSoundSet file
 * @result YES if successful
 */
- (BOOL)_upgradeTextBasedSoundSet:(NSString *)setPath
{
    NSCharacterSet		*newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSCharacterSet		*whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
	NSFileManager		*mgr = [NSFileManager defaultManager];
	NSMutableDictionary	*newSounds = [NSMutableDictionary dictionary];
	NSString			*setName, *workingDirectory, *tempSetName, *tempSetPath;
	NSString			*oldSetString, *oldSetInfo = nil;
	BOOL				success = NO;
	
	//
	setName = [[setPath lastPathComponent] stringByDeletingPathExtension];
	workingDirectory = [setPath stringByDeletingLastPathComponent];

	//Rename the existing set to .AdiumSoundSetOld
	tempSetName = [setName stringByAppendingPathExtension:SOUNDSET_TEMP_EXTENSION];
	tempSetPath = [workingDirectory stringByAppendingPathComponent:tempSetName];
	success = [mgr moveItemAtPath:setPath toPath:tempSetPath error:NULL];
	
	if (success) {
		//Create a folder for the new soundset
		success = [mgr createDirectoryAtPath:setPath withIntermediateDirectories:YES attributes:nil error:NULL];
		if (success) {
	
			//Extract the set's contents
			oldSetString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[tempSetPath stringByAppendingPathComponent:[setName stringByAppendingPathExtension:@"txt"]]]
													encoding:NSUTF8StringEncoding
													   error:NULL];
			
			if (!oldSetString || ![oldSetString length]) {
				//If we can't find a txt file with the correct name, try to use any text file
				
				oldSetString = nil;
				
				for (NSString *filename in [mgr contentsOfDirectoryAtPath:tempSetPath error:NULL]) {
					if ([[filename pathExtension] caseInsensitiveCompare:@"txt"] == NSOrderedSame) {
						oldSetString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[tempSetPath stringByAppendingPathComponent:filename]]
																encoding:NSUTF8StringEncoding
																   error:NULL];
						break;
					}
				}
			}

			if (oldSetString && [oldSetString length] != 0) {
				NSScanner	*scanner;
				
				//Setup the scanner
				scanner = [NSScanner scannerWithString:oldSetString];
				[scanner setCaseSensitive:NO];
				[scanner setCharactersToBeSkipped:whitespaceSet];
				
				//Scan the description
				[scanner scanUpToString:@"\nSoundset:\n" intoString:&oldSetInfo];
				[scanner scanString:@"\nSoundset:\n" intoString:nil];
				
				//Scan the events
				while (![scanner isAtEnd]) {
					NSString	*event;
					NSString	*path = nil;
					
					//Get the event and file name
					[scanner scanUpToString:@"\"" intoString:nil];
					[scanner scanString:@"\"" intoString:nil];
					[scanner scanUpToString:@"\"" intoString:&event];
					[scanner scanString:@"\"" intoString:nil];
					[scanner scanUpToCharactersFromSet:newlineSet intoString:&path];
					[scanner scanCharactersFromSet:newlineSet intoString:nil];
					
					//Move the sound into our new pack
					if (path && [path length]) {
						success = [mgr copyItemAtPath:[tempSetPath stringByAppendingPathComponent:path]
										 toPath:[setPath stringByAppendingPathComponent:[path lastPathComponent]]
										error:NULL];
						if (success) {
							[newSounds setObject:[path lastPathComponent] forKey:event];
						}
					}
				}
			}
			
			success = ([newSounds count] ? YES : NO);
		}

		//Generate and save a Sounds.plist for the updated set
		if (success) {
			NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:1], SOUNDSET_VERSION,
				oldSetInfo, SOUNDSET_INFO,
				newSounds, SOUNDSET_SOUNDS,
				nil];
			success = [infoDict writeToFile:[setPath stringByAppendingPathComponent:SOUNDSET_PLIST_FILENAME] 
								 atomically:NO];
		}
	}

	if (success) {
		//Trash the old soundset
		[mgr trashFileAtPath:tempSetPath];
	} else {
		//Trash the empty folder we created
		[mgr trashFileAtPath:setPath];
		
		//Move the unconverted sound set back to its original location
		[mgr moveItemAtPath:tempSetPath toPath:setPath error:NULL];	
	}
	
	return success;
}

#pragma mark Dictionary storage

/*!
 * @brief Two sound sets are considered equal if they are pointing to the same .AdiumSoundset bundle
 */
- (BOOL)isEqual:(id)otherObject
{
	return ([otherObject isKindOfClass:[self class]] && [otherObject hash] == [self hash]);
}

/*!
 * @brief Because we defined equality based on our sourcePath, the sourcePath's hash is an easy hash for us to use
 */
- (NSUInteger)hash
{
	return [sourcePath hash];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p - %@: %li sounds at %@>", NSStringFromClass([self class]), self, self.name, [self.sounds count], sourcePath];
}
@end
