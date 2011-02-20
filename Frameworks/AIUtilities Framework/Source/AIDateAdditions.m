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
	NSInteger workInterval = (NSInteger)(workIntervalSeconds / 60.0); //Now it's minutes.

	if (outMinutes) *outMinutes = workInterval % 60; //Get the fraction of an hour in minutes.
	workInterval = workInterval / 60; //Now it's hours.

	if (outHours) *outHours = workInterval % 24; //Get the fraction of a day in hours.
	workInterval = workInterval / 24; //Now it's days.

	if (outDays) *outDays = workInterval % 7; //Get the fraction of a week in days.
	workInterval = workInterval / 7; //Now it's weeks.

	if (outWeeks) *outWeeks = workInterval;
}

@end
