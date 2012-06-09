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

#import "AIXtraInfo.h"
#import <Adium/AIDockControllerProtocol.h>
#import "AIIconState.h"

@implementation AIXtraInfo

- (NSString *)type
{
	return type;
}

- (NSString *)name
{
	return name;
}

- (NSString *)version
{
	return version;
}

- (void) setName:(NSString *)inName
{
	if(!inName) name = @"Unnamed Xtra";
	else {
		name = inName;
	}
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@, %@, %@, retaincount=%u", [self name], [self path], [self type], 0];
}

+ (AIXtraInfo *) infoWithURL:(NSURL *)url
{
	return [[self alloc] initWithURL:url];
}

- (id) initWithURL:(NSURL *)url
{
	if((self = [super init]))
	{
		path = [url path];
		type = [[[url path] pathExtension] lowercaseString];
		xtraBundle = [[NSBundle alloc] initWithPath:path];
		version = [xtraBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) { //This checks for a new-style xtra
			[self setName:[xtraBundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey]];
			resourcePath = [xtraBundle resourcePath];
			icon = [[NSImage alloc] initByReferencingFile:[xtraBundle pathForResource:@"Icon" ofType:@"icns"]];
			readMePath = [xtraBundle pathForResource:@"ReadMe" ofType:@"rtf"];
			NSString *previewImagePath = [xtraBundle pathForImageResource:@"PreviewImage"];
			if(previewImagePath)
				previewImage = [[NSImage alloc] initByReferencingFile:previewImagePath];
		}
		else {
			if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
				return nil;
			}
			[self setName:[[path lastPathComponent] stringByDeletingPathExtension]];
			resourcePath = [path copy];//root of the xtra
		}	
		if (!readMePath)
			readMePath = [[NSBundle mainBundle] pathForResource:@"DefaultXtraReadme" ofType:@"rtf"];
		if (!icon) {
			if ([[path pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
                AIIconState *previewState = [adium.dockController previewStateForIconPackAtPath:path];
				icon = [previewState image];

			} else {
				icon = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];
			}
		}
		if(!previewImage)
			previewImage = icon;
		
		/* Enabled by default */
		enabled = YES;
	}
	return self;
}

- (NSImage *) icon
{
	return icon;
}

- (NSString *)resourcePath
{
	return resourcePath;
}

- (NSString *)path
{
	return path;
}

- (NSString *)readMePath
{
	return readMePath;
}

- (NSBundle *)bundle
{
	return xtraBundle;
}

- (NSImage *)previewImage
{
	return previewImage;
}

- (BOOL)enabled
{
	return enabled;
}

- (void)setEnabled:(BOOL)inEnabled
{
	enabled = inEnabled;
}

@end
