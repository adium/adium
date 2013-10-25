//
//  HyperlinkContextTest.h
//  AIHyperlinks.framework
//

#import <SenTestingKit/SenTestingKit.h>


@interface HyperlinkContextTest : SenTestCase {

}
- (void)testSimpleDomain;
- (void)testEmail;
- (void)testJID;
- (void)testEdgeURI;
- (void)testCompositeContext;
@end
