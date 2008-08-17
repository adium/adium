#import <Foundation/Foundation.h>
#import "DPSVNLogParser.h"
#import "NSStringAdditions.h"
#import "NSTaskAdditions.h"


@interface DPChangeLogBuilder : NSObject

- (void)parserWillBeginParsing:(DPSVNLogParser *)parser;
- (void)parser:(DPSVNLogParser *)parser parsedChangelog:(NSDictionary *)log;

@end

@implementation DPChangeLogBuilder

- (void)parserWillBeginParsing:(DPSVNLogParser *)parser {
}

- (void)parser:(DPSVNLogParser *)parser parsedChangelog:(NSDictionary *)log {
	NSEnumerator *enumerator = [log keyEnumerator];
	NSString *category;
	
	while ((category = [enumerator nextObject])) {
		NSEnumerator *changesEnum = [[log objectForKey:category] objectEnumerator];
		NSString *change;
		
		printf("%s:\n\n", [category UTF8String]);
		while ((change = [changesEnum nextObject]))
			printf("* %s\n", [change UTF8String]);
		printf("\n");
	}
}

@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSProcessInfo *processInfo = [NSProcessInfo processInfo];
	NSArray *arguments = [processInfo arguments];
	int revLimit = 0;
	
	if ([arguments count] > 1)
		revLimit = [[arguments objectAtIndex:1] intValue];
	
	NSString *svnPath = [NSTask fullPathToExecutable:@"svn"];
	
	if (!svnPath) {
		puts("Can't find svn executable.\n");
		return EXIT_FAILURE;
	}
	
	NSPipe *pipe = [NSPipe pipe];
	NSTask *task = [[NSTask alloc] init];
	NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:@"log", @"--xml", nil];
	
	if (revLimit > 0) {
		[args addObject:@"-r"];
		[args addObject:[NSString stringWithFormat:@"HEAD:%d", revLimit]];
	}
	
	[task setLaunchPath:svnPath];
	[task setArguments:args];
	[task setEnvironment:[processInfo environment]];
	[task setStandardOutput:pipe];
	[task launch];
	[task waitUntilExit];
	
	if ([task terminationStatus] == 0) {
		DPSVNLogParser *parser = [[DPSVNLogParser alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile]];
		DPChangeLogBuilder *builder = [DPChangeLogBuilder new];
		
		[parser setDelegate:builder];
		[parser parse];
		
		[parser release];
		[builder release];
	}
	
	[task release];
    [pool release];
    return 0;
}
