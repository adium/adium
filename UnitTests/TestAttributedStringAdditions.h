//
//  TestAttributedStringAdditions.h
//  Adium
//
//  Created by Peter Hosey on 2009-03-07.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

@interface TestAttributedStringAdditions : SenTestCase {

}

- (void) testLinkedAttributedString;
- (void) testAttributedStringWithLinkedSubstring;
- (void) testAttributedStringWithLinkedEntireStringUsingSubstringMethod;
- (void) testAttributedStringWithLinkedEmptySubstring;

- (void) testAttributedStringByConvertingLinksToStrings;

@end
