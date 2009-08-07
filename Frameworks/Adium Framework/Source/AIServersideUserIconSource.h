//
//  AIServersideUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Adium/AIUserIcons.h>

@interface AIServersideUserIconSource : NSObject <AIUserIconSource> {
	NSMutableDictionary *serversideIconDataCache;
	BOOL				gettingServersideData;
}

- (void)setServersideUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSData *)serversideUserIconDataForObject:(AIListObject *)inObject;

@end
