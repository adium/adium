//
//  AICalendarDateAdditions.m
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2007-11-11.
//  Copyright 2007 Adium Team. All rights reserved.
//

#import "AICalendarDateAdditions.h"

@implementation NSCalendarDate (AICalendarDateAdditions)

- (NSCalendarDate *)dateByMatchingDSTOfDate:(NSDate *)otherDate
{
	NSCalendarDate *result = self;

	NSTimeZone *tz = [self timeZone];
	if ([tz isDaylightSavingTimeForDate:otherDate] && ![tz isDaylightSavingTimeForDate:self]) {
		//We have sprung forward. Subtract one hour from date to convert it to standard time.
		result = [self
			dateByAddingYears:-0  months:-0    days:-0
						hours:-1 minutes:-0 seconds:-0];
	} else if ([tz isDaylightSavingTimeForDate:self] && ![tz isDaylightSavingTimeForDate:otherDate]) {
		//We have fallen back. Add one hour to date to convert it to daylight-saving time.
		result = [self
			dateByAddingYears:-0  months:-0    days:-0
						hours:+1 minutes:-0 seconds:-0];
	}

	return result;
}

@end
