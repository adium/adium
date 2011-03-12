#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>
#import "ThreadedStressTest.h"

#include <stdlib.h>
#include <stdio.h>
#include <sysexits.h>

int main(int argc, char **argv) {
	NSUInteger numIterations = 1U;
	if (*++argv) {
		//We have at least one argument. Interpret it as the number of times to run the test.
		numIterations = strtoul(*argv, /*next*/ NULL, /*radix*/ 0);
		if (numIterations == 0U) {
			fprintf(stderr, "Could not interpret number of iterations: %s\n", *argv);
			return EX_USAGE;
		}
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	ThreadedStressTest *test = [[[ThreadedStressTest alloc] initWithSelector:@selector(threadedStressTest)] autorelease];
	SenTestRun *run = [[[SenTestRun alloc] initWithTest:test] autorelease];

	NSDate *startDate, *endDate;

	startDate = [NSDate date];
	[run start];
	while (numIterations--) {
		[test performTest:run];
	}
	[run stop];
	endDate = [NSDate date];

	BOOL success = [run hasSucceeded];
	NSLog(@"Test %@ in %f seconds", success ? @"succeeded" : @"failed", [endDate timeIntervalSinceDate:startDate]);

	[pool drain]; //Glug glug glug

	return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
