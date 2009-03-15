#import "TestDateFormatterStringRepWithInterval.h"
#import <AIUtilities/AICalendarDateAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>

@implementation TestDateFormatterStringRepWithInterval

//Note: All of these delta values that we pass to NSCalendarDate need to be NEGATIVE, because we're looking to get a string representation of the interval since some time in the past.
- (void)testDateFormatterStringRepWithInterval_seconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-0];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-10];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 minutes 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 seconds", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 minutes", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date], @"65 weeks 5 days 10 hours 10 minutes 10 seconds", @"Unexpected string for time interval");
}

- (void)testDateFormatterStringRepWithInterval_seconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_minutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hours_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_hoursMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-0
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_days_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHours_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_daysHoursMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:-5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"5d 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeks_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHours_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksHoursMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 10h 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDays_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-0
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10m 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHours_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-0
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-0
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10s", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutes_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-10
		          seconds:-0];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10m", @"Unexpected string for time interval");
}
- (void)testDateFormatterStringRepWithInterval_weeksDaysHoursMinutesSeconds_abbreviated {
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSCalendarDate *date = [now
		dateByAddingYears:-0
		           months:-0
		             days:7 * -65 + -5
		            hours:-10
		          minutes:-10
		          seconds:-10];
	date = [date dateByMatchingDSTOfDate:now];
	AISimplifiedAssertEqualObjects([NSDateFormatter stringForTimeIntervalSinceDate:date showingSeconds:YES abbreviated:YES], @"65w 5d 10h 10m 10s", @"Unexpected string for time interval");
}

@end
