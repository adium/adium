//All test-case methods here use NSScriptCoercionHandler, which should delegate to AIRichTextCoercer.

@interface TestRichTextCoercion : SenTestCase
{}

/*
- (void)testAttributedStringToPlainText;
- (void)testMutableAttributedStringToPlainText;
 */
- (void)testTextStorageToPlainText;

/*
- (void)testPlainTextToAttributedString;
- (void)testPlainTextToMutableAttributedString;
 */
- (void)testPlainTextToTextStorage;

//Coerce the string, then mutate the original.
/*
- (void)testMutableAttributedStringToPlainTextWithMutations;
 */
- (void)testTextStorageToPlainTextWithMutations;

//Run the AppleScript “x as y”, where x is an AS object and y is an AS class.
- (void)testRichTextToPlainTextInAppleScript;
- (void)testPlainTextToRichTextInAppleScript;

@end
