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
#import "TestDateAdditions.h"

#import <AIUtilities/AIDateAdditions.h>

//2009-03-08T03:00:00.5 PDT - half a second after the start of Daylight Saving Time.
#define TEST_DATE [NSDate dateWithTimeIntervalSinceReferenceDate:258199200.5]

//We're testing converting intervals. If we use a time zone that supports DST, the DST changes screw us up. We need an invariant time zone, and UTC works well for this purpose.
#define TEST_TIME_ZONE [NSTimeZone timeZoneWithName:@"UTC"]

@implementation TestDateAdditions

- (void)testConvertIntervalToWeeks
{
	NSDate *now = TEST_DATE;
	NSDate *then;

	NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;
	NSDateComponents *components;

	NSInteger weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test exactly one week ago.
	components = [[NSDateComponents alloc] init];
	components.day = -7;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)1, @"Expected the difference between now and 7 days ago, which is %f seconds, to be 1 week; result was %iw, %id, %ih, %im, %fs", [now timeIntervalSinceDate:then], weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 7 days ago to be 1 week, 0 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 7 days ago to be 1 week, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 7 days ago to be 1 week, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 7 days ago to be 1 week, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test eight days ago. [Insert obligatory Beatles reference]
	components.day = -8;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)1, @"Expected the difference between now and 8 days ago to be 1 week, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)1, @"Expected the difference between now and 8 days ago to be 1 week, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test six days (almost, but not quite, one week) ago. [Insert obligatory DJ Shadow reference]
	components = [[NSDateComponents alloc] init];
	components.day = -6;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 6 days ago to be 0 weeks, 6 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)6, @"Expected the difference between now and 6 days ago to be 6 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 6 days ago to be 6 days, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 6 days ago to be 6 days, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 6 days ago to be 6 days, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToDays
{
	NSDate *now = TEST_DATE;
	NSDate *then;

	NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;
	NSDateComponents *components;

	NSInteger weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one day ago.
	components = [[NSDateComponents alloc] init];
	components.day = -1;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 0 weeks, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)1, @"Expected the difference between now and 1 day ago to be 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 1 day ago to be 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test one day ago, expressed as hours.
	components = [[NSDateComponents alloc] init];
	components.hour = -24;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 0 weeks, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)1, @"Expected the difference between now and 1 day ago to be 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 1 day ago to be 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 1 day ago to be 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	
	//Test 23 hours (almost, but not quite, one day) ago.
	components = [[NSDateComponents alloc] init];
	components.hour = -23;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 23 hours ago to be 0 weeks, 23 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 23 hours ago to be 0 days, 23 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)23, @"Expected the difference between now and 23 hours ago to be 23 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 23 hours ago to be 23 hours, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 23 hours ago to be 23 hours, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToHours
{
	NSDate *now = TEST_DATE;
	NSDate *then;

	NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;
	NSDateComponents *components;

	NSInteger weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one hour ago.
	components = [[NSDateComponents alloc] init];
	components.hour = -1;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 0 weeks, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 0 days, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)1, @"Expected the difference between now and 1 hour ago to be 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test one hour ago, expressed as minutes.
	components = [[NSDateComponents alloc] init];
	components.minute = -60;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 0 weeks, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 0 days, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)1, @"Expected the difference between now and 1 hour ago to be 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test 59 minutes (almost, but not quite, one hour) ago.
	components = [[NSDateComponents alloc] init];
	components.minute = -59;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 59 minutes ago to be 0 weeks, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 59 minutes ago to be 0 days, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 59 minutes ago to be 0 hours, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)59, @"Expected the difference between now and 59 minutes ago to be 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 59 minutes ago to be 59 minutes, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToMinutes
{
	NSDate *now = TEST_DATE;
	NSDate *then;

	NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;
	NSDateComponents *components;

	NSInteger weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one minute ago.
	components = [[NSDateComponents alloc] init];
	components.minute = -1;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 minute ago to be 0 weeks, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 1 minute ago to be 0 days, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 1 minute ago to be 0 hours, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)1, @"Expected the difference between now and 1 minute ago to be 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 0.0, @"Expected the difference between now and 1 minute ago to be 1 minute, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test 59 seconds (almost, but not quite, one minute) ago.
	components = [[NSDateComponents alloc] init];
	components.second = -59;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 59 seconds ago to be 0 weeks, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 59 seconds ago to be 0 days, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 59 seconds ago to be 0 hours, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 59 seconds ago to be 0 minutes, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 59.0, @"Expected the difference between now and 59 seconds ago to be 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToSeconds
{
	NSDate *now = TEST_DATE;
	NSDate *then;

	NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSTimeZone *tz = TEST_TIME_ZONE;
	gregorianCalendar.timeZone = tz;
	NSDateComponents *components;

	NSInteger weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one second ago.
	components = [[NSDateComponents alloc] init];
	components.second = -1;
	then = [gregorianCalendar dateByAddingComponents:components toDate:now options:0UL];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	XCTAssertEqual(weeks, (NSInteger)0, @"Expected the difference between now and 1 second ago to be 0 weeks, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual( days, (NSInteger)0, @"Expected the difference between now and 1 second ago to be 0 days, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(hours, (NSInteger)0, @"Expected the difference between now and 1 second ago to be 0 hours, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(minutes, (NSInteger)0, @"Expected the difference between now and 1 second ago to be 0 minutes, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	XCTAssertEqual(seconds, 1.0, @"Expected the difference between now and 1 second ago to be 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}

@end
