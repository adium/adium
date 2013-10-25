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
		[inName retain];
		[name autorelease];
		name = inName;
	}
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@, %@, %@, retaincount=%lu", [self name], [self path], [self type], [self retainCount]];
}

+ (AIXtraInfo *) infoWithURL:(NSURL *)url
{
	return [[[self alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL *)url
{
	if((self = [super init]))
	{
		path = [[url path] retain];
		type = [[[[url path] pathExtension] lowercaseString] retain];
		xtraBundle = [[NSBundle alloc] initWithPath:path];
		version = [[xtraBundle objectForInfoDictionaryKey:@"CFBundleVersion"] retain];
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1)) { //This checks for a new-style xtra
			[self setName:[xtraBundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey]];
			resourcePath = [[xtraBundle resourcePath] retain];
			icon = [[NSImage alloc] initByReferencingFile:[xtraBundle pathForResource:@"Icon" ofType:@"icns"]];
			readMePath = [[xtraBundle pathForResource:@"ReadMe" ofType:@"rtf"] retain];
			NSString *previewImagePath = [xtraBundle pathForImageResource:@"PreviewImage"];
			if(previewImagePath)
				previewImage = [[NSImage alloc] initByReferencingFile:previewImagePath];
		}
		else {
			if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
				[self autorelease];
				return nil;
			}
			[self setName:[[path lastPathComponent] stringByDeletingPathExtension]];
			resourcePath = [path copy];//root of the xtra
		}	
		if (!readMePath)
			readMePath = [[[NSBundle mainBundle] pathForResource:@"DefaultXtraReadme" ofType:@"rtf"] retain];
		if (!icon) {
			if ([[path pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
                AIIconState *previewState = [adium.dockController previewStateForIconPackAtPath:path];
				icon = [[previewState image] retain];

			} else {
				icon = [[[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]] retain];
			}
		}
		if(!previewImage)
			previewImage = [icon retain];
		
		/* Enabled by default */
		enabled = YES;
	}
	return self;
}

- (NSImage *) icon
{
	return icon;
}

- (void) dealloc
{
	[icon release];
	[previewImage release];
	[path release];
	[name release];
	[resourcePath release];
	[type release];
	[version release];
	[readMePath release];
	[super dealloc];
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
