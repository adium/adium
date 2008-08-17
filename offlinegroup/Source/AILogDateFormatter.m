//
//  AILogDateFormatter.m
//  Adium
//
//  Created by Evan Schoenberg on 7/30/06.
//

#import "AILogDateFormatter.h"
#import "AICalendarDate.h"
#import <AIUtilities/AIApplicationAdditions.h>

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
