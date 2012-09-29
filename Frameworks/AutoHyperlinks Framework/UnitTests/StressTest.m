//
//  StressTest.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 5/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "StressTest.h"
#import "AutoHyperlinks.h"


@implementation StressTest
- (void)testStress {
	NSError				*error = nil;
	NSString			*stressString = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:TEST_URIS_FILE_PATHNAME] encoding:NSUTF8StringEncoding error:&error];
	STAssertNil(error, @"stringWithContentsOfFile:encoding:error: could not read file at path '%s': %@", TEST_URIS_FILE_PATHNAME, error);

	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithString:stressString];
	NSAttributedString	*attrString;
	
	int i = 5;
	while(i > 0) {
		attrString = [scanner linkifiedString];
		i--;
	}
}
@end
