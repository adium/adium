//
//  HyperlinkContextTest.m
//  AIHyperlinks.framework
//

#import "HyperlinkContextTest.h"
#import "AutoHyperlinks.h"

@implementation HyperlinkContextTest
- (void)testLaxContext:(NSString *)linkString withURI:(NSString *)URIString
{
	NSString			*testString = [NSString stringWithFormat:linkString, URIString];
	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithString:testString];
	AHMarkedHyperlink	*link = [scanner nextURI];
	
	STAssertNotNil(link, @"-[SHHyperlinkScanner nextURL] found no URI in \"%@\"", testString);
	STAssertEqualObjects([[link parentString] substringWithRange:[link range]], URIString, @"in context: '%@'", testString);
}

- (void)testNegativeContext:(NSString *)linkString withURI:(NSString *)URIString
{
	NSString			*testString = [NSString stringWithFormat:linkString, URIString];
	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithString:testString];
	AHMarkedHyperlink	*link = [scanner nextURI];
	
	STAssertNil(link, @"-[SHHyperlinkScanner nextURLFromString:] found no URI in \"%@\"", testString);
	STAssertEqualObjects([[link parentString] substringWithRange:[link range]], nil, @"in context: '%@'", testString);
}

#pragma mark positive tests
- (void)testEnclosedURI:(NSString *)URIString {
	[self testLaxContext:@"<%@>" withURI:URIString];
	[self testLaxContext:@"(%@)" withURI:URIString];
	[self testLaxContext:@"[%@]" withURI:URIString];
	
	[self testLaxContext:@"< %@ >" withURI:URIString];
	[self testLaxContext:@"( %@ )" withURI:URIString];
	[self testLaxContext:@"[ %@ ]" withURI:URIString];
}

- (void)testEnclosedURI:(NSString *)URIString enclosureOpeningCharacter:(unichar)openingChar enclosureClosingCharacter:(unichar)closingChar followedByCharacter:(unichar)terminalChar {
	NSString *format = [NSString stringWithFormat:@"%C%%@%C%C", openingChar, closingChar, terminalChar];
	[self testLaxContext:format withURI:URIString];
}

- (void)testEnclosedURIFollowedByCharacter:(NSString *)URIString {
	enum {
		kNumEnclosureCharacters = 3U,
		kNumTerminalCharacters = 17U
	};
	unichar enclosureOpeningCharacters[kNumEnclosureCharacters] = { '<', '(', '[', };
	unichar enclosureClosingCharacters[kNumEnclosureCharacters] = { '>', ')', ']', };
	unichar terminalCharacters[kNumTerminalCharacters] = { '.', '!', '?', '<', '>', '(', ')', '{', '}', '[', ']', '"', '\'', '-', ',', ':', ';' };
	for (unsigned int enclosureIndex = 0U; enclosureIndex < kNumEnclosureCharacters; ++enclosureIndex) {
		for (unsigned int terminalCharacterIndex = 0U; terminalCharacterIndex < kNumTerminalCharacters; ++terminalCharacterIndex) {
			[self         testEnclosedURI:URIString
				enclosureOpeningCharacter:enclosureOpeningCharacters[enclosureIndex]
				enclosureClosingCharacter:enclosureClosingCharacters[enclosureIndex]
					  followedByCharacter:terminalCharacters[terminalCharacterIndex]
			];
		}
	}
}

- (void)testURIBorder:(NSString *)URIString {
	[self testLaxContext:@":%@" withURI:URIString];
	[self testLaxContext:@"check it out:%@" withURI:URIString];
	[self testLaxContext:@"%@:" withURI:URIString];
	[self testLaxContext:@"%@." withURI:URIString];
}

- (void)testWhitespace:(NSString *)URIString {
	[self testLaxContext:@"\t%@" withURI:URIString];
	[self testLaxContext:@"\n%@" withURI:URIString];
	[self testLaxContext:@"\v%@" withURI:URIString];
	[self testLaxContext:@"\f%@" withURI:URIString];
	[self testLaxContext:@"\r%@" withURI:URIString];
	[self testLaxContext:@" %@" withURI:URIString];

	[self testLaxContext:@"%@\t" withURI:URIString];
	[self testLaxContext:@"%@\n" withURI:URIString];
	[self testLaxContext:@"%@\v" withURI:URIString];
	[self testLaxContext:@"%@\f" withURI:URIString];
	[self testLaxContext:@"%@\r" withURI:URIString];
	[self testLaxContext:@"%@ " withURI:URIString];

	[self testLaxContext:@"\t%@\t" withURI:URIString];
	[self testLaxContext:@"\n%@\n" withURI:URIString];
	[self testLaxContext:@"\v%@\v" withURI:URIString];
	[self testLaxContext:@"\f%@\f" withURI:URIString];
	[self testLaxContext:@"\r%@\r" withURI:URIString];
	[self testLaxContext:@" %@ " withURI:URIString];
	
	[self testLaxContext:@"words before %@" withURI:URIString];
	[self testLaxContext:@"%@ words after" withURI:URIString];
	[self testLaxContext:@"words before %@ and words after" withURI:URIString];
}

#pragma mark negative tests
- (void)testNegativeEnclosedURI:(NSString *)URIString {
	[self testNegativeContext:@"<%@>" withURI:URIString];
	[self testNegativeContext:@"(%@)" withURI:URIString];
	[self testNegativeContext:@"[%@]" withURI:URIString];
}

- (void)testNegativeEnclosedURI:(NSString *)URIString enclosureOpeningCharacter:(unichar)openingChar enclosureClosingCharacter:(unichar)closingChar followedByCharacter:(unichar)terminalChar {
	NSString *format = [NSString stringWithFormat:@"%C%%@%C%C", openingChar, closingChar, terminalChar];
	[self testNegativeContext:format withURI:URIString];
}
- (void)testNegativeEnclosedURIFollowedByCharacter:(NSString *)URIString {
	enum {
		kNumEnclosureCharacters = 3U,
		kNumTerminalCharacters = 17U
	};
	unichar enclosureOpeningCharacters[kNumEnclosureCharacters] = { '<', '(', '[', };
	unichar enclosureClosingCharacters[kNumEnclosureCharacters] = { '>', ')', ']', };
	unichar terminalCharacters[kNumTerminalCharacters] = { '.', '!', '?', '<', '>', '(', ')', '{', '}', '[', ']', '"', '\'', '-', ',', ':', ';' };
	for (unsigned int enclosureIndex = 0U; enclosureIndex < kNumEnclosureCharacters; ++enclosureIndex) {
		for (unsigned int terminalCharacterIndex = 0U; terminalCharacterIndex < kNumTerminalCharacters; ++terminalCharacterIndex) {
			[self         testNegativeEnclosedURI:URIString
				enclosureOpeningCharacter:enclosureOpeningCharacters[enclosureIndex]
				enclosureClosingCharacter:enclosureClosingCharacters[enclosureIndex]
					  followedByCharacter:terminalCharacters[terminalCharacterIndex]
			];
		}
	}
}

- (void)testNegativeURIBorder:(NSString *)URIString {
	[self testNegativeContext:@":%@" withURI:URIString];
	[self testNegativeContext:@"check it out:%@" withURI:URIString];
	[self testNegativeContext:@"%@:" withURI:URIString];
	[self testNegativeContext:@"%@." withURI:URIString];
}

- (void)testNegativeWhitespace:(NSString *)URIString {
	[self testNegativeContext:@"\t%@" withURI:URIString];
	[self testNegativeContext:@"\n%@" withURI:URIString];
	[self testNegativeContext:@"\v%@" withURI:URIString];
	[self testNegativeContext:@"\f%@" withURI:URIString];
	[self testNegativeContext:@"\r%@" withURI:URIString];
	[self testNegativeContext:@" %@" withURI:URIString];

	[self testNegativeContext:@"%@\t" withURI:URIString];
	[self testNegativeContext:@"%@\n" withURI:URIString];
	[self testNegativeContext:@"%@\v" withURI:URIString];
	[self testNegativeContext:@"%@\f" withURI:URIString];
	[self testNegativeContext:@"%@\r" withURI:URIString];
	[self testNegativeContext:@"%@ " withURI:URIString];

	[self testNegativeContext:@"\t%@\t" withURI:URIString];
	[self testNegativeContext:@"\n%@\n" withURI:URIString];
	[self testNegativeContext:@"\v%@\v" withURI:URIString];
	[self testNegativeContext:@"\f%@\f" withURI:URIString];
	[self testNegativeContext:@"\r%@\r" withURI:URIString];
	[self testNegativeContext:@" %@ " withURI:URIString];
	
	[self testNegativeContext:@"words before %@" withURI:URIString];
	[self testNegativeContext:@"%@ words after" withURI:URIString];
	[self testNegativeContext:@"words before %@ and words after" withURI:URIString];
}

#pragma mark URI tests
- (void)testSimpleDomain {
	[self testEnclosedURI:@"example.com"];
	[self testEnclosedURIFollowedByCharacter:@"example.com"];
	[self testURIBorder:@"example.com"];
	[self testWhitespace:@"example.com"];
}

- (void)testEmail {
	[self testEnclosedURI:@"test@example.com"];
	[self testEnclosedURIFollowedByCharacter:@"test@example.com"];
	[self testURIBorder:@"test@example.com"];
	[self testWhitespace:@"test@example.com"];
}

- (void)testJID {
	[self testNegativeEnclosedURI:@"jdoe@jabber.org/Adium"];
	[self testNegativeEnclosedURIFollowedByCharacter:@"jdoe@jabber.org/Adium"];
	[self testNegativeURIBorder:@"jdoe@jabber.org/Adium"];
	[self testNegativeWhitespace:@"jdoe@jabber.org/Adium"];
}

- (void)testEdgeURI {
	[self testEnclosedURI:@"example.com/foo_(bar)"];
	[self testURIBorder:@"example.com/foo_(bar)"];
	[self testEnclosedURI:@"http://example.com/foo_(bar)"];
	[self testURIBorder:@"http://example.com/foo_(bar)"];
	[self testEnclosedURI:@"http://example.com/f(oo_(ba)r)"];
	[self testURIBorder:@"http://example.com/f(oo_(ba)r)"];
	[self testEnclosedURI:@"http://example.com/f[oo_(ba]r)"];
	[self testURIBorder:@"http://example.com/f[oo_(ba]r)"];
	[self testEnclosedURI:@"http://example.com/f[oo_((ba]r))"];
	[self testURIBorder:@"http://example.com/f[oo_((ba]r))"];
	[self testURIBorder:@"http://www.example.com/___"];
	[self testURIBorder:@"http://www.example.com/$$$"];
	[self testURIBorder:@"http://www.example.com/---"];
	
	[self testEnclosedURI:@"http://www.example.com/query.php?test=YES&evilQuery=1"];
	[self testURIBorder:@"http://www.example.com/query.php?test=YES&evilQuery=1"];
	[self testEnclosedURIFollowedByCharacter:@"http://www.example.com/query.php?test=YES&evilQuery=1"];
	
	[self testEnclosedURI:@"http://www.example.com/___"];
	[self testEnclosedURI:@"http://www.example.com/$$$"];
	[self testEnclosedURI:@"http://www.example.com/---"];

	[self testEnclosedURIFollowedByCharacter:@"http://example.com/"];
	[self testEnclosedURIFollowedByCharacter:@"http://example.com"];

	[self testLaxContext:@"<><><><><<<<><><><><%@><><><><><><<<><><><><><>" withURI:@"example.com"];
	[self testLaxContext:@"l<><><><><<<<><><><><%@><><><><><><<<><><><><><>" withURI:@"http://example.com/foo_(bar)"];
	
	[self testLaxContext:@"@%@" withURI:@"example.com"];
	
	[self testLaxContext:@"foo (bar) %@" withURI:@"http://example.com/path/to/url.html"];
}

- (void)testCompositeContext {
	NSString			*URI1 = @"mailto:test@example.com";
	NSString			*URI2 = @"xmpp:test@example.com";
	NSString			*testString = [NSString stringWithFormat:@"%@ something %@", URI1, URI2];
	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithString:testString];
	AHMarkedHyperlink	*link;
	
	link = [scanner nextURI];
	STAssertNotNil(link, @"-[SHHyperlinkScanner nextURL] found no URI in \"%@\"", testString);
	STAssertEqualObjects([[link parentString] substringWithRange:[link range]], URI1, @"in context: '%@'", testString);
	
	link = [scanner nextURI];
	STAssertNotNil(link, @"-[SHHyperlinkScanner nextURL] found no URI in \"%@\"", testString);
	STAssertEqualObjects([[link parentString] substringWithRange:[link range]], URI2, @"in context: '%@'", testString);
}
@end
