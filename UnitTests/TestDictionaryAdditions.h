#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

@interface TestDictionaryAdditions: SenTestCase
{}

- (void)testTranslateAddRemove_translate;
- (void)testTranslateAddRemove_add;
- (void)testTranslateAddRemove_remove;

- (void)testTranslateAddRemove_translateAdd;
- (void)testTranslateAddRemove_translateRemove;
- (void)testTranslateAddRemove_addRemove;

- (void)testTranslateAddRemove_translateAddRemove;

@end
