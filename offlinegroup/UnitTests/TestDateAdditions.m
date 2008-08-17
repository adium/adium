#import "TestDateAdditions.h"

#import <AIUtilities/AIDateAdditions.h>
#import <AIUtilities/AICalendarDateAdditions.h>

@implementation TestDateAdditions

- (void)testConvertIntervalToWeeks
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *then;

	int weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test exactly one week ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-7
					hours:-0 minutes:-0 seconds:-0];
	
	then = [then dateByMatchingDSTOfDate:now];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	STAssertEquals(weeks, 1, @"Expected the difference between now and 7 days ago, which is %f seconds, to be 1 week; result was %iw, %id, %ih, %im, %fs", [now timeIntervalSinceDate:then], weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 7 days ago to be 1 week, 0 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 7 days ago to be 1 week, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 7 days ago to be 1 week, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 7 days ago to be 1 week, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test eight days ago. [Insert obligatory Beatles reference]
	then = [now
		dateByAddingYears:-0  months:-0    days:-8
					hours:-0 minutes:-0 seconds:-0];
	then = [then dateByMatchingDSTOfDate:now];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 1, @"Expected the difference between now and 8 days ago to be 1 week, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 1, @"Expected the difference between now and 8 days ago to be 1 week, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 8 days ago to be 1 week, 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test six days (almost, but not quite, one week) ago. [Insert obligatory DJ Shadow reference]
	then = [now
		dateByAddingYears:-0  months:-0    days:-6
					hours:-0 minutes:-0 seconds:-0];
	then = [then dateByMatchingDSTOfDate:now];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 6 days ago to be 0 weeks, 6 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 6, @"Expected the difference between now and 6 days ago to be 6 days; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 6 days ago to be 6 days, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 6 days ago to be 6 days, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 6 days ago to be 6 days, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToDays
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *then;

	int weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one day ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-1
					hours:-0 minutes:-0 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 day ago to be 0 weeks, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 1, @"Expected the difference between now and 1 day ago to be 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 day ago to be 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test one day ago, expressed as hours.
	then = [now
		dateByAddingYears:-0   months:-0    days:-0
					hours:-24 minutes:-0 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 day ago to be 0 weeks, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 1, @"Expected the difference between now and 1 day ago to be 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 day ago to be 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	
	//Test 23 hours (almost, but not quite, one day) ago.
	then = [now
		dateByAddingYears:-0   months:-0    days:-0
					hours:-24 minutes:-0 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 day ago to be 0 weeks, 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 1, @"Expected the difference between now and 1 day ago to be 1 day; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 hours; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 day ago to be 1 day, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 day ago to be 1 day, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToHours
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *then;

	int weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one hour ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-0
					hours:-1 minutes:-0 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 hour ago to be 0 weeks, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 1 hour ago to be 0 days, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 1, @"Expected the difference between now and 1 hour ago to be 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test one hour ago, expressed as minutes.
	then = [now
		dateByAddingYears:-0  months:-0    days:-0
					hours:-1 minutes:-0 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 hour ago to be 0 weeks, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 1 hour ago to be 0 days, 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 1, @"Expected the difference between now and 1 hour ago to be 1 hour; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 hour ago to be 1 hour, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test 59 minutes (almost, but not quite, one hour) ago.
	then = [now
		dateByAddingYears:-0  months:-0     days:-0
					hours:-0 minutes:-59 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 59 minutes ago to be 0 weeks, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 59 minutes ago to be 0 days, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 59 minutes ago to be 0 hours, 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 59, @"Expected the difference between now and 59 minutes ago to be 59 minutes; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 59 minutes ago to be 59 minutes, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToMinutes
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *then;

	int weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one minute ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-0
					hours:-0 minutes:-1 seconds:-0];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 minute ago to be 0 weeks, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 1 minute ago to be 0 days, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 1 minute ago to be 0 hours, 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 1, @"Expected the difference between now and 1 minute ago to be 1 minute; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 0.0, @"Expected the difference between now and 1 minute ago to be 1 minute, 0 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);

	//Test 59 seconds (almost, but not quite, one minute) ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-0
					hours:-0 minutes:-0 seconds:-59];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 59 seconds ago to be 0 weeks, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 59 seconds ago to be 0 days, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 59 seconds ago to be 0 hours, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 59 seconds ago to be 0 minutes, 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 59.0, @"Expected the difference between now and 59 seconds ago to be 59 seconds; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}
- (void)testConvertIntervalToSeconds
{
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *then;

	int weeks, days, hours, minutes;
	NSTimeInterval seconds;

	//Test one second ago.
	then = [now
		dateByAddingYears:-0  months:-0    days:-0
					hours:-0 minutes:-0 seconds:-1];
	[NSDate convertTimeInterval:[now timeIntervalSinceDate:then]
						toWeeks:&weeks
						   days:&days
						  hours:&hours
						minutes:&minutes
						seconds:&seconds];
	NSLog(@"%s: seconds is %.15f", __PRETTY_FUNCTION__, seconds);
	STAssertEquals(weeks, 0, @"Expected the difference between now and 1 second ago to be 0 weeks, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals( days, 0, @"Expected the difference between now and 1 second ago to be 0 days, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(hours, 0, @"Expected the difference between now and 1 second ago to be 0 hours, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(minutes, 0, @"Expected the difference between now and 1 second ago to be 0 minutes, 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
	STAssertEquals(seconds, 1.0, @"Expected the difference between now and 1 second ago to be 1 second; result was %iw, %id, %ih, %im, %fs", weeks, days, hours, minutes, seconds);
}

@end
