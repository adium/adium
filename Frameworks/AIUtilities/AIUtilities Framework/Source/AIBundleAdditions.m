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
	NSDictionary	*documentTypes = [[self infoDictionary] objectForKey:@"CFBundleDocumentTypes"];
	NSEnumerator	*documentTypesEnumerator;
	NSDictionary	*documentType;

	//Look at each dictionary in turn
	documentTypesEnumerator = [documentTypes objectEnumerator];
	while ((documentType = [documentTypesEnumerator nextObject])) {
		//The @"CFBundleTypeExtensions" key yields an NSArray of supported extensions
		NSArray	*extensions = [documentType objectForKey:@"CFBundleTypeExtensions"];
		if (extensions) {
			[supportedDocumentTypes addObjectsFromArray:extensions];
		}
	}

	return supportedDocumentTypes;
}

@end
