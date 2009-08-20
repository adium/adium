//
//  AIPasteboardAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 5/26/08.
//

#import "AIPasteboardAdditions.h"

@implementation NSPasteboard (AIPasteboardAdditions)

- (NSArray *)filesFromITunesDragPasteboard
{
	NSString		*fileURLPath;
	NSMutableArray  *filePaths = [NSMutableArray array];
	NSDictionary	*iTunesDict = [self propertyListForType:AIiTunesTrackPboardType];
	NSEnumerator	*enumerator = [[[[iTunesDict objectForKey:@"Tracks"] allValues] valueForKeyPath:@"@distinctUnionOfObjects.Location"] objectEnumerator];

	while ((fileURLPath = [enumerator nextObject])) {
		[filePaths addObject:[[NSURL URLWithString:fileURLPath] path]];
	}
	
	return filePaths;
}

@end
