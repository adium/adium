//
//  AIApplication.h
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//


@class AIStatus;

@interface AIApplication : NSApplication {

}
- (void)insertInStatuses:(AIStatus *)status atIndex:(unsigned int)i;
- (void)removeFromStatusesAtIndex:(unsigned int)i;
- (void)replaceInStatuses:(AIStatus *)status atIndex:(unsigned int)i;
@end
