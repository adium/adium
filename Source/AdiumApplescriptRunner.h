//
//  AdiumApplescriptRunner.h
//  Adium
//
//  Created by Evan Schoenberg on 4/29/06.
//


@interface AdiumApplescriptRunner : NSObject {
	NSMutableDictionary	*runningApplescriptsDict;
	NSMutableArray		*pendingApplescriptsArray;
	BOOL				applescriptRunnerIsReady;	
}

- (void)runApplescriptAtPath:(NSString *)path
					function:(NSString *)function
				   arguments:(NSArray *)arguments
			 notifyingTarget:(id)target
					selector:(SEL)selector
					userInfo:(id)userInfo;
@end
