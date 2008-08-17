//
//  AIBundleAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//

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
