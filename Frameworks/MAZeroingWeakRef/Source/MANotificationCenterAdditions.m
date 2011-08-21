//
//  MANotificationCenterAdditions.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/12/10.
//

#import "MANotificationCenterAdditions.h"

#import "MAZeroingWeakRef.h"


@implementation NSNotificationCenter (MAZeroingWeakRefAdditions)

#if NS_BLOCKS_AVAILABLE

- (void)addWeakObserver: (id)observer selector: (SEL)selector name: (NSString *)name object: (NSString *)object
{
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: observer];
    
    id noteObj = [self addObserverForName: name object:object queue: nil usingBlock: ^(NSNotification *note) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        id anObserver = [ref target];
        [anObserver performSelector: selector withObject: note];
        
        [pool release];
    }];
    
    [ref setCleanupBlock: ^(id target) {
        [self removeObserver: noteObj];
        [ref autorelease];
    }];
}

#endif

@end
