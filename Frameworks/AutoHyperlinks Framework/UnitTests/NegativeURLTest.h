//
//  NegativeURLTest.h
//  AIHyperlinks.framework
//

#import <XCTest/XCTest.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) XCTAssertFalse([AHHyperlinkScanner isStringValidURI: x usingStrict:YES fromIndex:0 withStatus:nil schemeLength:nil], @"%@ is a valid URI and should not be", x)


@interface NegativeURLTest : XCTestCase {
}

- (void)testInvalidURI;

@end
