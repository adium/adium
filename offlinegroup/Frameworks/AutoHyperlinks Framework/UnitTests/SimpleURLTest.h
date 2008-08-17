//
//  SimpleURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) STAssertTrue([AHHyperlinkScanner isStringValidURI: x usingStrict:NO fromIndex:0 withStatus:nil],\
					@"\"%@\" Should be a valid URI.", x )

@interface SimpleURLTest : SenTestCase {
	AHHyperlinkScanner	*scanner;
}
- (void)testURLOnly;
- (void)testURI;
- (void)testURIWithPaths;
- (void)testURIWithUserAndPass;
- (void)testIPAddressURI;
- (void)testIPv6URI;
- (void)testUniqueURI;
- (void)testEmailAddress;
- (void)testInternationalEmailAddress;
- (void)testDictURI;
- (void)testUserCases;
@end
