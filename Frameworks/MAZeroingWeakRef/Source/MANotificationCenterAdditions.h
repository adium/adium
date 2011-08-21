//
//  MANotificationCenterAdditions.h
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/12/10.
//

#import <Foundation/Foundation.h>


@interface NSNotificationCenter (MAZeroingWeakRefAdditions)
#if NS_BLOCKS_AVAILABLE
- (void)addWeakObserver: (id)observer selector: (SEL)selector name: (NSString *)name object: (NSString *)object;
#endif
@end
