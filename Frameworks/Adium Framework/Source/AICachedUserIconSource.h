//
//  AICachedUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Adium/AIUserIcons.h>

@interface AICachedUserIconSource : NSObject <AIUserIconSource> {
	
}

+ (BOOL)cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSData *)cachedUserIconDataForObject:(AIListObject *)inObject;

@end
