//
//  RAOperation.h
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RAOperation : NSObject
{
}

// abstract, override this to create a concrete subclass, don't call super
- (void)run;

@end

@interface RASelectorOperation : RAOperation
{
	id	_obj;
	SEL	_sel;
	id	_arg;
	
	id	_result;
}

- (id)initWithTarget: (id)obj selector: (SEL)sel object: (id)arg;

- (id)result;

@end

@class RALatchTrigger;
@interface RAWaitableSelectorOperation : RASelectorOperation
{
	RALatchTrigger*	_trigger;
}

- (void)waitUntilDone;

@end
