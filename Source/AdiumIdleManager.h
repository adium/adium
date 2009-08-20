//
//  AdiumIdleManager.h
//  Adium
//
//  Created by Evan Schoenberg on 7/5/05.
//


@interface AdiumIdleManager : NSObject {
	BOOL					machineIsIdle;
	CFTimeInterval			lastSeenIdle;
	NSTimer					*idleTimer;	
}

@end
