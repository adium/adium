//
//  AIDateAdditions.m
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2007-11-12.
//  Copyright 2007 Adium Team. All rights reserved.
//

#import "AIDateAdditions.h"

@implementation NSDate (AIDateAdditions)

+ (void) convertTimeInterval:(NSTimeInterval)interval
                    toWeeks:(out NSInteger *)outWeeks
                       days:(out NSInteger *)outDays
                      hours:(out NSInteger *)outHours
                    minutes:(out NSInteger *)outMinutes
                    seconds:(out NSTimeInterval *)outSeconds
{
	NSTimeInterval	workIntervalSeconds = interval;

	if (outSeconds) *outSeconds = fmod(workIntervalSeconds, 60.0); //Get the fraction of a minute in seconds.
	NSInteger workInterval = workIntervalSeconds / 60.0; //Now it's minutes.

	if (outMinutes) *outMinutes = workInterval % 60; //Get the fraction of an hour in minutes.
	workInterval = workInterval / 60; //Now it's hours.

	if (outHours) *outHours = workInterval % 24; //Get the fraction of a day in hours.
	workInterval = workInterval / 24; //Now it's days.

	if (outDays) *outDays = workInterval % 7; //Get the fraction of a week in days.
	workInterval = workInterval / 7; //Now it's weeks.

	if (outWeeks) *outWeeks = workInterval;
}

@end
