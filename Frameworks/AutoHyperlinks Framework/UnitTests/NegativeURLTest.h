//
//  NegativeURLTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>
#import "AutoHyperlinks.h"

#define testHyperlink(x) STAssertFalse([AHHyperlinkScanner isStringValidURI: x usingStrict:YES fromIndex:0 withStatus:nil], @"%@ is a valid URI and should not be", x)


@interface NegativeURLTest : SenTestCase {
}

- (void)testInvalidURI;

@end
