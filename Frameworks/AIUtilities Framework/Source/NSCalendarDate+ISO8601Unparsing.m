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

#import <Foundation/Foundation.h>

#ifndef DEFAULT_TIME_SEPARATOR
#	define DEFAULT_TIME_SEPARATOR ':'
#endif
unichar ISO8601UnparserDefaultTimeSeparatorCharacter = DEFAULT_TIME_SEPARATOR;

static BOOL is_leap_year(NSInteger year) {
	return \
	    ((year %   4) == 0)
	&& (((year % 100) != 0)
	||  ((year % 400) == 0));
}

@interface NSString(ISO8601Unparsing)

//Replace all occurrences of ':' with timeSep.
- (NSString *)prepareDateFormatWithTimeSeparator:(unichar)timeSep;

@end

@implementation NSCalendarDate(ISO8601Unparsing)

#pragma mark Public methods

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep {
	NSString *dateFormat = [(includeTime ? @"%Y-%m-%dT%H:%M:%S" : @"%Y-%m-%d") prepareDateFormatWithTimeSeparator:timeSep];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:NO];
	NSString *str = [formatter stringForObjectValue:self];
	[formatter release];
	if(includeTime) {
		NSInteger offset = [[self timeZone] secondsFromGMT];
		offset /= 60;  //bring down to minutes
		if(offset == 0)
			str = [str stringByAppendingString:@"Z"];
		if(offset < 0)
			str = [str stringByAppendingFormat:@"-%02d:%02d", -offset / 60, -offset % 60];
		else
			str = [str stringByAppendingFormat:@"+%02d:%02d", offset / 60, offset % 60];
	}
	return str;
}
/*Adapted from:
 *	Algorithm for Converting Gregorian Dates to ISO 8601 Week Date
 *	Rick McCarty, 1999
 *	http://personal.ecu.edu/mccartyr/ISOwdALG.txt
 */
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep {
	enum {
		monday, tuesday, wednesday, thursday, friday, saturday, sunday
	};
	enum {
		january = 1U, february, march,
		april, may, june,
		july, august, september,
		october, november, december
	};

	NSInteger year = [self yearOfCommonEra];
	NSInteger week = 0;
	NSInteger dayOfWeek = ([self dayOfWeek] + 6) % 7;
	NSInteger dayOfYear = [self dayOfYear];

	NSInteger prevYear = year - 1U;

	BOOL yearIsLeapYear = is_leap_year(year);
	BOOL prevYearIsLeapYear = is_leap_year(prevYear);

	NSInteger YY = prevYear % 100;
	NSInteger C = prevYear - YY;
	NSInteger G = YY + YY / 4;
	NSInteger Jan1Weekday = (((((C / 100) % 4) * 5) + G) % 7);

	NSInteger weekday = ((dayOfYear + Jan1Weekday) - 1) % 7;

	if((dayOfYear <= (7U - Jan1Weekday)) && (Jan1Weekday > thursday)) {
		week = 52U + ((Jan1Weekday == friday) || ((Jan1Weekday == saturday) && prevYearIsLeapYear));
		--year;
	} else {
		unsigned lengthOfYear = 365U + yearIsLeapYear;
		if((lengthOfYear - dayOfYear) < (thursday - weekday)) {
			++year;
			week = 1U;
		} else {
			NSInteger J = dayOfYear + (sunday - weekday) + Jan1Weekday;
			week = J / 7U - (Jan1Weekday > thursday);
		}
	}

	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:[@"T%H:%M:%S%z" prepareDateFormatWithTimeSeparator:timeSep] allowNaturalLanguage:NO];
		timeString = [formatter stringForObjectValue:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-W%02u-%02u%@", year, week, dayOfWeek + 1U, timeString];
}
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep {
	NSString *timeString;
	if(includeTime) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:[@"T%H:%M:%S%z" prepareDateFormatWithTimeSeparator:timeSep] allowNaturalLanguage:NO];
		timeString = [formatter stringForObjectValue:self];
		[formatter release];
	} else
		timeString = @"";

	return [NSString stringWithFormat:@"%u-%03u%@", [self yearOfCommonEra], [self dayOfYear], timeString];
}

#pragma mark -

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime {
	return [self ISO8601DateStringWithTime:includeTime timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime {
	return [self ISO8601WeekDateStringWithTime:includeTime timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime {
	return [self ISO8601OrdinalDateStringWithTime:includeTime timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}

#pragma mark -

- (NSString *)ISO8601DateStringWithTimeSeparator:(unichar)timeSep {
	return [self ISO8601DateStringWithTime:YES timeSeparator:timeSep];
}
- (NSString *)ISO8601WeekDateStringWithTimeSeparator:(unichar)timeSep {
	return [self ISO8601WeekDateStringWithTime:YES timeSeparator:timeSep];
}
- (NSString *)ISO8601OrdinalDateStringWithTimeSeparator:(unichar)timeSep {
	return [self ISO8601OrdinalDateStringWithTime:YES timeSeparator:timeSep];
}

#pragma mark -

- (NSString *)ISO8601DateString {
	return [self ISO8601DateStringWithTime:YES timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}
- (NSString *)ISO8601WeekDateString {
	return [self ISO8601WeekDateStringWithTime:YES timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}
- (NSString *)ISO8601OrdinalDateString {
	return [self ISO8601OrdinalDateStringWithTime:YES timeSeparator:ISO8601UnparserDefaultTimeSeparatorCharacter];
}

@end

@implementation NSString(ISO8601Unparsing)

//Replace all occurrences of ':' with timeSep.
- (NSString *)prepareDateFormatWithTimeSeparator:(unichar)timeSep {
	NSString *dateFormat = self;
	if(timeSep != ':') {
		NSMutableString *dateFormatMutable = [[dateFormat mutableCopy] autorelease];
		[dateFormatMutable replaceOccurrencesOfString:@":"
		                               	   withString:[NSString stringWithCharacters:&timeSep length:1U]
	                                      	  options:NSBackwardsSearch | NSLiteralSearch
	                                        	range:(NSRange){ 0U, [dateFormat length] }];
		dateFormat = dateFormatMutable;
	}
	return dateFormat;
}

@end
