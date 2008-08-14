//
//  AdiumApplescriptRunner.m
//  Adium
//
//  Created by Evan Schoenberg on 4/29/06.
//

#import "AdiumApplescriptRunner.h"

@implementation AdiumApplescriptRunner
- (id)init
{
	if ((self = [super init])) {
		NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptRunnerIsReady:)
											  name:@"AdiumApplescriptRunner_IsReady"
											object:nil];
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptRunnerDidQuit:)
											  name:@"AdiumApplescriptRunner_DidQuit"
											object:nil];
		
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptDidRun:)
											  name:@"AdiumApplescript_DidRun"
											object:nil];	
		
		//Check for an existing AdiumApplescriptRunner; if there is one, it will respond with AdiumApplescriptRunner_IsReady
		[distributedNotificationCenter postNotificationName:@"AdiumApplescriptRunner_RespondIfReady"
													 object:nil
												   userInfo:nil
										 deliverImmediately:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_Quit"
																   object:nil
																 userInfo:nil
													   deliverImmediately:NO];

	[super dealloc];
}

- (void)_executeApplescriptWithDict:(NSDictionary *)executionDict
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_ExecuteScript"
																   object:nil
																 userInfo:executionDict
													   deliverImmediately:NO];
}

- (void)launchApplescriptRunner
{
	NSString *applescriptRunnerPath = [[NSBundle mainBundle] pathForResource:@"AdiumApplescriptRunner"
																	  ofType:nil
																 inDirectory:nil];
	
	//Houston, we are go for launch.
	if (applescriptRunnerPath) {
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus err = FSPathMakeRef((UInt8 *)[applescriptRunnerPath fileSystemRepresentation], &appRef, NULL);
		if (err == noErr) {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams | kLSLaunchAsync;
			spec.asyncRefCon = NULL;
			err = LSOpenFromRefSpec(&spec, NULL);
			
			if (err != noErr) {
				NSLog(@"Could not launch %@",applescriptRunnerPath);
			}
		}
	} else {
		NSLog(@"Could not find AdiumApplescriptRunner...");
	}
}

/*!
 * @brief Run an applescript, optinally calling a function with arguments, and notify a target/selector with its output when it is done
 */
- (void)runApplescriptAtPath:(NSString *)path function:(NSString *)function arguments:(NSArray *)arguments notifyingTarget:(id)target selector:(SEL)selector userInfo:(id)userInfo
{
	NSString *uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];
	
	if (!runningApplescriptsDict) runningApplescriptsDict = [[NSMutableDictionary alloc] init];
	
	if (target && selector) {
		[runningApplescriptsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			target, @"target",
			NSStringFromSelector(selector), @"selector",
			userInfo, @"userInfo", nil]
									forKey:uniqueID];
	}

	NSDictionary *executionDict = [NSDictionary dictionaryWithObjectsAndKeys:
		path, @"path",
		(function ? function : @""), @"function",
		(arguments ? arguments : [NSArray array]), @"arguments",
		uniqueID, @"uniqueID",
		nil];
	
	if (applescriptRunnerIsReady) {
		[self _executeApplescriptWithDict:executionDict];
		
	} else {
		if (!pendingApplescriptsArray) pendingApplescriptsArray = [[NSMutableArray alloc] init];
		
		[pendingApplescriptsArray addObject:executionDict];
		
		[self launchApplescriptRunner];
	}
}

- (void)applescriptRunnerIsReady:(NSNotification *)inNotification
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary	*executionDict;
	
	applescriptRunnerIsReady = YES;
	
	for (executionDict in pendingApplescriptsArray) {
		[self _executeApplescriptWithDict:executionDict];		
	}
	
	[pendingApplescriptsArray release]; pendingApplescriptsArray = nil;
	[pool release];
}

- (void)applescriptRunnerDidQuit:(NSNotification *)inNotification
{
	applescriptRunnerIsReady = NO;
}

- (void)applescriptDidRun:(NSNotification *)inNotification
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *userInfo = [inNotification userInfo];
	NSString	 *uniqueID = [userInfo objectForKey:@"uniqueID"];

	NSDictionary *targetDict = [runningApplescriptsDict objectForKey:uniqueID];
	if (targetDict) {
		id			 target = [targetDict objectForKey:@"target"];
		//Selector will be of the form applescriptDidRun:resultString:
		SEL			 selector = NSSelectorFromString([targetDict objectForKey:@"selector"]);
		
		//Notify our target
		[target performSelector:selector
					 withObject:[targetDict objectForKey:@"userInfo"]
					 withObject:[userInfo objectForKey:@"resultString"]];
		
		//No further need for this dictionary entry
		[runningApplescriptsDict removeObjectForKey:uniqueID];
		
		if (![runningApplescriptsDict count]) {
			[runningApplescriptsDict release]; runningApplescriptsDict = nil;
		}
	}
	[pool release];
}

@end
