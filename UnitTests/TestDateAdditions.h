#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

@interface TestDateAdditions : SenTestCase
{}

- (void)testConvertIntervalToWeeks;
- (void)testConvertIntervalToDays;
- (void)testConvertIntervalToHours;
- (void)testConvertIntervalToMinutes;
- (void)testConvertIntervalToSeconds;

@end
