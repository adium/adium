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
#import "TestDateFormatterStringRepWithInterval.h"
#import <AIUtilities/AIDateAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>

//We're testing converting intervals. If we use a time zone that supports DST, the DST changes screw us up. We need an invariant time zone, and UTC works well for this purpose.
#define TEST_TIME_ZONE [NSTimeZone timeZoneWithName:@"UTC"]

@implementation TestDateFormatterStringRepWithInterval

//Note: All of these delta values that we pass to -[NSCalendar dateByAddingComponents:toDate:options:] need to be NEGATIVE, because we're looking to get a string representation of the interval since some time in the past.
- (void)testDateFormatterStringRepWithInterval_seconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;

	//This delay will reveal whether the method under test is incorrectly testing for seconds. (This was a real intermittent failure.)
	usleep(0.1f * 1000000.0f);

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}

- (void)testDateFormatterStringRepWithInterval_seconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.day = -5;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.minute = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds_abbreviated {
	NSDate *now = [NSDate date];
	NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;

	NSDateComponents *components;
	components = [[[NSDateComponents alloc] init] autorelease];
	components.week = -65;
	components.day = -5;
	components.hour = -10;
	components.minute = -10;
	components.second = -10;

	NSDate *date = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10m 10s", @"Unexpected string for time interval");
}

@end
