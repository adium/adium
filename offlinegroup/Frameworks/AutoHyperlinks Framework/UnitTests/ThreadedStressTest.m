//
//  ThreadedStressTest.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 6/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ThreadedStressTest.h"
#import "AutoHyperlinks.h"

#define LOOP_COUNT 10
#define THREAD_COUNT 10

@implementation ThreadedStressTest
-(void) threadedStressTest
{
	NSThread* threads[THREAD_COUNT];
	long completed = 0;
	
	for(long i = 0; i < THREAD_COUNT; i++)
	{
		threads[i] = [[[NSThread alloc] initWithTarget:self selector:@selector(performLinkTest:) object:nil] autorelease];
		[threads[i] setName:[NSString stringWithFormat:@"Thread %i",i]];
	}
	
	for(long i = 0; i < THREAD_COUNT; i++)
	{
		[threads[i] start];
	}
	
	reloop:
	for(long i = 0; i < THREAD_COUNT; i++)
	{
		if(![threads[i] isFinished]) {
			[NSThread sleepForTimeInterval:.1];
			goto reloop;
		}
	}
	return;
}

-(void) performLinkTest:(id)object
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSError				*error = nil;
	NSString			*stressString = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:TEST_URIS_FILE_PATHNAME] encoding:NSUTF8StringEncoding error:&error];
	STAssertNil(error, @"stringWithContentsOfFile:encoding:error: could not read file at path '%s': %@", TEST_URIS_FILE_PATHNAME, error);

	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithString:stressString];
	NSAttributedString	*attrString;
	
	int i = LOOP_COUNT;
	while(i > 0) {
		attrString = [scanner linkifiedString];
		i--;
	}
	[pool release];
}
@end
