/*
 *  AIDebugControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@protocol AIDebugController <AIController>
	- (void)addMessage:(NSString *)actualMessage;
@property (nonatomic, readonly) NSArray *debugLogArray;
	- (void)clearDebugLogArray;
@end
