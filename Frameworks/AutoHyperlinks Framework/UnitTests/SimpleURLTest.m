//
//  SimpleURLTest.m
//  AIHyperlinks.framework
//

#import "SimpleURLTest.h"

@implementation SimpleURLTest

- (void)testURLOnly {
	testHyperlink(@"example.com");
	testHyperlink(@"www.example.com");
	testHyperlink(@"ftp.example.com");
	testHyperlink(@"example.com/");
	testHyperlink(@"www.example.com/");
	testHyperlink(@"ftp.example.com/");
	testHyperlink(@"example.com/foo");
	testHyperlink(@"www.example.com/foo");
	testHyperlink(@"example.com/foo/bar.php");
	testHyperlink(@"www.example.com/foo/bar.php");
}

- (void)testURI {
	testHyperlink(@"http://example.com/");
	testHyperlink(@"http://www.example.com/");
	testHyperlink(@"http://ftp.example.com/");
	testHyperlink(@"ftp://example.com/");
	testHyperlink(@"ftp://www.example.com/");
	testHyperlink(@"ftp://ftp.example.com/");
	testHyperlink(@"http://example.com");
	testHyperlink(@"http://www.example.com");
	testHyperlink(@"http://ftp.example.com");
	testHyperlink(@"ftp://example.com");
	testHyperlink(@"ftp://www.example.com");
	testHyperlink(@"ftp://ftp.example.com");
}

- (void)testURIWithPaths {
	testHyperlink(@"http://example.com/foo");
	testHyperlink(@"http://example.com/foo/bar.php");
	testHyperlink(@"http://www.example.com/foo/");
	testHyperlink(@"http://www.example.com/foo/bar.php");
	testHyperlink(@"http://ftp.example.com/foo");
	testHyperlink(@"http://ftp.example.com/foo/bar.php");
	testHyperlink(@"ftp://example.com/foo");
	testHyperlink(@"ftp://example.com/foo/bar.php");
	testHyperlink(@"ftp://www.example.com/foo/");
	testHyperlink(@"ftp://www.example.com/foo/bar.php");
	testHyperlink(@"ftp://ftp.example.com/foo");
	testHyperlink(@"ftp://ftp.example.com/foo/bar.php");
}

- (void)testURIWithUserAndPass {
	testHyperlink(@"http://user@example.com");
	testHyperlink(@"http://user:pass@example.com");
	testHyperlink(@"ftp://user@example.com");
	testHyperlink(@"ftp://user:pass@example.com");
}

- (void)testIPAddressURI {
	testHyperlink(@"http://1.1.1.1");
	testHyperlink(@"http://1.1.1.12");
	testHyperlink(@"http://1.1.1.123");
	testHyperlink(@"http://1.1.12.1");
	testHyperlink(@"http://1.1.12.12");
	testHyperlink(@"http://1.1.12.123");
	testHyperlink(@"http://1.1.123.1");
	testHyperlink(@"http://1.1.123.12");
	testHyperlink(@"http://1.1.123.123");
	testHyperlink(@"http://1.12.1.1");
	testHyperlink(@"http://1.12.1.12");
	testHyperlink(@"http://1.12.1.123");
	testHyperlink(@"http://1.12.12.1");
	testHyperlink(@"http://1.12.12.12");
	testHyperlink(@"http://1.12.12.123");
	testHyperlink(@"http://1.12.123.1");
	testHyperlink(@"http://1.12.123.12");
	testHyperlink(@"http://1.12.123.123");
	testHyperlink(@"http://1.123.1.1");
	testHyperlink(@"http://1.123.1.12");
	testHyperlink(@"http://1.123.1.123");
	testHyperlink(@"http://1.123.12.1");
	testHyperlink(@"http://1.123.12.12");
	testHyperlink(@"http://1.123.12.123");
	testHyperlink(@"http://1.123.123.1");
	testHyperlink(@"http://1.123.123.12");
	testHyperlink(@"http://1.123.123.123");
	testHyperlink(@"http://12.1.1.1");
	testHyperlink(@"http://12.1.1.12");
	testHyperlink(@"http://12.1.1.123");
	testHyperlink(@"http://12.1.12.1");
	testHyperlink(@"http://12.1.12.12");
	testHyperlink(@"http://12.1.12.123");
	testHyperlink(@"http://12.1.123.1");
	testHyperlink(@"http://12.1.123.12");
	testHyperlink(@"http://12.1.123.123");
	testHyperlink(@"http://12.12.1.1");
	testHyperlink(@"http://12.12.1.12");
	testHyperlink(@"http://12.12.1.123");
	testHyperlink(@"http://12.12.12.1");
	testHyperlink(@"http://12.12.12.12");
	testHyperlink(@"http://12.12.12.123");
	testHyperlink(@"http://12.12.123.1");
	testHyperlink(@"http://12.12.123.12");
	testHyperlink(@"http://12.12.123.123");
	testHyperlink(@"http://12.123.1.1");
	testHyperlink(@"http://12.123.1.12");
	testHyperlink(@"http://12.123.1.123");
	testHyperlink(@"http://12.123.12.1");
	testHyperlink(@"http://12.123.12.12");
	testHyperlink(@"http://12.123.12.123");
	testHyperlink(@"http://12.123.123.1");
	testHyperlink(@"http://12.123.123.12");
	testHyperlink(@"http://12.123.123.123");
	testHyperlink(@"http://123.1.1.1");
	testHyperlink(@"http://123.1.1.12");
	testHyperlink(@"http://123.1.1.123");
	testHyperlink(@"http://123.1.12.1");
	testHyperlink(@"http://123.1.12.12");
	testHyperlink(@"http://123.1.12.123");
	testHyperlink(@"http://123.1.123.1");
	testHyperlink(@"http://123.1.123.12");
	testHyperlink(@"http://123.1.123.123");
	testHyperlink(@"http://123.12.1.1");
	testHyperlink(@"http://123.12.1.12");
	testHyperlink(@"http://123.12.1.123");
	testHyperlink(@"http://123.12.12.1");
	testHyperlink(@"http://123.12.12.12");
	testHyperlink(@"http://123.12.12.123");
	testHyperlink(@"http://123.12.123.1");
	testHyperlink(@"http://123.12.123.12");
	testHyperlink(@"http://123.12.123.123");
	testHyperlink(@"http://123.123.1.1");
	testHyperlink(@"http://123.123.1.12");
	testHyperlink(@"http://123.123.1.123");
	testHyperlink(@"http://123.123.12.1");
	testHyperlink(@"http://123.123.12.12");
	testHyperlink(@"http://123.123.12.123");
	testHyperlink(@"http://123.123.123.1");
	testHyperlink(@"http://123.123.123.12");
	testHyperlink(@"http://123.123.123.123");
	testHyperlink(@"ftp://1.1.1.1");
	testHyperlink(@"ftp://1.1.1.12");
	testHyperlink(@"ftp://1.1.1.123");
	testHyperlink(@"ftp://1.1.12.1");
	testHyperlink(@"ftp://1.1.12.12");
	testHyperlink(@"ftp://1.1.12.123");
	testHyperlink(@"ftp://1.1.123.1");
	testHyperlink(@"ftp://1.1.123.12");
	testHyperlink(@"ftp://1.1.123.123");
	testHyperlink(@"ftp://1.12.1.1");
	testHyperlink(@"ftp://1.12.1.12");
	testHyperlink(@"ftp://1.12.1.123");
	testHyperlink(@"ftp://1.12.12.1");
	testHyperlink(@"ftp://1.12.12.12");
	testHyperlink(@"ftp://1.12.12.123");
	testHyperlink(@"ftp://1.12.123.1");
	testHyperlink(@"ftp://1.12.123.12");
	testHyperlink(@"ftp://1.12.123.123");
	testHyperlink(@"ftp://1.123.1.1");
	testHyperlink(@"ftp://1.123.1.12");
	testHyperlink(@"ftp://1.123.1.123");
	testHyperlink(@"ftp://1.123.12.1");
	testHyperlink(@"ftp://1.123.12.12");
	testHyperlink(@"ftp://1.123.12.123");
	testHyperlink(@"ftp://1.123.123.1");
	testHyperlink(@"ftp://1.123.123.12");
	testHyperlink(@"ftp://1.123.123.123");
	testHyperlink(@"ftp://12.1.1.1");
	testHyperlink(@"ftp://12.1.1.12");
	testHyperlink(@"ftp://12.1.1.123");
	testHyperlink(@"ftp://12.1.12.1");
	testHyperlink(@"ftp://12.1.12.12");
	testHyperlink(@"ftp://12.1.12.123");
	testHyperlink(@"ftp://12.1.123.1");
	testHyperlink(@"ftp://12.1.123.12");
	testHyperlink(@"ftp://12.1.123.123");
	testHyperlink(@"ftp://12.12.1.1");
	testHyperlink(@"ftp://12.12.1.12");
	testHyperlink(@"ftp://12.12.1.123");
	testHyperlink(@"ftp://12.12.12.1");
	testHyperlink(@"ftp://12.12.12.12");
	testHyperlink(@"ftp://12.12.12.123");
	testHyperlink(@"ftp://12.12.123.1");
	testHyperlink(@"ftp://12.12.123.12");
	testHyperlink(@"ftp://12.12.123.123");
	testHyperlink(@"ftp://12.123.1.1");
	testHyperlink(@"ftp://12.123.1.12");
	testHyperlink(@"ftp://12.123.1.123");
	testHyperlink(@"ftp://12.123.12.1");
	testHyperlink(@"ftp://12.123.12.12");
	testHyperlink(@"ftp://12.123.12.123");
	testHyperlink(@"ftp://12.123.123.1");
	testHyperlink(@"ftp://12.123.123.12");
	testHyperlink(@"ftp://12.123.123.123");
	testHyperlink(@"ftp://123.1.1.1");
	testHyperlink(@"ftp://123.1.1.12");
	testHyperlink(@"ftp://123.1.1.123");
	testHyperlink(@"ftp://123.1.12.1");
	testHyperlink(@"ftp://123.1.12.12");
	testHyperlink(@"ftp://123.1.12.123");
	testHyperlink(@"ftp://123.1.123.1");
	testHyperlink(@"ftp://123.1.123.12");
	testHyperlink(@"ftp://123.1.123.123");
	testHyperlink(@"ftp://123.12.1.1");
	testHyperlink(@"ftp://123.12.1.12");
	testHyperlink(@"ftp://123.12.1.123");
	testHyperlink(@"ftp://123.12.12.1");
	testHyperlink(@"ftp://123.12.12.12");
	testHyperlink(@"ftp://123.12.12.123");
	testHyperlink(@"ftp://123.12.123.1");
	testHyperlink(@"ftp://123.12.123.12");
	testHyperlink(@"ftp://123.12.123.123");
	testHyperlink(@"ftp://123.123.1.1");
	testHyperlink(@"ftp://123.123.1.12");
	testHyperlink(@"ftp://123.123.1.123");
	testHyperlink(@"ftp://123.123.12.1");
	testHyperlink(@"ftp://123.123.12.12");
	testHyperlink(@"ftp://123.123.12.123");
	testHyperlink(@"ftp://123.123.123.1");
	testHyperlink(@"ftp://123.123.123.12");
	testHyperlink(@"ftp://123.123.123.123");
	
	testHyperlink(@"http://1.1.1.1/");
	testHyperlink(@"http://1.1.1.12/");
	testHyperlink(@"http://1.1.1.123/");
	testHyperlink(@"http://1.1.12.1/");
	testHyperlink(@"http://1.1.12.12/");
	testHyperlink(@"http://1.1.12.123/");
	testHyperlink(@"http://1.1.123.1/");
	testHyperlink(@"http://1.1.123.12/");
	testHyperlink(@"http://1.1.123.123/");
	testHyperlink(@"http://1.12.1.1/");
	testHyperlink(@"http://1.12.1.12/");
	testHyperlink(@"http://1.12.1.123/");
	testHyperlink(@"http://1.12.12.1/");
	testHyperlink(@"http://1.12.12.12/");
	testHyperlink(@"http://1.12.12.123/");
	testHyperlink(@"http://1.12.123.1/");
	testHyperlink(@"http://1.12.123.12/");
	testHyperlink(@"http://1.12.123.123/");
	testHyperlink(@"http://1.123.1.1/");
	testHyperlink(@"http://1.123.1.12/");
	testHyperlink(@"http://1.123.1.123/");
	testHyperlink(@"http://1.123.12.1/");
	testHyperlink(@"http://1.123.12.12/");
	testHyperlink(@"http://1.123.12.123/");
	testHyperlink(@"http://1.123.123.1/");
	testHyperlink(@"http://1.123.123.12/");
	testHyperlink(@"http://1.123.123.123/");
	testHyperlink(@"http://12.1.1.1/");
	testHyperlink(@"http://12.1.1.12/");
	testHyperlink(@"http://12.1.1.123/");
	testHyperlink(@"http://12.1.12.1/");
	testHyperlink(@"http://12.1.12.12/");
	testHyperlink(@"http://12.1.12.123/");
	testHyperlink(@"http://12.1.123.1/");
	testHyperlink(@"http://12.1.123.12/");
	testHyperlink(@"http://12.1.123.123/");
	testHyperlink(@"http://12.12.1.1/");
	testHyperlink(@"http://12.12.1.12/");
	testHyperlink(@"http://12.12.1.123/");
	testHyperlink(@"http://12.12.12.1/");
	testHyperlink(@"http://12.12.12.12/");
	testHyperlink(@"http://12.12.12.123/");
	testHyperlink(@"http://12.12.123.1/");
	testHyperlink(@"http://12.12.123.12/");
	testHyperlink(@"http://12.12.123.123/");
	testHyperlink(@"http://12.123.1.1/");
	testHyperlink(@"http://12.123.1.12/");
	testHyperlink(@"http://12.123.1.123/");
	testHyperlink(@"http://12.123.12.1/");
	testHyperlink(@"http://12.123.12.12/");
	testHyperlink(@"http://12.123.12.123/");
	testHyperlink(@"http://12.123.123.1/");
	testHyperlink(@"http://12.123.123.12/");
	testHyperlink(@"http://12.123.123.123/");
	testHyperlink(@"http://123.1.1.1/");
	testHyperlink(@"http://123.1.1.12/");
	testHyperlink(@"http://123.1.1.123/");
	testHyperlink(@"http://123.1.12.1/");
	testHyperlink(@"http://123.1.12.12/");
	testHyperlink(@"http://123.1.12.123/");
	testHyperlink(@"http://123.1.123.1/");
	testHyperlink(@"http://123.1.123.12/");
	testHyperlink(@"http://123.1.123.123/");
	testHyperlink(@"http://123.12.1.1/");
	testHyperlink(@"http://123.12.1.12/");
	testHyperlink(@"http://123.12.1.123/");
	testHyperlink(@"http://123.12.12.1/");
	testHyperlink(@"http://123.12.12.12/");
	testHyperlink(@"http://123.12.12.123/");
	testHyperlink(@"http://123.12.123.1/");
	testHyperlink(@"http://123.12.123.12/");
	testHyperlink(@"http://123.12.123.123/");
	testHyperlink(@"http://123.123.1.1/");
	testHyperlink(@"http://123.123.1.12/");
	testHyperlink(@"http://123.123.1.123/");
	testHyperlink(@"http://123.123.12.1/");
	testHyperlink(@"http://123.123.12.12/");
	testHyperlink(@"http://123.123.12.123/");
	testHyperlink(@"http://123.123.123.1/");
	testHyperlink(@"http://123.123.123.12/");
	testHyperlink(@"http://123.123.123.123/");
	testHyperlink(@"ftp://1.1.1.1/");
	testHyperlink(@"ftp://1.1.1.12/");
	testHyperlink(@"ftp://1.1.1.123/");
	testHyperlink(@"ftp://1.1.12.1/");
	testHyperlink(@"ftp://1.1.12.12/");
	testHyperlink(@"ftp://1.1.12.123/");
	testHyperlink(@"ftp://1.1.123.1/");
	testHyperlink(@"ftp://1.1.123.12/");
	testHyperlink(@"ftp://1.1.123.123/");
	testHyperlink(@"ftp://1.12.1.1/");
	testHyperlink(@"ftp://1.12.1.12/");
	testHyperlink(@"ftp://1.12.1.123/");
	testHyperlink(@"ftp://1.12.12.1/");
	testHyperlink(@"ftp://1.12.12.12/");
	testHyperlink(@"ftp://1.12.12.123/");
	testHyperlink(@"ftp://1.12.123.1/");
	testHyperlink(@"ftp://1.12.123.12/");
	testHyperlink(@"ftp://1.12.123.123/");
	testHyperlink(@"ftp://1.123.1.1/");
	testHyperlink(@"ftp://1.123.1.12/");
	testHyperlink(@"ftp://1.123.1.123/");
	testHyperlink(@"ftp://1.123.12.1/");
	testHyperlink(@"ftp://1.123.12.12/");
	testHyperlink(@"ftp://1.123.12.123/");
	testHyperlink(@"ftp://1.123.123.1/");
	testHyperlink(@"ftp://1.123.123.12/");
	testHyperlink(@"ftp://1.123.123.123/");
	testHyperlink(@"ftp://12.1.1.1/");
	testHyperlink(@"ftp://12.1.1.12/");
	testHyperlink(@"ftp://12.1.1.123/");
	testHyperlink(@"ftp://12.1.12.1/");
	testHyperlink(@"ftp://12.1.12.12/");
	testHyperlink(@"ftp://12.1.12.123/");
	testHyperlink(@"ftp://12.1.123.1/");
	testHyperlink(@"ftp://12.1.123.12/");
	testHyperlink(@"ftp://12.1.123.123/");
	testHyperlink(@"ftp://12.12.1.1/");
	testHyperlink(@"ftp://12.12.1.12/");
	testHyperlink(@"ftp://12.12.1.123/");
	testHyperlink(@"ftp://12.12.12.1/");
	testHyperlink(@"ftp://12.12.12.12/");
	testHyperlink(@"ftp://12.12.12.123/");
	testHyperlink(@"ftp://12.12.123.1/");
	testHyperlink(@"ftp://12.12.123.12/");
	testHyperlink(@"ftp://12.12.123.123/");
	testHyperlink(@"ftp://12.123.1.1/");
	testHyperlink(@"ftp://12.123.1.12/");
	testHyperlink(@"ftp://12.123.1.123/");
	testHyperlink(@"ftp://12.123.12.1/");
	testHyperlink(@"ftp://12.123.12.12/");
	testHyperlink(@"ftp://12.123.12.123/");
	testHyperlink(@"ftp://12.123.123.1/");
	testHyperlink(@"ftp://12.123.123.12/");
	testHyperlink(@"ftp://12.123.123.123/");
	testHyperlink(@"ftp://123.1.1.1/");
	testHyperlink(@"ftp://123.1.1.12/");
	testHyperlink(@"ftp://123.1.1.123/");
	testHyperlink(@"ftp://123.1.12.1/");
	testHyperlink(@"ftp://123.1.12.12/");
	testHyperlink(@"ftp://123.1.12.123/");
	testHyperlink(@"ftp://123.1.123.1/");
	testHyperlink(@"ftp://123.1.123.12/");
	testHyperlink(@"ftp://123.1.123.123/");
	testHyperlink(@"ftp://123.12.1.1/");
	testHyperlink(@"ftp://123.12.1.12/");
	testHyperlink(@"ftp://123.12.1.123/");
	testHyperlink(@"ftp://123.12.12.1/");
	testHyperlink(@"ftp://123.12.12.12/");
	testHyperlink(@"ftp://123.12.12.123/");
	testHyperlink(@"ftp://123.12.123.1/");
	testHyperlink(@"ftp://123.12.123.12/");
	testHyperlink(@"ftp://123.12.123.123/");
	testHyperlink(@"ftp://123.123.1.1/");
	testHyperlink(@"ftp://123.123.1.12/");
	testHyperlink(@"ftp://123.123.1.123/");
	testHyperlink(@"ftp://123.123.12.1/");
	testHyperlink(@"ftp://123.123.12.12/");
	testHyperlink(@"ftp://123.123.12.123/");
	testHyperlink(@"ftp://123.123.123.1/");
	testHyperlink(@"ftp://123.123.123.12/");
	testHyperlink(@"ftp://123.123.123.123/");
}

- (void)testIPv6URI {
	testHyperlink(@"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]");
	testHyperlink(@"http://[1080:0:0:0:8:800:200C:417A]");
	testHyperlink(@"http://[3ffe:2a00:100:7031::1]");
	testHyperlink(@"http://[1080::8:800:200C:417A]");
	testHyperlink(@"http://[::192.9.5.5]");
	testHyperlink(@"http://[::FFFF:129.144.52.38]");
	testHyperlink(@"http://[2010:836B:4179::836B:4179]");
	testHyperlink(@"http://[::1]");

	testHyperlink(@"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]/");
	testHyperlink(@"http://[1080:0:0:0:8:800:200C:417A]/");
	testHyperlink(@"http://[3ffe:2a00:100:7031::1]/");
	testHyperlink(@"http://[1080::8:800:200C:417A]/");
	testHyperlink(@"http://[::192.9.5.5]/");
	testHyperlink(@"http://[::FFFF:129.144.52.38]/");
	testHyperlink(@"http://[2010:836B:4179::836B:4179]/");
	testHyperlink(@"http://[::1]/");
}

- (void)testInternationalDomainNameURI {
#if 0
	NSString *URLString;
	NSURL *correctURL, *foundURL;

	//http://ουτοπία.δπθ.gr/, aka utoria.duth.gr. Link borrowed from <http://en.wikipedia.org/wiki/Image:IDN-utopia-greek.jpg>.
	URLString = [NSString stringWithUTF8String:"\x68\x74\x74\x70\x3A\x2F\x2F\xCE\xBF\xCF\x85\xCF\x84\xCE\xBF\xCF\x80\xCE\xAF\xCE\xB1\x2E\xCE\xB4\xCF\x80\xCE\xB8\x2E\x67\x72\x2F"]; //With pathname (/)
	testHyperlink(URLString);

	scanner = [AHHyperlinkScanner strictHyperlinkScannerWithString:URLString];
	foundURL = [[scanner nextURI] URL];
	STAssertNotNil(foundURL, @"%@ is a valid URL but scanner returned nil", URLString);
	if (foundURL) {
		correctURL = [NSURL URLWithString:@"http://xn--kxae4bafwg.xn--pxaix.gr/"];
		STAssertEqualObjects(foundURL, correctURL, @"Hyperlink scanner returned incorrect URL");
	}

	URLString = [NSString stringWithUTF8String:"\x68\x74\x74\x70\x3A\x2F\x2F\xCE\xBF\xCF\x85\xCF\x84\xCE\xBF\xCF\x80\xCE\xAF\xCE\xB1\x2E\xCE\xB4\xCF\x80\xCE\xB8\x2E\x67\x72"]; //Without pathname
	testHyperlink(URLString);

	scanner = [AHHyperlinkScanner strictHyperlinkScannerWithString:URLString];
	foundURL = [[scanner nextURI] URL];
	STAssertNotNil(foundURL, @"%@ is a valid URL but scanner returned nil", URLString);
	if (foundURL) {
		correctURL = [NSURL URLWithString:@"http://xn--kxae4bafwg.xn--pxaix.gr/"];
		STAssertEqualObjects(foundURL, correctURL, @"Hyperlink scanner returned incorrect URL");
	}

	//<http://➡.ws/ﷺ>, which is the shortened URL for <http://➡.ws/>.
	URLString = [NSString stringWithUTF8String:"\x68\x74\x74\x70\x3a\x2f\x2f\xe2\x9e\xa1\x2e\x77\x73\x2f\xef\xb7\xba"];
	testHyperlink(URLString);

	scanner = [AHHyperlinkScanner strictHyperlinkScannerWithString:URLString];
	foundURL = [[scanner nextURI] URL];
	STAssertNotNil(foundURL, @"%@ is a valid URL but scanner returned nil", URLString);
	if (foundURL) {
		correctURL = [NSURL URLWithString:@"http://xn--hgi.ws/%EF%B7%BA"];
		STAssertEqualObjects(foundURL, correctURL, @"Hyperlink scanner returned incorrect URL");
	}
#endif
}

- (void)testUniqueURI {
	testHyperlink(@"sip:foo@example.com");
	testHyperlink(@"xmpp:foo@example.com");
	testHyperlink(@"xmpp:foo@example.com/adium");
	//URL formats with query strings as specified by http://www.xmpp.org/extensions/xep-0147.html
	testHyperlink(@"xmpp:romeo@montague.net?message;body=Here%27s%20a%20test%20message");
	testHyperlink(@"xmpp:romeo@montague.net?message;subject=Test%20Message;body=Here%27s%20a%20test%20message");
	//Variants with '&' instead of ';': Adium accepts these, although the XEP does not specify them.
	testHyperlink(@"xmpp:romeo@montague.net?message&body=Here%27s%20a%20test%20message");
	testHyperlink(@"xmpp:romeo@montague.net?message&subject=Test%20Message&body=Here%27s%20a%20test%20message");
	testHyperlink(@"aim:goim?screenname=adiumx");
	testHyperlink(@"aim:goim?screenname=adiumx&message=Hey!+Does+this+work?");
	testHyperlink(@"ymsgr:sendim?adiumy");
	testHyperlink(@"yahoo:sendim?adiumy");
	testHyperlink(@"ymsgr://im?to=adiumy");
	testHyperlink(@"yahoo://im?to=adiumy");
	testHyperlink(@"ymsgr:im?to=adiumy");
	testHyperlink(@"yahoo:im?to=adiumy");
	//gtalk: URIs adapted from http://groups.google.com/group/google-talk-open/browse_thread/thread/8b297e26b4ffce1b/8d9f92f0f5e68a04?#8d9f92f0f5e68a04 and http://trac.adiumx.com/ticket/7420#comment:4
	testHyperlink(@"gtalk:chat?jid=example@gmail.com");
	testHyperlink(@"gtalk:chat?jid=example@gmail.com&from_jid=example2@gmail.com");
	testHyperlink(@"gtalk:call?jid=example@gmail.com");
	testHyperlink(@"gtalk:call?jid=example@gmail.com&from_jid=example2@gmail.com");
	testHyperlink(@"gtalk:gtalk?jid=example@gmail.com");
	testHyperlink(@"myim:addContact?uID=0&cID=42");
	testHyperlink(@"myim:addContact?uID=0&cID=&auto=true");
	testHyperlink(@"myim:addContact?auto=true&uID=0&cID=");
	testHyperlink(@"myim:addContact?uID=42&cID=42");
	testHyperlink(@"myim:addContact?uID=42&cID=&auto=true");
	testHyperlink(@"myim:addContact?auto=true&uID=42&cID=");
	testHyperlink(@"myim:sendIM?uID=0&cID=42");
	testHyperlink(@"myim:sendIM?uID=42&cID=42");
	testHyperlink(@"rdar://1234");
	testHyperlink(@"rdar://problem/1234");
	testHyperlink(@"rdar://problems/1234&5678&9012");
	testHyperlink(@"radr://1234");
	testHyperlink(@"radr://problem/1234");
	testHyperlink(@"radr://problems/1234&5678&9012");
	testHyperlink(@"radar://1234");
	testHyperlink(@"radar://problem/1234");
	testHyperlink(@"radar://problems/1234&5678&9012");
	testHyperlink(@"x-radar://1234");
	testHyperlink(@"x-radar://problem/1234");
	testHyperlink(@"x-radar://problems/1234&5678&9012");
	testHyperlink(@"spotify:track:abcd1234");
	testHyperlink(@"spotify:album:abcd1234");
	testHyperlink(@"spotify:artist:abcd1234");
	testHyperlink(@"spotify:search:abcd1234");
	testHyperlink(@"spotify:playlist:abcd1234");
	testHyperlink(@"spotify:user:abcd1234");
	testHyperlink(@"spotify:radio:abcd1234");
	//msnim: URIs taken from http://en.wikipedia.org/wiki/URI_scheme
	testHyperlink(@"msnim:chat?contact=example@msn.com");
	testHyperlink(@"msnim:add?contact=example@msn.com");
	testHyperlink(@"msnim:voice?contact=example@msn.com");
	testHyperlink(@"msnim:video?contact=example@msn.com");
}

- (void)testEmailAddress {
	testHyperlink(@"foo@example.com");
	testHyperlink(@"foo.bar@example.com");
}

- (void)testInternationalEmailAddress {
	// test@ουτοπία.δπθ.gr
	testHyperlink([NSString stringWithUTF8String:"\x74\x65\x73\x74\x40\xCE\xBF\xCF\x85\xCF\x84\xCE\xBF\xCF\x80\xCE\xAF\xCE\xB1\x2E\xCE\xB4\xCF\x80\xCE\xB8\x2E\x67\x72"]);
}

- (void)testDictURI {
	testHyperlink(@"dict:/test");
	testHyperlink(@"dict://test");
	testHyperlink(@"dict:///test");
}

- (void)testUserCases {
	testHyperlink(@"http://example.com/foo_(bar)");
	testHyperlink(@"http://acts_as_solr.railsfreaks.com/"); //#7959
	testHyperlink(@"http://example.not.a.tld/");
	testHyperlink(@"http://example.not.a.tld:8080/");
	testHyperlink(@"http://example.not.a.tld/stuff");
	testHyperlink(@"http://example.not.a.tld:8080/stuff");
}
@end
