//
//  AIManuallySetUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Adium/AIUserIcons.h>

@interface AIManuallySetUserIconSource : NSObject <AIUserIconSource> {

}

- (void)setManuallySetUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSData *)manuallySetUserIconDataForObject:(AIListObject *)inObject;

@end
