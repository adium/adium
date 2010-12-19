//
//  TestScandate.m
//  Adium
//
//  Created by Peter Hosey on 2010-12-18.
//  Copyright 2010 Peter Hosey. All rights reserved.
//

#import "TestScandate.h"

#import "scandate.h"

@implementation TestScandate

- (void) testEricRichiesTwitterTimelineLogFilename {
	static const char EricRichiesTwitterTimelineLogFilename[] = "timeline (edr1084) (2010-12-18T17.42.58-0500).chatlog";
	unsigned long correctYear = 2010, correctMonth = 12, correctDayOfMonth = 18;
	BOOL correctDidFindTime = YES;
	unsigned long correctHour = 17, correctMinute = 42, correctSecond = 58;
	long correctTimeZoneOffsetInMinutes = -(5 * 60);
	BOOL correctDidFindDate = YES;

	unsigned long foundYear, foundMonth, foundDayOfMonth;
	BOOL didFindTime;
	unsigned long foundHour, foundMinute, foundSecond;
	long foundTimeZoneOffsetInMinutes;

	BOOL didFindDate = scandate(EricRichiesTwitterTimelineLogFilename, &foundYear, &foundMonth, &foundDayOfMonth, &didFindTime, &foundHour, &foundMinute, &foundSecond, &foundTimeZoneOffsetInMinutes);
	STAssertEquals(didFindDate, correctDidFindDate, @"No date found in this string! '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundYear, correctYear, @"Wrong year found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundMonth, correctMonth, @"Wrong month found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundDayOfMonth, correctDayOfMonth, @"Wrong day-of-month found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(didFindTime, correctDidFindTime, @"No time found in this string! '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundHour, correctHour, @"Wrong hour found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundMinute, correctMinute, @"Wrong minute found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundSecond, correctSecond, @"Wrong second found in '%s'", EricRichiesTwitterTimelineLogFilename);
	STAssertEquals(foundTimeZoneOffsetInMinutes, correctTimeZoneOffsetInMinutes, @"Wrong time zone offset found in '%s'", EricRichiesTwitterTimelineLogFilename);
}

@end
