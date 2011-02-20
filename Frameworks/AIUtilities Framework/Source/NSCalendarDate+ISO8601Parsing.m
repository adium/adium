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

#import <ctype.h>
#import <string.h>

#import "NSCalendarDate+ISO8601Parsing.h"

#ifndef DEFAULT_TIME_SEPARATOR
#	define DEFAULT_TIME_SEPARATOR ':'
#endif
unichar ISO8601ParserDefaultTimeSeparatorCharacter = DEFAULT_TIME_SEPARATOR;

static unsigned read_segment(const unsigned char *str, const unsigned char **next, unsigned *out_num_digits) {
	unsigned num_digits = 0U;
	unsigned value = 0U;

	while(isdigit(*str)) {
		value *= 10U;
		value += *str - '0';
		++num_digits;
		++str;
	}

	if(next) *next = str;
	if(out_num_digits) *out_num_digits = num_digits;

	return value;
}
static unsigned read_segment_4digits(const unsigned char *str, const unsigned char **next, unsigned *out_num_digits) {
	unsigned num_digits = 0U;
	unsigned value = 0U;

	if(isdigit(*str)) {
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(isdigit(*str)) {
		value *= 10U;
		value += *(str++) - '0';
		++num_digits;
	}

	if(next) *next = str;
	if(out_num_digits) *out_num_digits = num_digits;

	return value;
}
static unsigned read_segment_2digits(const unsigned char *str, const unsigned char **next) {
	unsigned value = 0U;

	if(isdigit(*str))
		value += *str - '0';

	if(isdigit(*++str)) {
		value *= 10U;
		value += *(str++) - '0';
	}

	if(next) *next = str;

	return value;
}

//strtod doesn't support ',' as a separator. This does.
static double read_double(const unsigned char *str, const unsigned char **next) {
	double value = 0.0;

	if(str) {
		unsigned int_value = 0;

		while(isdigit(*str)) {
			int_value *= 10U;
			int_value += (*(str++) - '0');
		}
		value = int_value;

		if(((*str == ',') || (*str == '.'))) {
			++str;

			double multiplier, multiplier_multiplier;
			multiplier = multiplier_multiplier = 0.1;

			while(isdigit(*str)) {
				value += (*(str++) - '0') * multiplier;
				multiplier *= multiplier_multiplier;
			}
		}
	}

	if(next) *next = str;

	return value;
}

static BOOL is_leap_year(NSInteger year) {
	return \
	    ((year %   4U) == 0U)
	&& (((year % 100U) != 0U)
	||  ((year % 400U) == 0U));
}

@implementation NSCalendarDate(ISO8601Parsing)

/*Valid ISO 8601 date formats:
 *
 *YYYYMMDD
 *YYYY-MM-DD
 *YYYY-MM
 *YYYY
 *YY //century 
 * //Implied century: YY is 00-99
 *  YYMMDD
 *  YY-MM-DD
 * -YYMM
 * -YY-MM
 * -YY
 * //Implied year
 *  --MMDD
 *  --MM-DD
 *  --MM
 * //Implied year and month
 *   ---DD
 * //Ordinal dates: DDD is the number of the day in the year (1-366)
 *YYYYDDD
 *YYYY-DDD
 *  YYDDD
 *  YY-DDD
 *   -DDD
 * //Week-based dates: ww is the number of the week, and d is the number (1-7) of the day in the week
 *yyyyWwwd
 *yyyy-Www-d
 *yyyyWww
 *yyyy-Www
 *yyWwwd
 *yy-Www-d
 *yyWww
 *yy-Www
 * //Year of the implied decade
 *-yWwwd
 *-y-Www-d
 *-yWww
 *-y-Www
 * //Week and day of implied year
 *  -Wwwd
 *  -Www-d
 * //Week only of implied year
 *  -Www
 * //Day only of implied week
 *  -W-d
 */
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str strictly:(BOOL)strict timeSeparator:(unichar)timeSep getRange:(out NSRange *)outRange {
	if (!str || ![str length]) {
		if (outRange) {
			outRange->location = NSNotFound;
			outRange->length = 0U;
		}		

		return nil;
	}
	
	NSCalendarDate *now = [NSCalendarDate calendarDate];
	NSUInteger
		//Date
		year = 0U,
		month_or_week = 0U,
		day = 0U,
		//Time
		hour = 0U;
	NSTimeInterval
		minute = 0.0,
		second = 0.0;
	//Time zone
	signed tz_hour = 0;
	signed tz_minute = 0;

	enum {
		monthAndDate,
		week,
		dateOnly
	} dateSpecification = monthAndDate;

	if(strict) timeSep = ISO8601ParserDefaultTimeSeparatorCharacter;
	NSAssert(timeSep != '\0', @"Time separator must not be NUL.");

	BOOL isValidDate = ([str length] > 0U);
	NSTimeZone *timeZone = nil;
	NSCalendarDate *date = nil;

	const unsigned char *ch = (const unsigned char *)[str UTF8String];

	NSRange range = { 0U, 0U };
	const unsigned char *start_of_date = 0;
	if (strict && isspace(*ch)) {
		range.location = NSNotFound;
		isValidDate = NO;
	} else {
		//Skip leading whitespace.
		NSUInteger i = 0U;
		for(NSInteger len = strlen((const char *)ch); i < len; ++i) {
			if(!isspace(ch[i]))
				break;
		}

		range.location = i;
		ch += i;
		start_of_date = ch;

		unsigned segment;
		unsigned num_leading_hyphens = 0U, num_digits = 0U;

		if (*ch == 'T') {
			//There is no date here, only a time. Set the date to now; then we'll parse the time.
			isValidDate = isdigit(*++ch);

			year = [now yearOfCommonEra];
			month_or_week = [now monthOfYear];
			day = [now dayOfMonth];
		} else {

			while(*ch == '-') {
				++num_leading_hyphens;
				++ch;
			}

			segment = read_segment(ch, &ch, &num_digits);
			switch (num_digits) {
				case 0:
					if(*ch == 'W') {
						if((ch[1] == '-') && isdigit(ch[2]) && ((num_leading_hyphens == 1U) || ((num_leading_hyphens == 2U) && !strict))) {
							year = [now yearOfCommonEra];
							month_or_week = 1U;
							ch += 2;
							goto parseDayAfterWeek;
						} else if(num_leading_hyphens == 1U) {
							year = [now yearOfCommonEra];
							goto parseWeekAndDay;
						} else
							isValidDate = NO;
					} else
						isValidDate = NO;
					break;

				case 8: //YYYY MM DD
					if(num_leading_hyphens > 0U)
						isValidDate = NO;
					else {
						day = segment % 100U;
						segment /= 100U;
						month_or_week = segment % 100U;
						year = segment / 100U;
					}
					break;

				case 6: //YYMMDD (implicit century)
					if(num_leading_hyphens > 0U)
						isValidDate = NO;
					else {
						day = segment % 100U;
						segment /= 100U;
						month_or_week = segment % 100U;
						year  = [now yearOfCommonEra];
						year -= (year % 100U);
						year += segment / 100U;
					}
					break;

				case 4:
					switch(num_leading_hyphens) {
						case 0: //YYYY
							year = segment;

							if(*ch == '-') ++ch;

							if(!isdigit(*ch)) {
								if(*ch == 'W')
									goto parseWeekAndDay;
								else
									month_or_week = day = 1U;
							} else {
								segment = read_segment(ch, &ch, &num_digits);
								switch(num_digits) {
									case 4: //MMDD
										day = segment % 100U;
										month_or_week = segment / 100U;
										break;
	
									case 2: //MM
										month_or_week = segment;

										if(*ch == '-') ++ch;
										if(!isdigit(*ch))
											day = 1U;
										else
											day = read_segment(ch, &ch, NULL);
										break;
	
									case 3: //DDD
										day = segment % 1000U;
										dateSpecification = dateOnly;
										if(strict && (day > (365 + is_leap_year(year))))
											isValidDate = NO;
										break;
	
									default:
										isValidDate = NO;
								}
							}
							break;

						case 1: //YYMM
							month_or_week = segment % 100U;
							year = segment / 100U;

							if(*ch == '-') ++ch;
							if(!isdigit(*ch))
								day = 1U;
							else
								day = read_segment(ch, &ch, NULL);

							break;

						case 2: //MMDD
							day = segment % 100U;
							month_or_week = segment / 100U;
							year = [now yearOfCommonEra];

							break;

						default:
							isValidDate = NO;
					} //switch(num_leading_hyphens) (4 digits)
					break;

				case 1:
					if(strict) {
						//Two digits only - never just one.
						if(num_leading_hyphens == 1U) {
							if(*ch == '-') ++ch;
							if(*++ch == 'W') {
								year  = [now yearOfCommonEra];
								year -= (year % 10U);
								year += segment;
								goto parseWeekAndDay;
							} else
								isValidDate = NO;
						} else
							isValidDate = NO;
						break;
					}
				case 2:
					switch(num_leading_hyphens) {
						case 0:
							if(*ch == '-') {
								//Implicit century
								year  = [now yearOfCommonEra];
								year -= (year % 100U);
								year += segment;

								if(*++ch == 'W')
									goto parseWeekAndDay;
								else if(!isdigit(*ch)) {
									goto centuryOnly;
								} else {
									//Get month and/or date.
									segment = read_segment_4digits(ch, &ch, &num_digits);
									NSLog(@"(%@) parsing month; segment is %u and ch is %s", str, segment, ch);
									switch(num_digits) {
										case 4: //YY-MMDD
											day = segment % 100U;
											month_or_week = segment / 100U;
											break;

										case 1: //YY-M; YY-M-DD (extension)
											if(strict) {
												isValidDate = NO;
												break;
											}
										case 2: //YY-MM; YY-MM-DD
											month_or_week = segment;
											if(*ch == '-') {
												if(isdigit(*++ch))
													day = read_segment_2digits(ch, &ch);
												else
													day = 1U;
											} else
												day = 1U;
											break;

										case 3: //Ordinal date.
											day = segment;
											dateSpecification = dateOnly;
											break;
									}
								}
							} else if(*ch == 'W') {
								year  = [now yearOfCommonEra];
								year -= (year % 100U);
								year += segment;

							parseWeekAndDay: //*ch should be 'W' here.
								if(!isdigit(*++ch)) {
									//Not really a week-based date; just a year followed by '-W'.
									if(strict)
										isValidDate = NO;
									else
										month_or_week = day = 1U;
								} else {
									month_or_week = read_segment_2digits(ch, &ch);
									if(*ch == '-') ++ch;
								parseDayAfterWeek:
									day = isdigit(*ch) ? read_segment_2digits(ch, &ch) : 1U;
									dateSpecification = week;
								}
							} else {
								//Century only. Assume current year.
							centuryOnly:
								year = segment * 100U + [now yearOfCommonEra] % 100U;
								month_or_week = day = 1U;
							}
							break;

						case 1:; //-YY; -YY-MM (implicit century)
							NSLog(@"(%@) found %u digits and one hyphen, so this is either -YY or -YY-MM; segment (year) is %u", str, num_digits, segment);
							NSInteger current_year = [now yearOfCommonEra];
							NSInteger current_century = (current_year % 100);
							year = segment + (current_year - century);
							if(num_digits == 1U) //implied decade
								year += current_century - (current_year % 10);

							if(*ch == '-') {
								++ch;
								month_or_week = read_segment_2digits(ch, &ch);
								NSLog(@"(%@) month is %lu", str, month_or_week);
							}

							day = 1U;
							break;

						case 2: //--MM; --MM-DD
							year = [now yearOfCommonEra];
							month_or_week = segment;
							if(*ch == '-') {
								++ch;
								day = read_segment_2digits(ch, &ch);
							}
							break;

						case 3: //---DD
							year = [now yearOfCommonEra];
							month_or_week = [now monthOfYear];
							day = segment;
							break;

						default:
							isValidDate = NO;
					} //switch(num_leading_hyphens) (2 digits)
					break;

				case 7: //YYYY DDD (ordinal date)
					if(num_leading_hyphens > 0U)
						isValidDate = NO;
					else {
						day = segment % 1000U;
						year = segment / 1000U;
						dateSpecification = dateOnly;
						if(strict && (day > (365U + is_leap_year(year))))
							isValidDate = NO;
					}
					break;

				case 3: //--DDD (ordinal date, implicit year)
					//Technically, the standard only allows one hyphen. But it says that two hyphens is the logical implementation, and one was dropped for brevity. So I have chosen to allow the missing hyphen.
					if((num_leading_hyphens < 1U) || ((num_leading_hyphens > 2U) && !strict))
						isValidDate = NO;
					else {
						day = segment;
						year = [now yearOfCommonEra];
						dateSpecification = dateOnly;
						if(strict && (day > (365U + is_leap_year(year))))
							isValidDate = NO;
					}
					break;

				default:
					isValidDate = NO;
			}
		}

		if (isValidDate) {
			if (isspace(*ch) || (*ch == 'T')) ++ch;

			if (isdigit(*ch)) {
				hour = read_segment_2digits(ch, &ch);
				if(*ch == timeSep) {
					++ch;
					if((timeSep == ',') || (timeSep == '.')) {
						//We can't do fractional minutes when '.' is the segment separator.
						//Only allow whole minutes and whole seconds.
						minute = read_segment_2digits(ch, &ch);
						if(*ch == timeSep) {
							++ch;
							second = read_segment_2digits(ch, &ch);
						}
					} else {
						//Allow a fractional minute.
						//If we don't get a fraction, look for a seconds segment.
						//Otherwise, the fraction of a minute is the seconds.
						minute = read_double(ch, &ch);
						second = modf(minute, &minute);
						if(second > DBL_EPSILON)
							second *= 60.0; //Convert fraction (e.g. .5) into seconds (e.g. 30).
						else if(*ch == timeSep) {
							++ch;
							second = read_double(ch, &ch);
						}
					}
				}

				switch(*ch) {
					case 'Z':
						timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
						break;

					case '+':
					case '-':;
						BOOL negative = (*ch == '-');
						if(isdigit(*++ch)) {
							//Read hour offset.
							segment = *ch - '0';
							if(isdigit(*++ch)) {
								segment *= 10U;
								segment += *(ch++) - '0';
							}
							tz_hour = (signed)segment;
							if(negative) tz_hour = -tz_hour;

							//Optional separator.
							if(*ch == timeSep) ++ch;

							if(isdigit(*ch)) {
								//Read minute offset.
								segment = *ch - '0';
								if(isdigit(*++ch)) {
									segment *= 10U;
									segment += *ch - '0';
								}
								tz_minute = segment;
								if(negative) tz_minute = -tz_minute;
							}

							NSInteger secondsFromGMT = (tz_hour * 3600) + (tz_minute * 60);
							static NSInteger lastUsedSecondsFromGMT = NSNotFound;
							static NSTimeZone *lastUsedTimeZone;
							if (secondsFromGMT == lastUsedSecondsFromGMT)
								timeZone = [[lastUsedTimeZone retain] autorelease];
							else
								timeZone = [NSTimeZone timeZoneForSecondsFromGMT:secondsFromGMT];
							lastUsedSecondsFromGMT = secondsFromGMT;
							[lastUsedTimeZone autorelease];
							lastUsedTimeZone = [timeZone retain];
						}
				}
			}
		}

		if (isValidDate) {
			switch (dateSpecification) {
				case monthAndDate:
					date = [NSCalendarDate dateWithYear:year
												  month:month_or_week
													day:day
												   hour:hour
												 minute:(NSUInteger)minute
												 second:(NSUInteger)second
											   timeZone:timeZone];
					break;

				case week:;
					//Adapted from <http://personal.ecu.edu/mccartyr/ISOwdALG.txt>.
					//This works by converting the week date into an ordinal date, then letting the next case handle it.
					NSInteger prevYear = year - 1U;
					NSInteger YY = prevYear % 100U;
					NSInteger C = prevYear - YY;
					NSInteger G = YY + YY / 4U;
					NSInteger isLeapYear = (((C / 100U) % 4U) * 5U);
					NSInteger Jan1Weekday = (isLeapYear + G) % 7U;
					enum { monday, tuesday, wednesday, thursday/*, friday, saturday, sunday*/ };
					day = ((8U - Jan1Weekday) + (7U * (Jan1Weekday > thursday))) + (day - 1U) + (7U * (month_or_week - 2));

				case dateOnly: //An "ordinal date".
					date = [NSCalendarDate dateWithYear:year
												  month:1
													day:1
												   hour:hour
												 minute:(NSUInteger)minute
												 second:(NSUInteger)second
											   timeZone:timeZone];
					date = [date dateByAddingYears:0
											months:0
											  days:(day - 1)
											 hours:0
										   minutes:0
										   seconds:0];
					break;
			}
		}
	} //if (!(strict && isdigit(ch[0])))

	if(outRange) {
		if(isValidDate)
			range.length = ch - start_of_date;
		else
			range.location = NSNotFound;

		*outRange = range;
	}

	return date;
}

+ (NSCalendarDate *)calendarDateWithString:(NSString *)str {
	return [self calendarDateWithString:str strictly:NO getRange:NULL];
}
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str strictly:(BOOL)strict {
	return [self calendarDateWithString:str strictly:strict getRange:NULL];
}
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str strictly:(BOOL)strict getRange:(out NSRange *)outRange {
	return [self calendarDateWithString:str strictly:strict timeSeparator:ISO8601ParserDefaultTimeSeparatorCharacter getRange:NULL];
}

+ (NSCalendarDate *)calendarDateWithString:(NSString *)str timeSeparator:(unichar)timeSep getRange:(out NSRange *)outRange {
	return [self calendarDateWithString:str strictly:NO timeSeparator:timeSep getRange:outRange];
}
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str timeSeparator:(unichar)timeSep {
	return [self calendarDateWithString:str strictly:NO timeSeparator:timeSep getRange:NULL];
}
+ (NSCalendarDate *)calendarDateWithString:(NSString *)str getRange:(out NSRange *)outRange {
	return [self calendarDateWithString:str strictly:NO timeSeparator:ISO8601ParserDefaultTimeSeparatorCharacter getRange:outRange];
}

@end
