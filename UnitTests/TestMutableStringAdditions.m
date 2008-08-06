#import "TestMutableStringAdditions.h"
#import "AIUnitTestUtilities.h"

#import <AIUtilities/AIMutableStringAdditions.h>

@implementation TestMutableStringAdditions

- (void)testReplaceOccurrencesOfString_withString_options
{
	NSMutableString *testString = [NSMutableString stringWithString:@"The quick brown fox jumped over the other quick brown fox"];
	
	//first make the string longer
	[testString replaceOccurrencesOfString:@"brown" withString:@"kinda lime-green with a bit of ecru" options:NSLiteralSearch];
	AISimplifiedAssertEqualObjects([NSMutableString stringWithString:@"The quick kinda lime-green with a bit of ecru fox jumped over the other quick kinda lime-green with a bit of ecru fox"], 
								   testString, 
								   @"Modified string wasn't equal to hand-made modified string");
	
	//next, try replacing something at the end; if the range didn't expand, this will fail
	[testString replaceOccurrencesOfString:@"fox" withString:@"aardvark" options:NSLiteralSearch];
	AISimplifiedAssertEqualObjects([NSMutableString stringWithString:@"The quick kinda lime-green with a bit of ecru aardvark jumped over the other quick kinda lime-green with a bit of ecru aardvark"], 
								   testString, 
								   @"After making the string longer, modifications no longer took into account the full length");
}

@end
