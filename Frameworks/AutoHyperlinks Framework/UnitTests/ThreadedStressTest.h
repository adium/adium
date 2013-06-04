//
//  ThreadedStressTest.h
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 6/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface ThreadedStressTest : SenTestCase {
	BOOL allTestsDidFinish;
}
-(void) threadedStressTest;
@end
