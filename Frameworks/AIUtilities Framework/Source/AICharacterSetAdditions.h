//
//  AICharacterSetAdditions.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/27/06.
//

#import <Cocoa/Cocoa.h>

@interface NSCharacterSet (AICharacterSetAdditions)
- (NSCharacterSet *)immutableCopy;
@end
