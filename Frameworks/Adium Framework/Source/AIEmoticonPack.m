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

#import <Adium/AIEmoticon.h>
#import <Adium/AIEmoticonPack.h>
#import <Adium/AIEmoticonControllerProtocol.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

#define EMOTICON_PATH_EXTENSION			@"emoticon"
#define EMOTICON_PACK_TEMP_EXTENSION	@"AdiumEmoticonOld"

#define EMOTICON_PLIST_FILENAME	   		@"Emoticons.plist"
#define EMOTICON_PACK_VERSION			@"AdiumSetVersion"
#define EMOTICON_LIST					@"Emoticons"

#define EMOTICON_EQUIVALENTS			@"Equivalents"
#define EMOTICON_NAME					@"Name"

#define	EMOTICON_SERVICE_CLASS			@"Service Class"

#define EMOTICON_LOCATION				@"Location"
#define EMOTICON_LOCATION_SEPARATOR		@"////"

@interface AIEmoticonPack ()
- (AIEmoticonPack *)initFromPath:(NSString *)inPath;
- (void)loadEmoticons;
- (void)loadAdiumEmoticons:(NSDictionary *)emoticons localizedStrings:(NSDictionary *)localizationDict;
- (void)loadProteusEmoticons:(NSDictionary *)emoticons;
- (void)_upgradeEmoticonPack:(NSString *)packPath;
- (NSString *)_imagePathForEmoticonPath:(NSString *)inPath;
- (NSArray *)_equivalentsForEmoticonPath:(NSString *)inPath;
- (NSString *)_stringWithMacEndlines:(NSString *)inString;
@end


/*!
 * @class AIEmoticonPack
 * @brief Class to encapsulate an emoticon pack, which is a themed collection of emoticons
 *
 * An emoticon pack must have a name and a set of one or more emoticons (AIEmoticon objects).
 * It may also have a serviceClass, which indicates the class of a service upon which its emoticons are preferred.
 * For example, a set of MSN emoticons would have a service class of @"MSN".
 */
@implementation AIEmoticonPack

/*!
 * @brief Create a new emoticon pack
 * @param inPath The path to the root of a bundle of emoticons
 */
+ (id)emoticonPackFromPath:(NSString *)inPath
{
    return [[[self alloc] initFromPath:inPath] autorelease];
}

//Init
- (AIEmoticonPack *)initFromPath:(NSString *)inPath
{
    if ((self = [super init])) {
		path = [inPath retain];

		bundle = [[NSBundle bundleWithPath:path] retain];

		/*
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1)) {
			//This checks for a new-style xtra
			//New style xtras store the same info, but it's in Contents/Resources/ so that we can have an info.plist file and use NSBundle.
			emoticonLocation = [[xtraBundle resourcePath] retain];
		} 
		 */

		NSString *localizedName;
		name = [[path lastPathComponent] stringByDeletingPathExtension];
		if ((localizedName = [[bundle localizedInfoDictionary] objectForKey:name])) {
			name = localizedName;
		}
		[name retain];

		emoticonArray = nil;
		enabledEmoticonArray = nil;
		
		enabled = NO;
	}
    
    return self;
}

//Dealloc
- (void)dealloc
{
    [path release];
	[bundle release];
    [name release];
    [emoticonArray release];
	[enabledEmoticonArray release];
	[serviceClass release];

    [super dealloc];
}

/*!
 * @brief Name, for display to the user
 */
- (NSString *)name
{
    return name;
}

/*!
 * @brief Path to this emoticon pack
 */
- (NSString *)path
{
    return path;
}

/*!
 * @brief Service class of this emoticon pack
 *
 * @result A service class, or nil if the emoticon pack is not associated with any service class
 */
- (NSString *)serviceClass
{
	return serviceClass;
}

/*!
 * @brief An array of AIEmoticon objects
 */
- (NSArray *)emoticons
{
	if (!emoticonArray) [self loadEmoticons];
	return emoticonArray;
}

/*!
 * @brief An array of enabled AIEmoticon objects
 */
- (NSArray *)enabledEmoticons
{
	if (!enabledEmoticonArray)
		enabledEmoticonArray = [[self.emoticons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isEnabled == TRUE"]] retain];
	
	return enabledEmoticonArray;
}

/*!
 * @brief Return the preview image to use within a menu for this emoticon
 *
 * It tries to be the emoticon for text equivalent :) or :-). Failing that, any emoticon will do.
 */
- (NSImage *)menuPreviewImage
{
	NSArray		 *myEmoticons = [self emoticons];
	AIEmoticon	 *emoticon;

	for (emoticon in myEmoticons) {
		NSArray *equivalents = [emoticon textEquivalents];
		if ([equivalents containsObject:@":)"] || [equivalents containsObject:@":-)"]) {
			break;
		}
	}

	//If we didn't find a happy emoticon, use the first one in the array
	if (!emoticon && [myEmoticons count]) {
		emoticon = [myEmoticons objectAtIndex:0];
	}

	return [[emoticon image] imageByScalingForMenuItem];
}

/*!
 * @brief Set the emoticons that are disabled in this pack
 * @param inArray An NSArray of AIEmoticon objects to disable
 */
- (void)setDisabledEmoticons:(NSArray *)inArray
{
    //Flag our emoticons as enabled/disabled
    for (AIEmoticon *emoticon in self.emoticons) {
        [emoticon setEnabled:(![inArray containsObject:[emoticon name]])];
    }
	
	//reset the emabled emoticon list
	if (enabledEmoticonArray) {
		[enabledEmoticonArray release];
		enabledEmoticonArray = nil;
	}
}

/*!
 * @brief Enable/Disable this pack
 * @param inEnabled Should this pack be enabled?
 */
- (void)setIsEnabled:(BOOL)inEnabled
{
	enabled = inEnabled;
}

/*!
 * @brief Is this pack enabled?
 */
- (BOOL)isEnabled{
	return enabled;
}

//Copying --------------------------------------------------------------------------------------------------------------
#pragma mark Copying
//Copy
- (id)copyWithZone:(NSZone *)zone
{
    AIEmoticonPack	*newPack = [[AIEmoticonPack alloc] initFromPath:path];   

	newPack->emoticonArray = [emoticonArray mutableCopy];
	newPack->serviceClass = [serviceClass retain];
	newPack->path = [path retain];
	newPack->bundle = [bundle retain];
	newPack->name = [name retain];

    return newPack;
}

//Loading Emoticons ----------------------------------------------------------------------------------------------------
#pragma mark Loading Emoticons
/*!
 * @brief Load the emoticons in this pack.
 *
 * Called by [self emoticons] as needed
 */
- (void)loadEmoticons
{
	[emoticonArray release]; emoticonArray = [[NSMutableArray alloc] init];
	[serviceClass release]; serviceClass = nil;

	//
	NSString		*infoDictPath = [bundle pathForResource:EMOTICON_PLIST_FILENAME ofType:nil];
	NSDictionary	*infoDict = [NSDictionary dictionaryWithContentsOfFile:infoDictPath];
	NSDictionary	*localizedInfoDict = [bundle localizedInfoDictionary];

	//If no info dict was found, assume that this is an old emoticon pack and try to upgrade it
	if (!infoDict) {
		AILog(@"Upgrading Emoticon Pack %@ at %@...", self, bundle);
		[self _upgradeEmoticonPack:path];
		infoDict = [NSDictionary dictionaryWithContentsOfFile:infoDictPath];
		[bundle release]; bundle = [[NSBundle bundleWithPath:path] retain];
	}

	//Load the emoticons
	if (infoDict) {
		/* Handle optional location key, which allows emoticons to be loaded
		 * from arbitrary directories. This is only used by the iChat emoticon
		 * pack.
		 */
		id possiblePaths = [infoDict objectForKey:EMOTICON_LOCATION];
		if (possiblePaths) {
			if ([possiblePaths isKindOfClass:[NSString class]]) {
				possiblePaths = [NSArray arrayWithObjects:possiblePaths, nil];
			}

			NSEnumerator *pathEnumerator = [possiblePaths objectEnumerator];
			NSString *aPath;

			while ((aPath = [pathEnumerator nextObject])) {
				NSString *possiblePath;
				NSArray *splitPath = [aPath componentsSeparatedByString:EMOTICON_LOCATION_SEPARATOR];

				/* Two possible formats:
				 *
				 * <string>/absolute/path/to/directory</string>
				 * <string>CFBundleIdentifier////relative/path/from/bundle/to/directory</string>
				 *
				 * The separator in the latter is ////, defined as EMOTICON_LOCATION_SEPARATOR.
				 */
				if ([splitPath count] == 1) {
					possiblePath = [splitPath objectAtIndex:0];
				} else {
					NSArray *components = [NSArray arrayWithObjects:
						[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[splitPath objectAtIndex:0]],
						[splitPath objectAtIndex:1],
						nil];
					possiblePath = [NSString pathWithComponents:components];
				}

				/* If the directory exists, then we've found the location. If we
				 * make it all the way through the list without finding a valid
				 * directory, then the standard location will be used.
				 */
				BOOL isDir;
				if ([[NSFileManager defaultManager] fileExistsAtPath:possiblePath isDirectory:&isDir] && isDir) {
					[bundle release];
					bundle = [[NSBundle bundleWithPath:possiblePath] retain];
					break;
				}
			}
		}

		int version = [[infoDict objectForKey:EMOTICON_PACK_VERSION] intValue];
		
		switch (version) {
			case 0: [self loadProteusEmoticons:infoDict]; break;
			case 1: [self loadAdiumEmoticons:[infoDict objectForKey:EMOTICON_LIST] localizedStrings:localizedInfoDict]; break;
			default: break;
		}
		
		serviceClass = [[infoDict objectForKey:EMOTICON_SERVICE_CLASS] retain];
		if (!serviceClass) {
			if ([name rangeOfString:@"AIM"].location != NSNotFound) {
				serviceClass = [@"AIM-compatible" retain];
			} else if ([name rangeOfString:@"MSN"].location != NSNotFound) {
				serviceClass = [@"MSN" retain];
			} else if ([name rangeOfString:@"Yahoo"].location != NSNotFound) {
				serviceClass = [@"Yahoo!" retain];
			}
		}
	}
	
	//Sort the emoticons in this pack using the AIEmoticon compare: selector
	[emoticonArray sortUsingSelector:@selector(compare:)];
}

/*!
 * @brief Load an Adium version 1 emoticon pack
 *
 * @param emoticons A dictionary whose keys are file names and objects are themselves dictionaries with equivalent and name information.
 */
- (void)loadAdiumEmoticons:(NSDictionary *)emoticons localizedStrings:(NSDictionary *)localizationDict
{
	__block NSBundle	*myBundle = nil;

	[emoticons enumerateKeysAndObjectsUsingBlock:^(id fileName, id dict, BOOL *stop) {
		if ([dict isKindOfClass:[NSDictionary class]]) {
			NSString *emoticonName = [(NSDictionary *)dict objectForKey:EMOTICON_NAME];
			NSString *localizedEmoticonName = nil;

			if (emoticonName) {
				if (localizationDict) {
					//If the bundle provides localizations, use them
					localizedEmoticonName = [localizationDict objectForKey:emoticonName];
				} 

				if (!localizedEmoticonName) {
					if (!myBundle) myBundle = [NSBundle bundleForClass:[self class]];

					//Otherwise, look at our list of default translations (generated at the bottom of this file)
					localizedEmoticonName = [myBundle localizedStringForKey:emoticonName
																	  value:emoticonName
																	  table:@"EmoticonNames"];
				}
				
				if (localizedEmoticonName)
					emoticonName = localizedEmoticonName;
			}

			[emoticonArray addObject:[AIEmoticon emoticonWithIconPath:[bundle pathForImageResource:fileName]
														  equivalents:[(NSDictionary *)dict objectForKey:EMOTICON_EQUIVALENTS]
																 name:emoticonName
																 pack:self]];
		}
	}];
}

/*!
 * @brief Load a Proteus emoticon pack
 */
- (void)loadProteusEmoticons:(NSDictionary *)emoticons
{
	[emoticons enumerateKeysAndObjectsUsingBlock:^(id fileName, id dict, BOOL *stop) {
		[emoticonArray addObject:[AIEmoticon emoticonWithIconPath:[bundle pathForImageResource:fileName]
													  equivalents:[dict objectForKey:@"String Representations"]
															 name:[dict objectForKey:@"Meaning"]
															 pack:self]];
	}];
}

/*!
 * @brief Flush any cached emoticon images (and image attachment strings)
 */
- (void)flushEmoticonImageCache
{
    //Flag our emoticons as enabled/disabled
    for (AIEmoticon *emoticon in self.emoticons) {
        [emoticon flushEmoticonImageCache];
    }
}


//Upgrading ------------------------------------------------------------------------------------------------------------
//Methods for opening and converting old format Adium emoticon packs
#pragma mark Upgrading
/*!
 * @brief Upgrade an emoticon pack from the old format (where every emoticon is a separate file) to the new format
 */
- (void)_upgradeEmoticonPack:(NSString *)packPath
{
	NSString				*packName, *workingDirectory, *tempPackName, *tempPackPath, *fileName;
	NSDirectoryEnumerator   *enumerator;
	NSFileManager           *mgr = [NSFileManager defaultManager];
	NSMutableDictionary		*infoDict = [NSMutableDictionary dictionary];
	NSMutableDictionary		*emoticonDict = [NSMutableDictionary dictionary];
	
	//
	packName = [[packPath lastPathComponent] stringByDeletingPathExtension];
	workingDirectory = [packPath stringByDeletingLastPathComponent];
	
	//Rename the existing pack to .AdiumEmoticonOld
	tempPackName = [packName stringByAppendingPathExtension:EMOTICON_PACK_TEMP_EXTENSION];
	tempPackPath = [workingDirectory stringByAppendingPathComponent:tempPackName];
	[mgr moveItemAtPath:packPath toPath:tempPackPath error:NULL];
	
	//Create ourself a new pack
	[mgr createDirectoryAtPath:packPath withIntermediateDirectories:YES attributes:nil error:NULL];
	
	//Version this pack as 1
	[infoDict setObject:[NSNumber numberWithInt:1] forKey:EMOTICON_PACK_VERSION];
	
	//Process all .emoticons in the old pack
	enumerator = [[NSFileManager defaultManager] enumeratorAtPath:tempPackPath];
	while ((fileName = [enumerator nextObject])) {        
		if ([[fileName lastPathComponent] characterAtIndex:0] != '.' &&
		   [[fileName pathExtension] caseInsensitiveCompare:EMOTICON_PATH_EXTENSION] == NSOrderedSame) {
			NSString        *emoticonPath = [tempPackPath stringByAppendingPathComponent:fileName];
			BOOL            isDirectory;
			
			//Ensure that this is a folder and that it is non-empty
			[mgr fileExistsAtPath:emoticonPath isDirectory:&isDirectory];
			if (isDirectory) {
				NSString	*emoticonName = [fileName stringByDeletingPathExtension];
				
				//Get the text equivalents out of this .emoticon
				NSArray		*emoticonStrings = [self _equivalentsForEmoticonPath:emoticonPath];
				
				//Get the image out of this .emoticon
				NSString 	*imagePath = [self _imagePathForEmoticonPath:emoticonPath];
				NSString	*imageExtension = [imagePath pathExtension];
				
				if (emoticonStrings && imagePath) {
					NSString	*newImageName = [emoticonName stringByAppendingPathExtension:imageExtension];
					
					//Move the image into our new pack (with a unique name)
					NSString	*newImagePath = [packPath stringByAppendingPathComponent:newImageName];
					[mgr copyItemAtPath:imagePath toPath:newImagePath error:NULL];
					
					//Add to our emoticon plist
					[emoticonDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
											 emoticonStrings, EMOTICON_EQUIVALENTS,
											 emoticonName, EMOTICON_NAME, nil] 
									 forKey:newImageName];
				}
			}
		}
	}
	
	//Write our plist to the new pack
	[infoDict setObject:emoticonDict forKey:EMOTICON_LIST];
	[infoDict writeToFile:[packPath stringByAppendingPathComponent:EMOTICON_PLIST_FILENAME] atomically:NO];
	
	//Move the old/temp pack to the trash
	[mgr trashFileAtPath:tempPackPath];
}

/*!
 * @brief Path to an emoticon image
 *
 * @param Path within which to search for a file whose name starts with "Emoticon"
 */
- (NSString *)_imagePathForEmoticonPath:(NSString *)inPath
{
    NSDirectoryEnumerator   *enumerator;
    NSString		    	*fileName;
    
    //Search for the file named Emoticon in our bundle (It can be in any image format)
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:inPath];
    while ((fileName = [enumerator nextObject])) {
		if ([fileName hasPrefix:@"Emoticon"]) return [inPath stringByAppendingPathComponent:fileName];
    }
    
    return nil;
}

/*!
 * @brief Retrieve the text equivalents from a pack
 */
- (NSArray *)_equivalentsForEmoticonPath:(NSString *)inPath
{
	NSURL		*equivFileURL = [NSURL fileURLWithPath:[inPath stringByAppendingPathComponent:@"TextEquivalents.txt"]];
	NSArray 	*textEquivalents = nil;
	
	//Fetch the text equivalents
	NSString *equivString = [NSMutableString stringWithContentsOfURL:equivFileURL encoding:NSUTF8StringEncoding error:NULL];
	if (equivString) {		
		//Convert the text file into an array of strings		
		equivString = [self _stringWithMacEndlines:equivString];
		textEquivalents = [equivString componentsSeparatedByString:@"\r"];
	}
	
	return textEquivalents;
}

/*!
 * @brief Convert any unix/windows line endings to mac line endings
 * @result The converted string
 */
- (NSString *)_stringWithMacEndlines:(NSString *)inString
{
    NSCharacterSet      *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSMutableString     *newString = nil; //We avoid creating a new string if not necessary
    NSRange             charRange;
    
    //Step through all the invalid endlines
    charRange = [inString rangeOfCharacterFromSet:newlineSet];
    while (charRange.length != 0) {
        if (!newString) newString = [[inString mutableCopy] autorelease];
		
        //Replace endline and continue
        [newString replaceCharactersInRange:charRange withString:@"\r"];
        charRange = [newString rangeOfCharacterFromSet:newlineSet];
    }
    
    return newString ? newString : inString;
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"[%@: %@, ServiceClass %@]",[super description], [self name], self.serviceClass]);
}

/* Localized emoticon names, listed here for genstrings:

AILocalizedStringFromTable(@"Angry", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Blush", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Cry", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Scared", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Sad", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Gasp", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Grin", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Angel", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Kiss", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Lips Are Sealed", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Money-mouth", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Smile", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Sticking Out Tongue", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Erm", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Cool", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Wink", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Foot In Mouth", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Frown", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Confused", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Halo", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Undecided", "EmoticonNames", "Emoticon name")
AILocalizedStringFromTable(@"Embarrassed", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Baring Teeth", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Crying", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Disappointed", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Don't Tell Anyone", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Happy", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Heart", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"I Don't Know", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Nerd", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Open Mouthed", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Party", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Sarcastic", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Sick", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Sleepy", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Star", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Surprised", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Thinking", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Tongue Out", "EmoticonNames", "Emoticon name")
 AILocalizedStringFromTable(@"Wearing Sunglasses", "EmoticonNames", "Emoticon name")
*/

@end
