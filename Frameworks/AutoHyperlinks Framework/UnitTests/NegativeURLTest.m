//
//  NegativeURLTest.m
//  AIHyperlinks.framework
//

#import "NegativeURLTest.h"

@implementation NegativeURLTest
- (void)testInvalidURI {
	testHyperlink(@"adium");
	testHyperlink(@"http://");
	testHyperlink(@"example.co");
	testHyperlink(@"b.sc");
	testHyperlink(@"m.in");
	testHyperlink(@"test.not.a.tld");
	testHyperlink(@"http://[::]");
	testHyperlink(@"http://[::1:]");
	testHyperlink(@"http://[1]");
	testHyperlink(@"http://[]");
	testHyperlink(@"http://example.com/ is not a link");
	testHyperlink(@"jdoe@jabber.org/Adium");
	testHyperlink(@"mailto:test@example.com text xmpp:test@example.com");
}
@end
