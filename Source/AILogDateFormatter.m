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

#import "AILogDateFormatter.h"
#import "AICalendarDate.h"

@implementation AILogDateFormatter

- (NSString *)stringForObjectValue:(NSDate *)date
{
	NSString *returnValue = nil;

	if ([self respondsToSelector:@selector(timeStyle)] && [date isKindOfClass:[AICalendarDate class]]) {
		NSInteger today = [[NSCalendarDate calendarDate] dayOfCommonEra];
		NSInteger dateDay = [(AICalendarDate *)date dayOfCommonEra];
		NSDateFormatterStyle timeStyle = [self timeStyle];

		if ((dateDay == today) || (dateDay == (today - 1))) {
			NSString			*dayString = (dateDay == today) ? AILocalizedString(@"Today", "Day designation for the current day") : AILocalizedString(@"Yesterday", "Day designation for the previous day");
			if ((timeStyle != NSDateFormatterNoStyle) &&
				([(AICalendarDate *)date granularity] == AISecondGranularity)) {
				//Supposed to show time, and the date has sufficient granularity to show it
				NSDateFormatterStyle dateStyle = [self dateStyle];
				NSMutableString *mutableString = [dayString mutableCopy];

				[self setDateStyle:NSDateFormatterNoStyle];
				[mutableString appendString:@" "];
				[mutableString appendString:[super stringForObjectValue:date]];
				[self setDateStyle:dateStyle];
	
				returnValue = [mutableString autorelease];
			}

		} else {
			if ((timeStyle != NSDateFormatterNoStyle) &&
				([(AICalendarDate *)date granularity] == AIDayGranularity)) {
				//Currently supposed to show time, but the date does not have that level of granularity
				
				[self setTimeStyle:NSDateFormatterNoStyle];
				returnValue = [super stringForObjectValue:date];
				[self setTimeStyle:timeStyle];
			}
		}
	}

	if (![returnValue length]) returnValue = [super stringForObjectValue:date];
	if (![returnValue length]) returnValue = [date description];

	return returnValue;
}

@end
