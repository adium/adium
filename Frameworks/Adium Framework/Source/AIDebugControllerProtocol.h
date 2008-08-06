/*
 *  AIDebugControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@protocol AIDebugController <AIController>
#ifdef DEBUG_BUILD
	- (void)addMessage:(NSString *)actualMessage;
	- (NSArray *)debugLogArray;
	- (void)clearDebugLogArray;
#endif
@end
