//
//  AIApplication.h
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//


@class AIStatus;

@interface AIApplication : NSApplication {

}
- (void)insertInStatuses:(AIStatus *)status atIndex:(NSUInteger)i;
- (void)removeFromStatusesAtIndex:(NSUInteger)i;
- (void)replaceInStatuses:(AIStatus *)status atIndex:(NSUInteger)i;
@end
