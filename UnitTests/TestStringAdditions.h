#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

@interface TestStringAdditions: SenTestCase
{}

- (void)testRandomStringOfLength;
- (void)testStringWithContentsOfUTF8File;
- (void)testEllipsis;
- (void)testStringByAppendingEllipsis;
- (void)testCompactedString;
- (void)testStringWithEllipsisByTruncatingToLength;
- (void)testIdentityMethod;
- (void)testXMLEscaping;
- (void)testEscapingForShell;
- (void)testVolumePath;
- (void)testRangeOfLineBreakCharacterInRange;
- (void)testRangeOfLineBreakCharacterInEmptyRange;
- (void)testRangeOfLineBreakCharacterInRangeNotContainingLineBreakCharacter;
- (void)testRangeOfLineBreakCharacterInPartiallyInvalidRange;
- (void)testRangeOfLineBreakCharacterInInvalidRange;
- (void)testRangeOfLineBreakCharacterFromIndex;
- (void)testRangeOfLineBreakCharacterFromInvalidIndex;
- (void)testRangeOfLineBreakCharacter;
- (void)testRangeOfLineBreakCharacterInEmptyString;
- (void)testAllLinesWithSeparator;
- (void)testAllLines;

- (void) testCaseInsensitivelyEqualToSameString;
- (void) testCaseInsensitivelyEqualToSameStringInUppercase;
- (void) testCaseInsensitivelyEqualToSameStringInLowercase;
- (void) testCaseInsensitivelyEqualToStringPlusPrefix;
- (void) testCaseInsensitivelyEqualToStringPlusSuffix;
- (void) testCaseInsensitivelyEqualToCompletelyDifferentString;
- (void) testCaseInsensitivelyEqualToNil;
- (void) testCaseInsensitivelyEqualToThingsThatAreNotStrings;

@end
