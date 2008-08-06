//
//  ESFileWrapperExtension.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 10 2004.
//

#import <Adium/ESFileWrapperExtension.h>

@implementation ESFileWrapperExtension

- (id)initWithPath:(NSString *)path
{
	if ((self = [super initWithPath:path])) {
		originalPath = [path copy];
	}
	
	return self;
}

- (BOOL)updateFromPath:(NSString *)path
{
	if (originalPath != path) {
		/*immutable flavours of NSString only retain when we call -copy, so
		 *	originPath may still == path even though we used -copy above.
		 */
		[originalPath release]; originalPath = [path copy];
	}
	
	return ([super updateFromPath:path]);
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomicFlag updateFilenames:(BOOL)updateNamesFlag
{
	if (updateNamesFlag) {
		if (originalPath != path) {
			/*immutable flavours of NSString only retain when we call -copy, so
			 *	originPath may still == path even though we used -copy above.
			 */
			[originalPath release]; originalPath = [path copy];
		}
	}
	
	return ([super writeToFile:path atomically:atomicFlag updateFilenames:updateNamesFlag]);
}

- (NSString *)originalPath
{
	return originalPath;
}

@end
