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

#import "AIBundleAdditions.h"
#import "AIApplicationAdditions.h"

@interface NSBundle (LionCompatibility)

- (NSImage *)imageForResource:(NSString *)name;

@end

@implementation NSBundle (AIBundleAdditions)

- (NSString *)name
{
	NSDictionary	*info = [self localizedInfoDictionary];
	NSString		*label = [info objectForKey:@"CFBundleName"];
	
	if (!label) {
		label = [self objectForInfoDictionaryKey:@"CFBundleName"];
	}
	
	if (!label) {
		label = [self bundleIdentifier];
	}
	
	return label;
}

/*
 * @brief Return the extensions of all document types which are supported by this bundle
 */
- (NSSet *)supportedDocumentExtensions
{
	NSMutableSet	*supportedDocumentTypes = [NSMutableSet set];
	NSArray			*documentTypes = [[self infoDictionary] objectForKey:@"CFBundleDocumentTypes"];
	
	//Look at each dictionary in turn
	[documentTypes enumerateObjectsUsingBlock:^(id documentType, NSUInteger idx, BOOL *stop) {
		//The @"CFBundleTypeExtensions" key yields an NSArray of supported extensions
		NSArray	*extensions = [documentType objectForKey:@"CFBundleTypeExtensions"];
		if (extensions) {
			[supportedDocumentTypes addObjectsFromArray:extensions];
		}
	}];

	return supportedDocumentTypes;
}



- (NSImage *)AI_imageForResource:(NSString *)resource
{
	if ([NSApp isOnLionOrNewer]) {
		resource = [resource stringByDeletingPathExtension];
		
		return [self imageForResource:resource];
	} else {
		return [[[NSImage alloc] initByReferencingFile:[self pathForImageResource:resource]] autorelease];
	}
}

@end
