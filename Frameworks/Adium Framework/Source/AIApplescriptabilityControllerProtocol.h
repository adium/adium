/*
 *  AIApplescriptabilityControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@protocol AIApplescriptabilityController <AIController>
- (void)runApplescriptAtPath:(NSString *)inPath 
					function:(NSString *)function
				   arguments:(NSArray *)arguments
			 notifyingTarget:(id)target
					selector:(SEL)selector
					userInfo:(id)userInfo;
@end
