/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
